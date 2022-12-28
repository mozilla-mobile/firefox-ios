// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared
import Common

protocol TabManagerStore {
    var isRestoringTabs: Bool { get }
    var hasTabsToRestoreAtStartup: Bool { get }

    func preserveScreenshot(forTab tab: Tab?)
    func removeScreenshot(forTab tab: Tab?)

    func preserveTabs(_ tabs: [Tab],
                      selectedTab: Tab?)

    func restoreStartupTabs(clearPrivateTabs: Bool,
                            addTabClosure: (Bool) -> Tab) -> Tab?

    func clearArchive()
}

extension TabManagerStore {
    func preserveTabs(_ tabs: [Tab], selectedTab: Tab?) {
        preserveTabs(tabs, selectedTab: selectedTab)
    }
}

class TabManagerStoreImplementation: TabManagerStore, FeatureFlaggable, Loggable {
    // MARK: - Variables
    private let tabsKey = "tabs"
    private let prefs: Prefs
    private let imageStore: DiskImageStore?
    private var fileManager: TabFileManager
    private var writeOperation = DispatchWorkItem {}
    private let serialQueue: DispatchQueueInterface
    private var lockedForReading = false

    private var deprecatedTabDataRetriever: TabDataRetriever
    private var tabDataRetriever: TabDataRetriever
    static let storePath = "codableTabsState.archive"
    static let deprecatedStorePath = "tabsState.archive"

    var isRestoringTabs: Bool {
        return lockedForReading
    }

    var hasTabsToRestoreAtStartup: Bool {
        return !tabs.isEmpty
    }

    // MARK: - Initializer

    init(prefs: Prefs,
         imageStore: DiskImageStore?,
         fileManager: TabFileManager = FileManager.default,
         serialQueue: DispatchQueueInterface = DispatchQueue(label: "tab-manager-write-queue")) {
        self.prefs = prefs
        self.imageStore = imageStore
        self.fileManager = fileManager
        self.serialQueue = serialQueue

        self.deprecatedTabDataRetriever = TabDataRetrieverImplementation(fileManager: fileManager)
        self.tabDataRetriever = TabDataRetrieverImplementation(fileManager: fileManager)
        deprecatedTabDataRetriever.tabsStateArchivePath = deprecatedTabsStateArchivePath()
        tabDataRetriever.tabsStateArchivePath = tabsStateArchivePath()
    }

    // MARK: - Screenshots

    func preserveScreenshot(forTab tab: Tab?) {
        if let tab = tab, let screenshot = tab.screenshot, let uuidString = tab.screenshotUUID?.uuidString {
            imageStore?.put(uuidString, image: screenshot)
        }
    }

    func removeScreenshot(forTab tab: Tab?) {
        if let tab = tab, let screenshotUUID = tab.screenshotUUID {
            _ = imageStore?.removeImage(screenshotUUID.uuidString)
        }
    }

    // MARK: - Saving

    /// Async write of the tab state. In most cases, code doesn't care about performing an operation
    /// after this completes. Write failures (i.e. due to read locks) are considered inconsequential, as preserveTabs will be called frequently.
    /// - Parameters:
    ///   - tabs: The tabs to preserve
    ///   - selectedTab: One of the saved tabs will be saved as the selected tab.
    func preserveTabs(_ tabs: [Tab], selectedTab: Tab?) {
        assertIsMainThread("Preserving tabs is a main-only operation")
        guard let savedTabs = prepareSavedTabs(fromTabs: tabs, selectedTab: selectedTab)
        else {
            clearArchive()
            return
        }

        writeOperation.cancel()

        let path = tabsStateArchivePath()
        let tabStateData = archive(savedTabs: savedTabs)
        let simpleTabs = SimpleTab.convertToSimpleTabs(savedTabs)

        writeOperation = DispatchWorkItem { [weak self] in
            SimpleTab.saveSimpleTab(tabs: simpleTabs)
            self?.write(tabStateData: tabStateData, path: path)
        }

        // Delay by 100ms to debounce repeated calls to preserveTabs in quick succession.
        // Notice above that a repeated 'preserveTabs' call will 'cancel()' a pending write operation.
        serialQueue.asyncAfter(deadline: .now() + .milliseconds(100), execute: writeOperation)
    }

    // MARK: - Restoration

    func restoreStartupTabs(clearPrivateTabs: Bool,
                            addTabClosure: (Bool) -> Tab) -> Tab? {
        return restoreTabs(savedTabs: tabs,
                           clearPrivateTabs: clearPrivateTabs,
                           addTabClosure: addTabClosure)
    }

    func restoreTabs(savedTabs: [SavedTab],
                     clearPrivateTabs: Bool,
                     addTabClosure: (Bool) -> Tab) -> Tab? {
        assertIsMainThread("Restoration is a main-only operation")
        guard !lockedForReading, !savedTabs.isEmpty else { return nil }
        lockedForReading = true
        defer { lockedForReading = false }

        var savedTabs = savedTabs
        // Make sure to wipe the private tabs if the user has the pref turned on
        if clearPrivateTabs {
            savedTabs = savedTabs.filter { !$0.isPrivate }
        }

        var tabToSelect: Tab?
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            var tab = addTabClosure(savedTab.isPrivate)
            tab = savedTab.configureSavedTabUsing(tab, imageStore: imageStore)
            if savedTab.isSelected {
                tabToSelect = tab
            }
        }

