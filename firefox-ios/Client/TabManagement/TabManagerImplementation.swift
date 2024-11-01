// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Storage
import Common
import Shared
import WebKit

// This class subclasses the legacy tab manager temporarily so we can
// gradually migrate to the new system
class TabManagerImplementation: LegacyTabManager, Notifiable, WindowSimpleTabsProvider {
    private let tabDataStore: TabDataStore
    private let tabSessionStore: TabSessionStore
    private let imageStore: DiskImageStore?
    private let tabMigration: TabMigrationUtility
    private var tabsTelemetry = TabsTelemetry()
    private let windowManager: WindowManager
    private let windowIsNew: Bool
    var notificationCenter: NotificationProtocol
    var inactiveTabsManager: InactiveTabsManagerProtocol

    override var normalActiveTabs: [Tab] {
        let inactiveTabs = getInactiveTabs()
        let activeTabs = tabs.filter { $0.isPrivate == false && !inactiveTabs.contains($0) }
        return activeTabs
    }

    init(profile: Profile,
         imageStore: DiskImageStore = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         uuid: ReservedWindowUUID,
         tabDataStore: TabDataStore? = nil,
         tabSessionStore: TabSessionStore = DefaultTabSessionStore(),
         tabMigration: TabMigrationUtility? = nil,
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         inactiveTabsManager: InactiveTabsManagerProtocol = InactiveTabsManager(),
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        let dataStore =  tabDataStore ?? DefaultTabDataStore(logger: logger, fileManager: DefaultTabFileManager())
        self.tabDataStore = dataStore
        self.tabSessionStore = tabSessionStore
        self.imageStore = imageStore
        self.tabMigration = tabMigration ?? DefaultTabMigrationUtility(tabDataStore: dataStore)
        self.notificationCenter = notificationCenter
        self.inactiveTabsManager = inactiveTabsManager
        self.windowManager = windowManager
        self.windowIsNew = uuid.isNew
        super.init(profile: profile, uuid: uuid.uuid)

        setupNotifications(forObserver: self,
                           observing: [UIApplication.willResignActiveNotification,
                                       .TabMimeTypeDidSet])
    }

    // MARK: - Restore tabs

