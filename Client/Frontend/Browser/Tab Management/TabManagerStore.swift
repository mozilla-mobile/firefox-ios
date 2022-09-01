// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
import Shared

protocol TabManagerStore {
    var isRestoringTabs: Bool { get }
    var hasTabsToRestoreAtStartup: Bool { get }

    func preserveScreenshot(forTab tab: Tab?)
    func removeScreenshot(forTab tab: Tab?)

    func preserveTabs(_ tabs: [Tab],
                      selectedTab: Tab?,
                      writeCompletion: (() -> Void)?)

    func restoreStartupTabs(clearPrivateTabs: Bool,
                            tabManager: TabManager) -> Tab?

    func restoreTabs(savedTabs: [SavedTab],
                     clearPrivateTabs: Bool,
                     tabManager: TabManager) -> Tab?

    func clearArchive()
}

extension TabManagerStore {
    func preserveTabs(_ tabs: [Tab], selectedTab: Tab?, writeCompletion: (() -> Void)? =  nil) {
        preserveTabs(tabs, selectedTab: selectedTab, writeCompletion: writeCompletion)
    }
}

class TabManagerStoreImplementation: TabManagerStore, FeatureFlaggable, Loggable {

    // MARK: - Variables
    private let prefs: Prefs
    private let imageStore: DiskImageStore?
    private var fileManager: FileManager
    private var writeOperation: DispatchWorkItem
    private let serialQueue: DispatchQueue
    private var lockedForReading = false
    private let tabDataRetriever: TabDataRetriever

    var isRestoringTabs: Bool {
        return lockedForReading
    }

    var hasTabsToRestoreAtStartup: Bool {
        return !tabs.isEmpty
    }

    // MARK: - Initializer

    init(prefs: Prefs,
         imageStore: DiskImageStore?,
         fileManager: FileManager = FileManager.default,
         writeOperation: DispatchWorkItem = DispatchWorkItem {},
         serialQueue: DispatchQueue = DispatchQueue(label: "tab-manager-write-queue")) {
        self.fileManager = fileManager
        self.imageStore = imageStore
        self.prefs = prefs
        self.writeOperation = writeOperation
        self.serialQueue = serialQueue
        self.tabDataRetriever = TabDataRetrieverImplementation(fileManager: fileManager)
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
        guard let savedTabs = prepareSavedTabs(fromTabs: tabs, selectedTab: selectedTab),
              let path = tabsStateArchivePath()
        else {
            clearArchive()
            return
        }

        writeOperation.cancel()

        let tabStateData = archive(savedTabs: savedTabs)
        let simpleTabs = SimpleTab.convertToSimpleTabs(savedTabs)

        writeOperation = DispatchWorkItem { [weak self] in
            SimpleTab.saveSimpleTab(tabs: simpleTabs)
            let written = tabStateData.write(toFile: path, atomically: true)
            // Ignore write failure (could be restoring).
            self?.browserLog.debug("PreserveTabs write ok: \(written), bytes: \(tabStateData.length)")
        }

        // Delay by 100ms to debounce repeated calls to preserveTabs in quick succession.
        // Notice above that a repeated 'preserveTabs' call will 'cancel()' a pending write operation.
        serialQueue.asyncAfter(deadline: .now() + .milliseconds(100), execute: writeOperation)
    }

    // MARK: - Restoration

    func restoreStartupTabs(clearPrivateTabs: Bool, tabManager: TabManager) -> Tab? {
        return restoreTabs(savedTabs: tabs,
                           clearPrivateTabs: clearPrivateTabs,
                           tabManager: tabManager)
    }

    func restoreTabs(savedTabs: [SavedTab],
                     clearPrivateTabs: Bool,
                     tabManager: TabManager) -> Tab? {
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

        // TODO: Laurie - This is called from tabManager, shouldn't act on tabManager here
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            var tab = tabManager.addTab(flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)
            tab = savedTab.configureSavedTabUsing(tab, imageStore: imageStore)
            if savedTab.isSelected {
                tabToSelect = tab
            }
        }

        if tabToSelect == nil {
            tabToSelect = tabManager.tabs.first(where: { $0.isPrivate == false })
        }

        return tabToSelect
    }

    func clearArchive() {
        guard let path = tabsStateArchivePath() else { return }
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch let error {
            browserLog.warning("Clear archive couldn't be completed with: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    private func archive(savedTabs: [SavedTab]) -> NSMutableData {
        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        archiver.encode(savedTabs, forKey: "tabs")
        archiver.finishEncoding()
        return tabStateData
    }

    private var tabs: [SavedTab] {
        guard let tabData = tabDataRetriever.getTabData() else { return [SavedTab]() }

        let unarchiver = try NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.setClass(SavedTab.self, forClassName: "Client.SavedTab")
        unarchiver.setClass(SessionData.self, forClassName: "Client.SessionData")
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            SentryIntegration.shared.send(message: "Failed to restore tabs",
                                          tag: .tabManager,
                                          severity: .error,
                                          description: "\(unarchiver.error ??? "nil")")
            SimpleTab.saveSimpleTab(tabs: nil)
            return [SavedTab]()
        }

        return tabs
    }

    private func tabsStateArchivePath() -> String? {
        let profilePath: String?
        if  AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
            profilePath = (UIApplication.shared.delegate as? UITestAppDelegate)?.dirForTestProfile
        } else {
            profilePath = fileManager
                .containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?
                .appendingPathComponent("profile.profile")
                .path
        }
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("tabsState.archive").path
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
}

// MARK: Tests
extension TabManagerStoreImplementation {
    func testTabCountOnDisk() -> Int {
        assert(AppConstants.isRunningTest)
        return tabs.count
    }
}