        return tabToSelect
    }

    func clearArchive() {
        clearDeprecatedArchive()
        guard let path = tabsStateArchivePath() else { return }

        do {
            try fileManager.removeItem(at: path)
        } catch let error {
            SentryIntegration.shared.send(message: "Clear archive couldn't be completed",
                                          tag: .tabManager,
                                          severity: .warning,
                                          description: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func archive(savedTabs: [SavedTab]) -> Data? {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        do {
            try archiver.encodeEncodable(savedTabs, forKey: tabsKey)
        } catch let error {
            SentryIntegration.shared.send(message: "Archiving savedTabs failed",
                                          tag: .tabManager,
                                          severity: .warning,
                                          description: error.localizedDescription)
            return nil
        }

        return archiver.encodedData
    }

    private var tabs: [SavedTab] {
        guard let tabData = tabDataRetriever.getTabData() else {
            // In case tabs aren't migrated yet, we retrieve with deprecated methods
            return getDeprecatedTabsToMigrate()
        }

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: tabData)
            guard let tabs = unarchiver.decodeDecodable([SavedTab].self, forKey: tabsKey) else {
                let message = "\(unarchiver.error?.localizedDescription ?? "Couldn't decode from tabsKey")"
                return savedTabError(description: message)
            }
            return tabs
        } catch let error {
            return savedTabError(description: error.localizedDescription)
        }
    }

    private func savedTabError(description: String) -> [SavedTab] {
        SentryIntegration.shared.send(message: "Failed to restore tabs",
                                      tag: .tabManager,
                                      severity: .error,
                                      description: description)
        SimpleTab.saveSimpleTab(tabs: nil)
        return [SavedTab]()
    }

    private func tabsStateArchivePath() -> URL? {
        let profilePath: String?
        if  AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
            profilePath = (UIApplication.shared.delegate as? UITestAppDelegate)?.dirForTestProfile
        } else {
            profilePath = fileManager.tabPath
        }
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent(TabManagerStoreImplementation.storePath)
    }

    private func prepareSavedTabs(fromTabs tabs: [Tab], selectedTab: Tab?) -> [SavedTab]? {
        var savedTabs = [SavedTab]()
        var savedUUIDs = Set<String>()
        for tab in tabs {
            tab.tabUUID = tab.tabUUID.isEmpty ? UUID().uuidString : tab.tabUUID
            tab.screenshotUUID = tab.screenshotUUID ?? UUID()
            tab.firstCreatedTime = tab.firstCreatedTime ?? tab.sessionData?.lastUsedTime ?? Date.now()
            if let savedTab = SavedTab(tab: tab, isSelected: tab == selectedTab) {
                savedTabs.append(savedTab)
                if let uuidString = tab.screenshotUUID?.uuidString {
                    savedUUIDs.insert(uuidString)
                }
            }
        }

        // Clean up any screenshots that are no longer associated with a tab.
        _ = imageStore?.clearExcluding(savedUUIDs)
        return savedTabs.isEmpty ? nil : savedTabs
    }

    private func write(tabStateData: Data?, path: URL?) {
        guard let data = tabStateData, let path = path else { return }
        do {
            try data.write(to: path, options: [])
            browserLog.debug("PreserveTabs write succeeded with bytes count: \(data.count)")
        } catch {
            // Failure could happen when restoring
            browserLog.debug("PreserveTabs write failed with bytes count: \(data.count)")
        }
    }

    // MARK: - Deprecated
    // To remove once migration is completed, see FXIOS-4913

    func getDeprecatedTabsToMigrate() -> [SavedTab] {
        guard let tabData = deprecatedTabDataRetriever.getTabData() else { return [SavedTab]() }

        // In case tabs aren't migrated to Codable yet
        // We'll be able to remove this when adoption rate to v106 and greater is high enough
        let deprecatedUnarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
        deprecatedUnarchiver.setClass(SavedTab.self, forClassName: "Client.SavedTab")
        deprecatedUnarchiver.setClass(SessionData.self, forClassName: "Client.SessionData")
        deprecatedUnarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let migratedTabs = deprecatedUnarchiver.decodeObject(forKey: tabsKey) as? [SavedTab] else {
            let error = String(describing: deprecatedUnarchiver.error)
            return savedTabError(description: "Deprecated unarchiver could not decode Saved tab with: \(error)")
        }
        return migratedTabs
    }

    private func deprecatedTabsStateArchivePath() -> URL? {
        let profilePath: String?
        if  AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
            profilePath = (UIApplication.shared.delegate as? UITestAppDelegate)?.dirForTestProfile
        } else {
            profilePath = fileManager.tabPath
        }
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent(TabManagerStoreImplementation.deprecatedStorePath)
    }

    private func clearDeprecatedArchive() {
        guard let deprecatedPath = deprecatedTabsStateArchivePath() else { return }

        do {
            try fileManager.removeItem(at: deprecatedPath)
        } catch let error {
            SentryIntegration.shared.send(message: "Clear deprecated archive couldn't be completed",
                                          tag: .tabManager,
                                          severity: .warning,
                                          description: error.localizedDescription)
        }
    }
}

// MARK: Tests
extension TabManagerStoreImplementation {
    func testTabOnDisk() -> [SavedTab] {
        assert(AppConstants.isRunningTest)
        return tabs
    }
}