    override func restoreTabs(_ forced: Bool = false) {
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
                selectTab(newTab)
            }
            return
        }

        isRestoringTabs = true
        AppEventQueue.started(.tabRestoration(windowUUID))

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
            await buildTabRestore(window: await tabMigration.runMigration(for: windowUUID))
            logger.log("Tabs restore ended after migration", level: .debug, category: .tabs)
            logger.log("Normal tabs count; \(normalTabs.count), Inactive tabs count; \(inactiveTabs.count), Private tabs count; \(privateTabs.count)", level: .debug, category: .tabs)
        }
    }

    private func restoreOnly() {
        tabs = [Tab]()
        Task {
            // Only attempt a tab data store fetch if we know we should have tabs on disk (ignore new windows)
            let windowData: WindowData? = windowIsNew ? nil : await self.tabDataStore.fetchWindowData(uuid: windowUUID)
            await buildTabRestore(window: windowData)
            logger.log("Tabs restore ended after fetching window data", level: .debug, category: .tabs)
            logger.log("Normal tabs count; \(normalTabs.count), Inactive tabs count; \(inactiveTabs.count), Private tabs count; \(privateTabs.count)", level: .debug, category: .tabs)
        }
    }

    private func buildTabRestore(window: WindowData?) async {
        defer {
            isRestoringTabs = false
            tabRestoreHasFinished = true
            AppEventQueue.completed(.tabRestoration(windowUUID))
        }

        let nonPrivateTabs = window?.tabData.filter { !$0.isPrivate }

        guard let windowData = window,
              let nonPrivateTabs,
              !nonPrivateTabs.isEmpty,
              tabs.isEmpty
        else {
            // Always make sure there is a single normal tab
            // Note: this is where the first tab in a newly-created browser window will be added
            await generateEmptyTab()
            logger.log("There was no tabs restored, creating a normal tab",
                       level: .debug,
                       category: .tabs)

            return
        }
        await generateTabs(from: windowData)
        cleanUpUnusedScreenshots()
        cleanUpTabSessionData()

        await MainActor.run {
            for delegate in delegates {
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
            newTab.url = URL(string: tabData.siteUrl, invalidCharacters: false)
            newTab.lastTitle = tabData.title
            newTab.tabUUID = tabData.id.uuidString
            newTab.screenshotUUID = tabData.id
            newTab.firstCreatedTime = tabData.createdAtTime.toTimestamp()
            newTab.lastExecutedTime = tabData.lastUsedTime.toTimestamp()
            let groupData = LegacyTabGroupData(
                searchTerm: tabData.tabGroupData?.searchTerm ?? "",
                searchUrl: tabData.tabGroupData?.searchUrl ?? "",
                nextReferralUrl: tabData.tabGroupData?.nextUrl ?? "",
                tabHistoryCurrentState: tabData.tabGroupData?.tabHistoryCurrentState?.rawValue ?? ""
            )
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

        if let tabToSelect {
            selectTab(tabToSelect)
        } else {
            // If `tabToSelect` is nil after restoration, force selection of the most recent normal active tab if one exists.
            guard let mostRecentActiveTab = mostRecentTab(inTabs: normalActiveTabs) else {
                selectTab(addTab())
                return
            }

            selectTab(mostRecentActiveTab)
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
    private func generateEmptyTab() async {
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

        logger.log("Preserve tabs started", level: .debug, category: .tabs)
        preserveTabs(forced: false)
    }

    private func preserveTabs(forced: Bool) {
        Task {
            // FIXME FXIOS-10059 TabManagerImplementation's preserveTabs is called with a nil selectedTab
            let windowData = WindowData(id: windowUUID,
                                        activeTabId: self.selectedTabUUID ?? UUID(),
                                        tabData: self.generateTabDataForSaving())
            await tabDataStore.saveWindowData(window: windowData, forced: forced)

            // Save simple tabs, used by widget extension
            windowManager.performMultiWindowAction(.saveSimpleTabs)

            logger.log("Preserve tabs ended", level: .debug, category: .tabs)
        }
    }

    private func generateTabDataForSaving() -> [TabData] {
        let tabsToSave = tabs

        let tabData = tabsToSave.map { tab in
            let oldTabGroupData = tab.metadataManager?.tabGroupData
            let state = TabGroupTimerState(rawValue: oldTabGroupData?.tabHistoryCurrentState ?? "")
            let groupData = TabGroupData(searchTerm: oldTabGroupData?.tabAssociatedSearchTerm,
                                         searchUrl: oldTabGroupData?.tabAssociatedSearchUrl,
                                         nextUrl: oldTabGroupData?.tabAssociatedNextUrl,
                                         tabHistoryCurrentState: state)

            let tabId =  UUID(uuidString: tab.tabUUID) ?? UUID()
            if tab.url == nil {
                logger.log("Tab has empty tab.URL for saving for tab id \(tabId). It was last used \(Date.fromTimestamp(tab.lastExecutedTime))",
                           level: .debug,
                           category: .tabs)
            }

            return TabData(id: tabId,
                           title: tab.lastTitle,
                           siteUrl: tab.url?.absoluteString ?? tab.lastKnownUrl?.absoluteString ?? "",
                           faviconURL: tab.faviconURL,
                           isPrivate: tab.isPrivate,
                           lastUsedTime: Date.fromTimestamp(tab.lastExecutedTime),
                           createdAtTime: Date.fromTimestamp(tab.firstCreatedTime),
                           tabGroupData: groupData)
        }

        let logInfo: String
        let windowCount = windowManager.windows.count
        let totalTabCount =
        (windowCount > 1 ? windowManager.allWindowTabManagers().map({ $0.normalTabs.count }).reduce(0, +) : 0)
        logInfo = (windowCount == 1) ? "(1 window [\(windowUUID)])" : "(of \(totalTabCount) total tabs across \(windowCount) windows)"
        logger.log("Tab manager is preserving \(tabData.count) tabs \(logInfo)", level: .debug, category: .tabs)

        return tabData
    }

    /// storeChanges is called when a web view has finished loading a page, or when a tab is removed, and in other cases.
    override func storeChanges() {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        windowManager.performMultiWindowAction(.storeTabs)
        preserveTabs()
        saveSessionData(forTab: selectedTab)
    }

    override func saveSessionData(forTab tab: Tab?) {
        guard let tab = tab,
              let tabSession = tab.webView?.interactionState as? Data,
              let tabID = UUID(uuidString: tab.tabUUID)
        else { return }

        self.tabSessionStore.saveTabSession(tabID: tabID, sessionData: tabSession)
    }

    private func saveAllTabData() {
        // Only preserve tabs after the restore has finished
        guard tabRestoreHasFinished else { return }

        saveSessionData(forTab: selectedTab)
        preserveTabs(forced: true)
    }

    // MARK: - Select Tab

    /// This function updates the _selectedIndex.
    /// Note: it is safe to call this with `tab` and `previous` as the same tab, for use in the case
    /// where the index of the tab has changed (such as after deletion).
    override func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        // Fallback everywhere to selectedTab if no previous tab
        let previous = previous ?? selectedTab

        guard let tab = tab,
              let tabUUID = UUID(uuidString: tab.tabUUID)
        else {
            logger.log("Selected tab doesn't exist",
                       level: .debug,
                       category: .tabs)
            return
        }

        let url = tab.url

        logger.log("Select tab",
                   level: .info,
                   category: .tabs)

        // Before moving to a new tab save the current tab session data in order to preserve things like scroll position
        saveSessionData(forTab: selectedTab)

        willSelectTab(url)

        let isPrivateBrowsing = previous?.isPrivate
        previous?.metadataManager?.updateTimerAndObserving(state: .tabSwitched, isPrivate: isPrivateBrowsing ?? false)
        tab.metadataManager?.updateTimerAndObserving(state: .tabSelected, isPrivate: tab.isPrivate)

        // Make sure to wipe the private tabs if the user has the pref turned on
        if shouldClearPrivateTabs(), !tab.isPrivate {
            removeAllPrivateTabs()
        }

        _selectedIndex = tabs.firstIndex(of: tab) ?? -1

        preserveTabs()

        let sessionData = tabSessionStore.fetchTabSession(tabID: tabUUID)
        selectTabWithSession(tab: tab, sessionData: sessionData)

        // Default to false if the feature flag is not enabled
        var isPrivate = false
        if featureFlags.isFeatureEnabled(.feltPrivacySimplifiedUI, checking: .buildOnly) {
            isPrivate = tab.isPrivate
        }

        let action = PrivateModeAction(isPrivate: isPrivate,
                                       windowUUID: windowUUID,
                                       actionType: PrivateModeActionType.setPrivateModeTo)
        store.dispatch(action)

        didSelectTab(url)
        updateMenuItemsForSelectedTab()

        // Broadcast updates for any listeners
        delegates.forEach {
            $0.get()?.tabManager(
                self,
                didSelectedTabChange: tab,
                previousTab: previous,
                isRestoring: !tabRestoreHasFinished
            )
        }

        if let tab = previous {
            TabEvent.post(.didLoseFocus, for: tab)
        }
        if let tab = selectedTab {
            TabEvent.post(.didGainFocus, for: tab)
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .tab)

        // Note: we setup last session private case as the session is tied to user's selected
        // tab but there are times when tab manager isn't available and we need to know
        // users's last state (Private vs Regular)
        UserDefaults.standard.set(selectedTab?.isPrivate ?? false,
                                  forKey: PrefsKeys.LastSessionWasPrivate)
    }

    private func removeAllPrivateTabs() {
        // reset the selectedTabIndex if we are on a private tab because we will be removing it.
        if selectedTab?.isPrivate ?? false {
            _selectedIndex = -1
        }
        privateTabs.forEach { tab in
            tab.close()
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab, isRestoring: false) }
        }
        tabs = normalTabs
    }

    private func willSelectTab(_ url: URL?) {
        tabsTelemetry.startTabSwitchMeasurement()
    }

    private func didSelectTab(_ url: URL?) {
        tabsTelemetry.stopTabSwitchMeasurement()
        let isNativeErrorPage = featureFlags.isFeatureEnabled(.nativeErrorPage, checking: .buildOnly)

        // If app starts with error url, first homepage appears and
        // then error page is loaded. To directly load error page
        // isNativeErrorPage flag is added. If native error page flag enabled
        // then isNativeErrorPage = true.

        let action = GeneralBrowserAction(selectedTabURL: url,
                                          isPrivateBrowsing: selectedTab?.isPrivate ?? false,
                                          isNativeErrorPage: isNativeErrorPage,
                                          windowUUID: windowUUID,
                                          actionType: GeneralBrowserActionType.updateSelectedTab)
        store.dispatch(action)
    }

    private func selectTabWithSession(tab: Tab, sessionData: Data?) {
        assert(Thread.isMainThread, "Currently expected to be called only on main thread.")
        let configuration: WKWebViewConfiguration = tab.isPrivate ? self.privateConfiguration : self.configuration

        selectedTab?.createWebview(with: sessionData, configuration: configuration)
        selectedTab?.lastExecutedTime = Date.now()
    }

    // MARK: - Screenshots

    override func tabDidSetScreenshot(_ tab: Tab, hasHomeScreenshot: Bool) {
        guard tab.screenshot != nil else {
            // Remove screenshot from image store so we can use favicon
            // when a screenshot isn't available for the associated tab url
            removeScreenshot(tab: tab)
            return
        }

        storeScreenshot(tab: tab)
    }

    func storeScreenshot(tab: Tab) {
        guard let screenshot = tab.screenshot else { return }

        Task {
            try? await imageStore?.saveImageForKey(tab.tabUUID, image: screenshot)
        }
    }

    func removeScreenshot(tab: Tab) {
        Task {
            await imageStore?.deleteImageForKey(tab.tabUUID)
        }
    }

    private func cleanUpUnusedScreenshots() {
        // Clean up any screenshots that are no longer associated with a tab.
        var savedUUIDs = Set<String>()
        tabs.forEach { savedUUIDs.insert($0.screenshotUUID?.uuidString ?? "") }
        let savedUUIDsCopy = savedUUIDs
        Task {
            try? await imageStore?.clearAllScreenshotsExcluding(savedUUIDsCopy)
        }
    }

    private func cleanUpTabSessionData() {
        let liveTabs = tabs.compactMap { UUID(uuidString: $0.tabUUID) }
        Task {
            await tabSessionStore.deleteUnusedTabSessionData(keeping: liveTabs)
        }
    }

    // MARK: - Inactive tabs
    override func getInactiveTabs() -> [Tab] {
        let inactiveTabsEnabled = profile.prefs.boolForKey(PrefsKeys.FeatureFlags.InactiveTabs)
        guard inactiveTabsEnabled ?? true else { return [] }
        return inactiveTabsManager.getInactiveTabs(tabs: tabs)
    }

    @MainActor
    override func removeAllInactiveTabs() async {
        let currentModeTabs = getInactiveTabs()
        backupCloseTabs = currentModeTabs
        for tab in currentModeTabs {
            await self.removeTab(tab.tabUUID)
        }
        storeChanges()
    }

    @MainActor
    override func undoCloseInactiveTabs() async {
        tabs.append(contentsOf: backupCloseTabs)
        storeChanges()
        backupCloseTabs = [Tab]()
    }

    override func clearAllTabsHistory() {
        super.clearAllTabsHistory()
        Task {
            await tabSessionStore.deleteUnusedTabSessionData(keeping: [])
        }
    }

    @MainActor
    func closeTab(by url: URL) async {
        // Find the tab with the specified URL
        if let tabToClose = tabs.first(where: { $0.url == url }) {
            await self.removeTab(tabToClose.tabUUID)
        }
    }

    // MARK: - Update Menu Items
    private func updateMenuItemsForSelectedTab() {
        guard let selectedTab,
              var menuItems = UIMenuController.shared.menuItems
        else { return }

        if selectedTab.mimeType == MIMEType.PDF {
            // Iterate in reverse order to avoid index out of range errors when removing items
            for index in stride(from: menuItems.count - 1, through: 0, by: -1) {
                if menuItems[index].action == MenuHelperWebViewModel.selectorSearchWith ||
                    menuItems[index].action == MenuHelperWebViewModel.selectorFindInPage {
                    menuItems.remove(at: index)
                }
            }
        } else if !menuItems.contains(where: {
            $0.title == .MenuHelperSearchWithFirefox ||
            $0.title == .MenuHelperFindInPage
        }) {
            let searchItem = UIMenuItem(
                title: .MenuHelperSearchWithFirefox,
                action: MenuHelperWebViewModel.selectorSearchWith
            )
            let findInPageItem = UIMenuItem(
                title: .MenuHelperFindInPage,
                action: MenuHelperWebViewModel.selectorFindInPage
            )
            menuItems.append(contentsOf: [searchItem, findInPageItem])
        }
        UIMenuController.shared.menuItems = menuItems
    }

    // MARK: - Notifiable

    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.willResignActiveNotification:
            saveAllTabData()
        case .TabMimeTypeDidSet:
            guard windowUUID == notification.windowUUID else { return }
            updateMenuItemsForSelectedTab()
        default:
            break
        }
    }

    // MARK: - WindowSimpleTabsProvider

    func windowSimpleTabs() -> [TabUUID: SimpleTab] {
        // FIXME possibly also related FXIOS-10059 TabManagerImplementation's preserveTabs is called with a nil selectedTab
        let windowData = WindowData(id: windowUUID,
                                    activeTabId: self.selectedTabUUID ?? UUID(),
                                    tabData: self.generateTabDataForSaving())
        return SimpleTab.convertToSimpleTabs(windowData.tabData)
    }
}
