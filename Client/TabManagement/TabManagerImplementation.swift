// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Storage
import Common
import Shared

// This class subclasses the legacy tab manager temporarily so we can
// gradually migrate to the new system
class TabManagerImplementation: LegacyTabManager, Notifiable {
    private let tabDataStore: TabDataStore
    private let tabSessionStore: TabSessionStore
    private let imageStore: DiskImageStore?
    private let tabMigration: TabMigrationUtility
    var tabRestoreHasFinished = false
    var notificationCenter: NotificationProtocol

    init(profile: Profile,
         imageStore: DiskImageStore?,
         logger: Logger = DefaultLogger.shared,
         tabDataStore: TabDataStore = DefaultTabDataStore(),
         tabSessionStore: TabSessionStore = DefaultTabSessionStore(),
         tabMigration: TabMigrationUtility = DefaultTabMigrationUtility(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
            self.tabDataStore = tabDataStore
            self.tabSessionStore = tabSessionStore
            self.imageStore = imageStore
            self.tabMigration = tabMigration
            self.notificationCenter = notificationCenter
            super.init(profile: profile, imageStore: imageStore)

            setupNotifications(forObserver: self,
                               observing: [UIApplication.willResignActiveNotification])
    }

    // MARK: - Restore tabs

    override func restoreTabs(_ forced: Bool = false) {
        guard shouldUseNewTabStore()
        else {
            super.restoreTabs(forced)
            return
        }

        guard !isRestoringTabs,
              forced || tabs.isEmpty
        else {
            logger.log("No restore tabs running",
                       level: .debug,
                       category: .tabs)
            return
        }

        logger.log("Tabs restore started being force; \(forced), with empty tabs; \(tabs.isEmpty)",
                   level: .debug,
                   category: .tabs)

        guard !AppConstants.isRunningUITests,
              !DebugSettingsBundleOptions.skipSessionRestore
        else {
            if tabs.isEmpty {
                let newTab = addTab()
                super.selectTab(newTab)
            }
            return
        }

        isRestoringTabs = true

        guard tabMigration.shouldRunMigration else {
            logger.log("Not running the migration",
                       level: .debug,
                       category: .tabs)
            restoreOnly()
            return
        }

        logger.log("Running the migration",
                   level: .debug,
                   category: .tabs)
        migrateAndRestore()
    }

    private func migrateAndRestore() {
        Task {
            await buildTabRestore(window: await tabMigration.runMigration(savedTabs: store.tabs))
            logger.log("Tabs restore ended after migration", level: .debug, category: .tabs)
            logger.log("Normal tabs count; \(normalTabs.count), Inactive tabs count; \(inactiveTabs.count), Private tabs count; \(privateTabs.count)", level: .debug, category: .tabs)
        }
    }

    private func restoreOnly() {
        tabs = [Tab]()
        Task {
            await buildTabRestore(window: await self.tabDataStore.fetchWindowData())
            logger.log("Tabs restore ended after fetching window data", level: .debug, category: .tabs)
            logger.log("Normal tabs count; \(normalTabs.count), Inactive tabs count; \(inactiveTabs.count), Private tabs count; \(privateTabs.count)", level: .debug, category: .tabs)

            // Safety check incase something went wrong during launch where a migration should have occured
            if tabs.count <= 1 && store.tabs.count > 1 {
                logger.log("Rerunning migration due to inconsistent tab counts, old tab store count: \(store.tabs.count)",
                           level: .fatal,
                           category: .tabs)
                isRestoringTabs = true
                migrateAndRestore()
            }
        }
    }

    private func buildTabRestore(window: WindowData?) async {
        defer {
            isRestoringTabs = false
            tabRestoreHasFinished = true
        }

        guard let windowData = window,
              !windowData.tabData.isEmpty,
              tabs.isEmpty
        else {
            // Always make sure there is a single normal tab
            await generateEmptyTab()
            logger.log("There was no tabs restored, creating a normal tab",
                       level: .debug,
                       category: .tabs)

            return
        }
        await generateTabs(from: windowData)

        for delegate in delegates {
            ensureMainThread {
                delegate.get()?.tabManagerDidRestoreTabs(self)
            }
        }
    }

    /// Creates the webview so needs to live on the main thread
    @MainActor
    private func generateTabs(from windowData: WindowData) async {
        let filteredTabs = filterPrivateTabs(from: windowData,
                                             clearPrivateTabs: shouldClearPrivateTabs())
        var tabToSelect: Tab?

        for tabData in filteredTabs {
            let newTab = addTab(flushToDisk: false, zombie: true, isPrivate: tabData.isPrivate)
            newTab.url = URL(string: tabData.siteUrl)
            newTab.lastTitle = tabData.title
            newTab.tabUUID = tabData.id.uuidString
            newTab.screenshotUUID = tabData.id
            newTab.firstCreatedTime = tabData.createdAtTime.toTimestamp()
            newTab.lastExecutedTime = tabData.lastUsedTime.toTimestamp()
            newTab.sessionData = LegacySessionData(currentPage: 0,
                                                   urls: [],
                                                   lastUsedTime: tabData.lastUsedTime.toTimestamp())
            let groupData = LegacyTabGroupData(searchTerm: tabData.tabGroupData?.searchTerm ?? "",
                                               searchUrl: tabData.tabGroupData?.searchUrl ?? "",
                                               nextReferralUrl: tabData.tabGroupData?.nextUrl ?? "",
                                               tabHistoryCurrentState: tabData.tabGroupData?.tabHistoryCurrentState?.rawValue ?? "")
            newTab.metadataManager?.tabGroupData = groupData

            if newTab.url == nil {
                logger.log("Tab restored has empty URL for tab id \(tabData.id.uuidString). It was last used \(tabData.lastUsedTime)",
                           level: .debug,
                           category: .tabs)
            }

            // Restore screenshot
            restoreScreenshot(tab: newTab)

            if windowData.activeTabId == tabData.id {
                tabToSelect = newTab
            }
        }

        logger.log("There was \(filteredTabs.count) tabs restored",
                   level: .debug,
                   category: .tabs)

        selectTab(tabToSelect)

        // If tabToSelect is nil after restoration, force selection of first tab normal tab
        if tabToSelect == nil {
            guard let tabToSelect = tabs.first(where: { !$0.isPrivate }) else {
                selectTab(addTab())
                return
            }

            selectTab(tabToSelect)
        }
    }

    private func filterPrivateTabs(from windowData: WindowData, clearPrivateTabs: Bool) -> [TabData] {
        var savedTabs = windowData.tabData
        if clearPrivateTabs {
            savedTabs = windowData.tabData.filter { !$0.isPrivate }
        }
        return savedTabs
    }

    /// Creates the webview so needs to live on the main thread
    @MainActor
    private func generateEmptyTab() {
        let newTab = addTab()
        selectTab(newTab)
    }

    private func restoreScreenshot(tab: Tab) {
        Task {
            let screenshot = try? await imageStore?.getImageForKey(tab.tabUUID)
            tab.setScreenshot(screenshot)
        }
    }

    // MARK: - Save tabs

    override func preserveTabs() {
        // Only preserve tabs after the restore has finished
        guard tabRestoreHasFinished else { return }

        // For now we want to continue writing to both data stores so that we can revert to the old system if needed
        super.preserveTabs()
        guard shouldUseNewTabStore() else { return }

        logger.log("Preserve tabs started", level: .debug, category: .tabs)

        preserveTabs(forced: false)
    }

    private func preserveTabs(forced: Bool) {
        Task {
            // This value should never be nil but we need to still treat it as if it can be nil until the old code is removed
            let activeTabID = UUID(uuidString: self.selectedTab?.tabUUID ?? "") ?? UUID()
            // Hard coding the window ID until we later add multi-window support
            let windowData = WindowData(id: UUID(uuidString: "44BA0B7D-097A-484D-8358-91A6E374451D")!,
                                        activeTabId: activeTabID,
                                        tabData: self.generateTabDataForSaving())
            await tabDataStore.saveWindowData(window: windowData, forced: forced)

            logger.log("Preserve tabs ended", level: .debug, category: .tabs)
        }
    }

    private func generateTabDataForSaving() -> [TabData] {
        let tabData = tabs.map { tab in
            let oldTabGroupData = tab.metadataManager?.tabGroupData
            let state = TabGroupTimerState(rawValue: oldTabGroupData?.tabHistoryCurrentState ?? "")
            let groupData = TabGroupData(searchTerm: oldTabGroupData?.tabAssociatedSearchTerm,
                                         searchUrl: oldTabGroupData?.tabAssociatedSearchUrl,
                                         nextUrl: oldTabGroupData?.tabAssociatedNextUrl,
                                         tabHistoryCurrentState: state)

            let tabId = UUID(uuidString: tab.tabUUID) ?? UUID()
            let logMessage = "for saving for tab id \(tabId). It was last used \(Date.fromTimestamp(tab.lastExecutedTime ?? 0))"
            if tab.url == nil {
                logger.log("Tab has empty tab.URL \(logMessage)",
                           level: .debug,
                           category: .tabs)
            } else if tab.lastKnownUrl == nil {
                logger.log("Tab has empty tab.lastKnownURL \(logMessage)",
                           level: .fatal,
                           category: .tabs)
            }

            return TabData(id: tabId,
                           title: tab.lastTitle,
                           siteUrl: tab.url?.absoluteString ?? tab.lastKnownUrl?.absoluteString ?? "",
                           faviconURL: tab.faviconURL,
                           isPrivate: tab.isPrivate,
                           lastUsedTime: Date.fromTimestamp(tab.lastExecutedTime ?? 0),
                           createdAtTime: Date.fromTimestamp(tab.firstCreatedTime ?? 0),
                           tabGroupData: groupData)
        }

        logger.log("We are preserving \(tabData.count) tabs",
                   level: .debug,
                   category: .tabs)

        return tabData
    }

    /// storeChanges is called when a web view has finished loading a page
    override func storeChanges() {
        guard shouldUseNewTabStore()
        else {
            super.storeChanges()
            return
        }

        saveTabs(toProfile: profile, normalTabs)
        preserveTabs()
        saveCurrentTabSessionData()
    }

    private func saveCurrentTabSessionData() {
        guard #available(iOS 15.0, *),
              let selectedTab = self.selectedTab,
              let tabSession = selectedTab.webView?.interactionState as? Data,
              let tabID = UUID(uuidString: selectedTab.tabUUID)
        else { return }

        Task {
            await self.tabSessionStore.saveTabSession(tabID: tabID, sessionData: tabSession)
        }
    }

    private func saveAllTabData() {
        // Only preserve tabs after the restore has finished
        guard tabRestoreHasFinished else { return }

        saveCurrentTabSessionData()
        preserveTabs(forced: true)
    }

    // MARK: - Select Tab
    override func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        guard shouldUseNewTabStore(),
              let tab = tab,
              let tabUUID = UUID(uuidString: tab.tabUUID)
        else {
            super.selectTab(tab, previous: previous)
            return
        }

        // Before moving to a new tab save the current tab session data in order to preseve things like scroll position
        saveCurrentTabSessionData()

        guard !AppConstants.isRunningUITests,
              !DebugSettingsBundleOptions.skipSessionRestore
        else {
            super.selectTab(tab, previous: previous)
            return
        }

        Task(priority: .high) {
            if tab.isFxHomeTab {
                await selectTabWithSession(tab: tab,
                                           previous: previous,
                                           sessionData: nil)
            } else {
                let sessionData = await tabSessionStore.fetchTabSession(tabID: tabUUID)
                await selectTabWithSession(tab: tab,
                                           previous: previous,
                                           sessionData: sessionData)
            }
        }
    }

