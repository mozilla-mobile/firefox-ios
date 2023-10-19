// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage
import Shared

protocol LegacyTabManagerStore {
    var isRestoringTabs: Bool { get }
    var hasTabsToRestoreAtStartup: Bool { get }
    var tabs: [LegacySavedTab] { get }

    func preserveTabs(_ tabs: [Tab],
                      selectedTab: Tab?)

    func restoreStartupTabs(clearPrivateTabs: Bool,
                            addTabClosure: @escaping (Bool) -> Tab) -> Tab?

    func clearArchive()
}

extension LegacyTabManagerStore {
    func preserveTabs(_ tabs: [Tab], selectedTab: Tab?) {
        preserveTabs(tabs, selectedTab: selectedTab)
    }
}

class LegacyTabManagerStoreImplementation: LegacyTabManagerStore, FeatureFlaggable {
    // MARK: - Variables
    private let logger: Logger
    private let tabsKey = "tabs"
    private let prefs: Prefs
    private let imageStore: DiskImageStore?
    private var fileManager: LegacyTabFileManager
    private var writeOperation = DispatchWorkItem {}
    private let serialQueue: DispatchQueueInterface
    private var lockedForReading = false
    private var tabDataRetriever: LegacyTabDataRetriever
    static let storePath = "codableTabsState.archive"

    var isRestoringTabs: Bool {
        return lockedForReading
    }

    var hasTabsToRestoreAtStartup: Bool {
        return !tabs.isEmpty
    }

    // MARK: - Initializer

    init(prefs: Prefs,
         imageStore: DiskImageStore?,
         fileManager: LegacyTabFileManager = FileManager.default,
         serialQueue: DispatchQueueInterface = DispatchQueue(label: "tab-manager-write-queue"),
         logger: Logger = DefaultLogger.shared) {
        self.prefs = prefs
        self.imageStore = imageStore
        self.fileManager = fileManager
        self.serialQueue = serialQueue
        self.logger = logger
        self.tabDataRetriever = LegacyTabDataRetrieverImplementation(fileManager: fileManager)
        tabDataRetriever.tabsStateArchivePath = tabsStateArchivePath()
    }

    // MARK: - Saving

    /// Async write of the tab state. In most cases, code doesn't care about performing an operation
    /// after this completes. Write failures (i.e. due to read locks) are considered inconsequential, as preserveTabs will be called frequently.
    /// - Parameters:
    ///   - tabs: The tabs to preserve
    ///   - selectedTab: One of the saved tabs will be saved as the selected tab.
    func preserveTabs(_ tabs: [Tab], selectedTab: Tab?) {
        guard let savedTabs = prepareSavedTabs(fromTabs: tabs, selectedTab: selectedTab) else {
            clearArchive()
            return
        }

        // Preserving tabs is a main-only operation
        ensureMainThread { [self] in
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
    }

    // MARK: - Restoration

    func restoreStartupTabs(clearPrivateTabs: Bool,
                            addTabClosure: (Bool) -> Tab) -> Tab? {
        return restoreTabs(savedTabs: tabs,
                           clearPrivateTabs: clearPrivateTabs,
                           addTabClosure: addTabClosure)
    }

    func restoreTabs(savedTabs: [LegacySavedTab],
                     clearPrivateTabs: Bool,
                     addTabClosure: (Bool) -> Tab) -> Tab? {
        // We are told "Restoration is a main-only operation"
        guard !lockedForReading,
                Thread.current.isMainThread,
                !savedTabs.isEmpty
        else { return nil }

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
        guard let path = tabsStateArchivePath() else { return }

        do {
            try fileManager.removeItem(at: path)
        } catch let error {
            logger.log("Clear archive couldn't be completed",
                       level: .warning,
                       category: .tabs,
                       description: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func archive(savedTabs: [LegacySavedTab]) -> Data? {
        let archiver = NSKeyedArchiver(requiringSecureCoding: false)
        do {
            try archiver.encodeEncodable(savedTabs, forKey: tabsKey)
        } catch let error {
            logger.log("Archiving savedTabs failed",
                       level: .warning,
                       category: .tabs,
                       description: error.localizedDescription)
            return nil
        }

        return archiver.encodedData
    }

    var tabs: [LegacySavedTab] {
        guard let tabData = tabDataRetriever.getTabData() else {
            return []
        }

        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: tabData)
            guard let tabs = unarchiver.decodeDecodable([LegacySavedTab].self, forKey: tabsKey) else {
                let message = "\(unarchiver.error?.localizedDescription ?? "Couldn't decode from tabsKey")"
                return savedTabError(description: message)
            }
            return tabs
        } catch let error {
            return savedTabError(description: error.localizedDescription)
        }
    }

    private func savedTabError(description: String) -> [LegacySavedTab] {
        logger.log("Failed to restore tabs",
                   level: .warning,
                   category: .tabs,
                   description: description)
        SimpleTab.saveSimpleTab(tabs: nil)
        return [LegacySavedTab]()
    }

    private func tabsStateArchivePath() -> URL? {
        let profilePath: String?
        if  AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
            profilePath = (UIApplication.shared.delegate as? UITestAppDelegate)?.dirForTestProfile
        } else {
            profilePath = fileManager.tabPath
        }
        guard let path = profilePath else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent(LegacyTabManagerStoreImplementation.storePath)
    }

    private func prepareSavedTabs(fromTabs tabs: [Tab], selectedTab: Tab?) -> [LegacySavedTab]? {
        var savedTabs = [LegacySavedTab]()
        var savedUUIDs = Set<String>()
        for tab in tabs {
            tab.tabUUID = tab.tabUUID.isEmpty ? UUID().uuidString : tab.tabUUID
            tab.screenshotUUID = tab.screenshotUUID ?? UUID()
            tab.firstCreatedTime = tab.firstCreatedTime ?? tab.sessionData?.lastUsedTime ?? Date.now()
            if let savedTab = LegacySavedTab(tab: tab, isSelected: tab == selectedTab) {
                savedTabs.append(savedTab)
                if let uuidString = tab.screenshotUUID?.uuidString {
                    savedUUIDs.insert(uuidString)
                }
            }
        }

        // Clean up any screenshots that are no longer associated with a tab.
        let savedUUIDsCopy = savedUUIDs
        Task {
            try? await imageStore?.clearAllScreenshotsExcluding(savedUUIDsCopy)
        }

        return savedTabs.isEmpty ? nil : savedTabs
    }

    private func write(tabStateData: Data?, path: URL?) {
        guard let data = tabStateData, let path = path else { return }
        do {
            try data.write(to: path, options: [])
            logger.log("PreserveTabs write succeeded with bytes count: \(data.count)",
                       level: .debug,
                       category: .tabs)
        } catch {
            // Failure could happen when restoring
            logger.log("PreserveTabs write failed with bytes count: \(data.count)",
                       level: .debug,
                       category: .tabs)
        }
    }
}

// MARK: Tests
extension LegacyTabManagerStoreImplementation {
    func testTabOnDisk() -> [LegacySavedTab] {
        guard AppConstants.isRunningTest else {
            logger.log("This method is being called in NON-TESTING code. Do NOT do this!",
                       level: .fatal,
                       category: .tabs)
            fatalError()
        }

        return tabs
    }
}