    @MainActor
    private func selectTabWithSession(tab: Tab, previous: Tab?, sessionData: Data?) {
        super.selectTab(tab, previous: previous, sessionData: sessionData)
    }

    private func shouldUseNewTabStore() -> Bool {
        if #available(iOS 15, *) {
            return true
        }
        return false
    }

    // MARK: - Save screenshot
    override func tabDidSetScreenshot(_ tab: Tab, hasHomeScreenshot: Bool) {
        guard shouldUseNewTabStore()
        else {
            super.tabDidSetScreenshot(tab, hasHomeScreenshot: hasHomeScreenshot)
            return
        }

        storeScreenshot(tab: tab)
    }

    override func storeScreenshot(tab: Tab) {
        guard shouldUseNewTabStore(),
              let screenshot = tab.screenshot
        else {
            super.storeScreenshot(tab: tab)
            return
        }

        Task {
            try? await imageStore?.saveImageForKey(tab.tabUUID, image: screenshot)
        }
    }

    override func removeScreenshot(tab: Tab) {
        guard shouldUseNewTabStore()
        else {
            super.removeScreenshot(tab: tab)
            return
        }

        Task {
            await imageStore?.deleteImageForKey(tab.tabUUID)
        }
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            saveAllTabData()
        default:
            break
        }
    }
}
