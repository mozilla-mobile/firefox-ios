// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import TabDataStore
import Storage
import Common
import Shared
import WebKit
import WebEngine

enum SwitchPrivacyModeResult {
    case createdNewTab
    case usedExistingTab
}

struct BackupCloseTab {
    var tab: Tab
    var restorePosition: Int?
    var isSelected: Bool
}

class TabManagerImplementation: NSObject,
                                TabManager,
                                FeatureFlaggable,
                                SessionCreator {
    let windowUUID: WindowUUID
    let delaySelectingNewPopupTab: TimeInterval = 0.1

    var tabEventWindowResponseType: TabEventHandlerWindowResponseType { return .singleWindow(windowUUID) }
    var isRestoringTabs = false
    var backupCloseTab: BackupCloseTab?
    var notificationCenter: NotificationProtocol
    private(set) var tabs: [Tab]

    var isInactiveTabsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildAndUser)
    }

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    var isDeeplinkOptimizationRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.deeplinkOptimizationRefactor, checking: .buildOnly)
    }

    var isPDFRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.pdfRefactor, checking: .buildOnly)
    }

    var count: Int {
        return tabs.count
    }

    var selectedTab: Tab? {
        if !(0..<count ~= selectedIndex) {
            return nil
        }
        return tabs[selectedIndex]
    }

    var normalActiveTabs: [Tab] {
        let inactiveTabs = getInactiveTabs()
        let activeTabs = tabs.filter { $0.isPrivate == false && !inactiveTabs.contains($0) }
        return activeTabs
    }

    var normalTabs: [Tab] {
        return tabs.filter { !$0.isPrivate }
    }

    var inactiveTabs: [Tab] {
        return normalTabs.filter({ $0.isInactive })
    }

    var privateTabs: [Tab] {
        return tabs.filter { $0.isPrivate }
    }

    var recentlyAccessedNormalTabs: [Tab] {
        // If inactive tabs are enabled, do not include inactive tabs, as they are not "recently" accessed
        var eligibleTabs = isInactiveTabsEnabled ? normalActiveTabs : normalTabs

        eligibleTabs = eligibleTabs.filter { tab in
            if tab.lastKnownUrl == nil {
                return false
            } else if let lastKnownUrl = tab.lastKnownUrl {
                if lastKnownUrl.absoluteString.hasPrefix("internal://") { return false }
                return true
            }
            return tab.isURLStartingPage
        }

        eligibleTabs = SponsoredContentFilterUtility().filterSponsoredTabs(from: eligibleTabs)

        // sort the tabs chronologically
        eligibleTabs = eligibleTabs.sorted { $0.lastExecutedTime > $1.lastExecutedTime }

        return eligibleTabs
    }

    private let inactiveTabsManager: InactiveTabsManagerProtocol
    private let logger: Logger
    private let tabDataStore: TabDataStore
    private let tabSessionStore: TabSessionStore
    private let imageStore: DiskImageStore?
    private let windowManager: WindowManager
    private let windowIsNew: Bool
    private let profile: Profile
    private weak var navigationDelegate: WKNavigationDelegate?
    private var backupCloseTabs = [Tab]()
    private var tabsTelemetry = TabsTelemetry()
    private var delegates = [WeakTabManagerDelegate]()
    // The only tab present before doing tab restoration, since deeplink happens before it
    private var deeplinkTab: Tab?
    var tabRestoreHasFinished = false
    private(set) var selectedIndex: Int = -1

    @MainActor private lazy var tabConfigurationProvider = {
        return TabConfigurationProvider(prefs: profile.prefs)
    }()

    private var selectedTabUUID: UUID? {
        guard let selectedTab = self.selectedTab,
              let uuid = UUID(uuidString: selectedTab.tabUUID) else {
            return nil
        }

        return uuid
    }

    init(profile: Profile,
         imageStore: DiskImageStore = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         uuid: ReservedWindowUUID,
         tabDataStore: TabDataStore? = nil,
         tabSessionStore: TabSessionStore = DefaultTabSessionStore(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         inactiveTabsManager: InactiveTabsManagerProtocol = InactiveTabsManager(),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         tabs: [Tab] = []
    ) {
        let dataStore =  tabDataStore ?? DefaultTabDataStore(logger: logger, fileManager: DefaultTabFileManager())
        self.tabDataStore = dataStore
        self.tabSessionStore = tabSessionStore
        self.imageStore = imageStore
        self.notificationCenter = notificationCenter
        self.inactiveTabsManager = inactiveTabsManager
        self.windowManager = windowManager
        self.windowIsNew = uuid.isNew
        self.windowUUID = uuid.uuid
        self.profile = profile
        self.logger = logger
        self.tabs = tabs

        super.init()

        GlobalTabEventHandlers.configure(with: profile)

        setupNotifications(
            forObserver: self,
            observing: [
                UIApplication.willResignActiveNotification,
                .TabMimeTypeDidSet,
                .BlockPopup,
                .AutoPlayChanged
            ])
    }

    subscript(index: Int) -> Tab? {
        if index >= tabs.count {
            return nil
        }
        return tabs[index]
    }

    subscript(webView: WKWebView) -> Tab? {
        for tab in tabs where tab.webView === webView {
            return tab
        }

        return nil
    }

    // MARK: - Add/Remove Delegate
    func removeDelegate(_ delegate: any TabManagerDelegate, completion: (() -> Void)?) {
        DispatchQueue.main.async { [unowned self] in
            for index in 0 ..< self.delegates.count {
                let del = self.delegates[index]
                if delegate === del.get() || del.get() == nil {
                    self.delegates.remove(at: index)
                    return
                }
            }
            completion?()
        }
    }

    func addDelegate(_ delegate: TabManagerDelegate) {
        self.delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func setNavigationDelegate(_ delegate: WKNavigationDelegate) {
        navigationDelegate = delegate
    }

    // MARK: - Remove Tab
    @MainActor
    func removeTab(_ tabUUID: TabUUID) async {
        guard let index = tabs.firstIndex(where: { $0.tabUUID == tabUUID }) else { return }

        let tab = tabs[index]
        tab.cancelDocumentDownload()

        backupCloseTab = BackupCloseTab(
            tab: tab,
            restorePosition: index,
            isSelected: selectedTab?.tabUUID == tab.tabUUID)

        self.removeTab(tab, flushToDisk: true)
        self.updateSelectedTabAfterRemovalOf(tab, deletedIndex: index)
    }

    func removeTabWithCompletion(_ tabUUID: TabUUID, completion: (() -> Void)?) {
        guard let index = tabs.firstIndex(where: { $0.tabUUID == tabUUID }) else { return }
        let tab = tabs[index]

        DispatchQueue.main.async { [weak self] in
            self?.removeTab(tab, flushToDisk: true)
            self?.updateSelectedTabAfterRemovalOf(tab, deletedIndex: index)
            completion?()
        }
    }

    func removeTabs(_ tabs: [Tab]) {
        for tab in tabs {
            self.removeTab(tab, flushToDisk: false)
        }
        commitChanges()
    }

    @MainActor
    func removeTabs(by urls: [URL]) async {
        let urls = Set(urls)
        let tabsToRemove = normalTabs.filter { tab in
            guard let url = tab.url else { return false }
            return urls.contains(url)
        }
        for tab in tabsToRemove {
            await removeTab(tab.tabUUID)
        }
    }

    @MainActor
    func removeAllTabs(isPrivateMode: Bool) async {
        let currentModeTabs = tabs.filter { $0.isPrivate == isPrivateMode }
        var currentSelectedTab: BackupCloseTab?

        // Backup the selected tab in separate variable as the `removeTab` method called below for each tab will
        // automatically update tab selection as if there was a single tab removal.
        if let tab = selectedTab, tab.isPrivate == isPrivateMode {
            currentSelectedTab = BackupCloseTab(tab: tab,
                                                restorePosition: tabs.firstIndex(of: tab),
                                                isSelected: selectedTab?.tabUUID == tab.tabUUID)
        }
        backupCloseTabs = tabs

        for tab in currentModeTabs {
            await self.removeTab(tab.tabUUID)
        }

        // Save the tab state that existed prior to removals (preserves original selected tab)
        backupCloseTab = currentSelectedTab

        commitChanges()
    }

    /// Remove a tab, will notify delegate of the tab removal
    /// - Parameters:
    ///   - tab: the tab to remove
    ///   - flushToDisk: Will store changes if true, and update selected index
    private func removeTab(_ tab: Tab, flushToDisk: Bool) {
        guard let removalIndex = tabs.firstIndex(where: { $0 === tab }) else {
            logger.log("Could not find index of tab to remove",
                       level: .warning,
                       category: .tabs,
                       description: "Tab count: \(count)")
            return
        }

        // Save the tab's session state before closing it and losing the webView
        if flushToDisk {
            saveSessionData(forTab: tab)
        }

        backupCloseTab = BackupCloseTab(tab: tab,
                                        restorePosition: removalIndex,
                                        isSelected: selectedTab?.tabUUID == tab.tabUUID)
        let prevCount = count
        tabs.remove(at: removalIndex)
        assert(count == prevCount - 1, "Make sure the tab count was actually removed")
        if count != prevCount - 1 {
            logger.log("Make sure the tab count was actually removed",
                       level: .warning,
                       category: .tabs)
        }

        tab.close()

        // Notify of tab removal
        ensureMainThread { @MainActor [unowned self] in
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab, isRestoring: !tabRestoreHasFinished) }
            TabEvent.post(.didClose, for: tab)
        }

        if flushToDisk {
            commitChanges()
        }
    }

    func removeNormalTabsOlderThan(period: TabsDeletionPeriod, currentDate: Date) {
        let calendar = Calendar.current
        let cutoffDate: Date
        switch period {
        case .oneDay:
            cutoffDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        case .oneWeek:
            cutoffDate = calendar.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
        case .oneMonth:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
        }

        let tabsToRemove = normalTabs.filter { tab in
            let lastUsed = Date.fromTimestamp(tab.lastExecutedTime)
            return lastUsed <= cutoffDate
        }

        guard !tabsToRemove.isEmpty else { return }
        removeTabs(tabsToRemove)
    }

    // MARK: - Add Tab
    @MainActor
    func addTab(_ request: URLRequest?, afterTab: Tab?, isPrivate: Bool) -> Tab {
        return addTab(request,
                      afterTab: afterTab,
                      flushToDisk: true,
                      zombie: false,
                      isPrivate: isPrivate)
    }

    @discardableResult
    @MainActor
    func addTab(_ request: URLRequest? = nil,
                afterTab: Tab? = nil,
                zombie: Bool = false,
                isPrivate: Bool = false
    ) -> Tab {
        return addTab(request,
                      afterTab: afterTab,
                      flushToDisk: true,
                      zombie: zombie,
                      isPrivate: isPrivate)
    }

    @MainActor
    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool = true, isPrivate: Bool = false) {
        if urls.isEmpty {
            return
        }

        var tab: Tab?
        for url in urls {
            tab = addTab(URLRequest(url: url), flushToDisk: false, zombie: zombie, isPrivate: isPrivate)
        }

        if shouldSelectTab {
            // Select the most recent.
            selectTab(tab)
        }

        // Okay now notify that we bulk-loaded so we can adjust counts and animate changes.
        delegates.forEach { $0.get()?.tabManagerDidAddTabs(self) }

        // Flush.
        commitChanges()
    }

    @MainActor
    private func addTab(_ request: URLRequest? = nil,
                        afterTab: Tab? = nil,
                        flushToDisk: Bool,
                        zombie: Bool,
                        isPrivate: Bool = false
    ) -> Tab {
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: windowUUID)
        configureTab(tab, request: request, afterTab: afterTab, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    // MARK: - Get Tab
    func getTabForUUID(uuid: TabUUID) -> Tab? {
        let filterdTabs = tabs.filter { tab -> Bool in
            tab.tabUUID == uuid
        }
        return filterdTabs.first
    }

    func getTabForURL(_ url: URL) -> Tab? {
        return tabs.first(where: { $0.webView?.url == url })
    }

    // MARK: - Undo Close Tab
    @MainActor
    func undoCloseTab() {
        assert(Thread.isMainThread)
        guard let backupCloseTab = self.backupCloseTab else { return }

        let previouslySelectedTab = selectedTab
        if let index = backupCloseTab.restorePosition {
            tabs.insert(backupCloseTab.tab, at: index)
        } else {
            tabs.append(backupCloseTab.tab)
        }

        if backupCloseTab.isSelected {
            self.selectTab(backupCloseTab.tab)
        } else if let tabToSelect = previouslySelectedTab {
            self.selectTab(tabToSelect)
        }

        delegates.forEach { $0.get()?.tabManagerUpdateCount() }
        commitChanges()
    }

    @MainActor
    func undoCloseAllTabs() {
        assert(Thread.isMainThread)
        guard !backupCloseTabs.isEmpty else { return }
        tabs = backupCloseTabs
        commitChanges()
        backupCloseTabs = [Tab]()
        if backupCloseTab != nil {
            selectTab(backupCloseTab?.tab)
            backupCloseTab = nil
        }
    }

    // MARK: - Restore tabs

    @MainActor
    func restoreTabs(_ forced: Bool = false) {
        assert(Thread.isMainThread)
        if isDeeplinkOptimizationRefactorEnabled {
            // Deeplinks happens before tab restoration, so we should have a tab already present in the tabs list
            // if the application was opened from a deeplink.
            deeplinkTab = tabs.popLast()
        }

        guard !isRestoringTabs,
              forced || tabs.isEmpty
        else {
            logger.log("No restore tabs running",
                       level: .debug,
                       category: .tabs)
            return
        }

        logger.log("Tabs restore started being force; \(forced), with empty tabs; \(tabs.isEmpty), crashed at last launch is \(logger.crashedLastLaunch)",
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

        restoreTabs()
    }

    @MainActor
    private func updateSelectedTabAfterRemovalOf(_ removedTab: Tab, deletedIndex: Int) {
        assert(Thread.isMainThread)
        // If the currently selected tab has been deleted, try to select the next most reasonable tab.
        if deletedIndex == selectedIndex {
            // First, check if the user has closed the last viable tab of the current browsing mode: private or normal.
            // If so, handle this gracefully (i.e. close the last private tab should open the most recent normal active tab).
            let viableTabs = removedTab.isPrivate
                                 ? privateTabs
                                 : normalActiveTabs // We never want to surface an inactive tab, if inactive tabs enabled
            guard !viableTabs.isEmpty else {
                // If the selected tab is closed, and is private browsing, try to select a recent normal active tab. For all
                // other cases, open a new normal active tab.
                if removedTab.isPrivate,
                   let mostRecentActiveTab = mostRecentTab(inTabs: normalActiveTabs) {
                    selectTab(mostRecentActiveTab, previous: removedTab)
                } else {
                    selectTab(addTab(), previous: removedTab)
                }
                return
            }

            if let mostRecentViableTab = mostRecentTab(inTabs: viableTabs), mostRecentViableTab == removedTab.parent {
                // 1. Try to select the most recently used viable tab, if it's the removed tab's parent.
                selectTab(mostRecentViableTab, previous: removedTab)
            } else if !removedTab.isNormalAndInactive,
                      let rightOrLeftTab = findRightOrLeftTab(forRemovedTab: removedTab, withDeletedIndex: deletedIndex) {
                // 2. Try to select an array neighbour of the same tab type, except if the removed tab is inactive (unlikely
                // edge case).
                selectTab(rightOrLeftTab, previous: removedTab)
            } else {
                // 3. If there are no suitable active tabs to select, create a new normal active tab.
                // (Note: It's possible to fall into here when all tabs have become inactive, especially when debugging.)
                selectTab(addTab(), previous: removedTab)
            }
        } else if deletedIndex < selectedIndex {
            // If we delete a tab in the `tabs` array that's ahead of the selected tab, we need to shift our index.
            // The selected tab itself hasn't actually changed; reselect it to call code paths related to saving, etc.
            if let selectedTab = tabs[safe: selectedIndex - 1] {
                selectTab(selectedTab, previous: selectedTab)
            } else {
                assertionFailure("This should not happen, we should always be able to get the selected tab again.")
                selectTab(addTab())
            }
        }
    }

    private func restoreTabs() {
        tabs = [Tab]()
        Task {
            // Only attempt a tab data store fetch if we know we should have tabs on disk (ignore new windows)
            let windowData: WindowData? = windowIsNew ? nil : await tabDataStore.fetchWindowData(uuid: windowUUID)
            await buildTabRestore(window: windowData)
            await TabErrorTelemetryHelper.shared.validateTabCountAfterRestoringTabs(windowUUID)
            await MainActor.run {
                // Log on main thread, where computed `tab` properties can be accessed without risk of races
                logger.log("Tabs restore ended after fetching window data", level: .debug, category: .tabs)
                logger.log("Normal tabs count; \(normalTabs.count), Inactive tabs count; \(inactiveTabs.count), Private tabs count; \(privateTabs.count)", level: .debug, category: .tabs)
            }
        }
    }

    @objc
    @MainActor
    private func blockPopUpDidChange() {
        assert(Thread.isMainThread)
        let allowPopups = !(profile.prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true)
        // Each tab may have its own configuration, so we should tell each of them in turn.
        for tab in tabs {
            tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
        // The default tab configurations also need to change.
        tabConfigurationProvider.updateAllowsPopups(allowPopups)
    }

    @objc
    @MainActor
    private func autoPlayDidChange() {
        assert(Thread.isMainThread)
        let mediaType = AutoplayAccessors.getMediaTypesRequiringUserActionForPlayback(profile.prefs)
        // https://developer.apple.com/documentation/webkit/wkwebviewconfiguration
        // The web view incorporates our configuration settings only at creation time; we cannot change
        //  those settings dynamically later. So this change will apply to new webviews only.
        tabConfigurationProvider.updateMediaTypesRequiringUserActionForPlayback(mediaType)
    }

    private func buildTabRestore(window: WindowData?) async {
        defer {
            isRestoringTabs = false
            tabRestoreHasFinished = true
            AppEventQueue.completed(.tabRestoration(windowUUID))
        }

        let nonPrivateTabs = window?.tabData.filter { !$0.isPrivate }

        guard let windowData = window else {
            // Always make sure there is a single normal tab
            // Note: this is where the first tab in a newly-created browser window will be added
            await generateEmptyTab()
            logger.log("Not restoring tabs because there is no window data.",
                       level: .warning,
                       category: .tabs)
            return
        }

        guard let nonPrivateTabs,
              !nonPrivateTabs.isEmpty else {
            // Always make sure there is a single normal tab
            // Note: this is where the first tab in a newly-created browser window will be added
            await generateEmptyTab()
            logger.log("Not restoring tabs because there is no tab data on the window data.",
                       level: .warning,
                       category: .tabs)
            return
        }

        guard tabs.isEmpty else {
            // Always make sure there is a single normal tab
            // Note: this is where the first tab in a newly-created browser window will be added
            await generateEmptyTab()
            logger.log("Not restoring tabs because there are in memory tabs already.",
                       level: .warning,
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

    private func shouldClearPrivateTabs() -> Bool {
        // FXIOS-9519: By default if no bool value is set we close the private tabs and mark it true
        return profile.prefs.boolForKey(PrefsKeys.Settings.closePrivateTabs) ?? true
    }

    /// Creates the webview so needs to live on the main thread
    @MainActor
    private func generateTabs(from windowData: WindowData) async {
        let filteredTabs = filterPrivateTabs(from: windowData,
                                             clearPrivateTabs: shouldClearPrivateTabs())
        var tabToSelect: Tab?

        for tabData in filteredTabs {
            let newTab = configureNewTab(with: tabData)
            if isDeeplinkOptimizationRefactorEnabled {
                if deeplinkTab == nil, windowData.activeTabId == tabData.id {
                    tabToSelect = newTab
                }
            } else {
                if windowData.activeTabId == tabData.id {
                    tabToSelect = newTab
                }
            }
        }

        logger.log("There was \(filteredTabs.count) tabs restored",
                   level: .debug,
                   category: .tabs)
        handleTabSelectionAfterRestore(tabToSelect: tabToSelect)
    }

    @MainActor
    private func configureNewTab(with tabData: TabData) -> Tab? {
        let newTab: Tab

        let isDeeplinkTabAlreadyAdded: Bool = if let deeplinkTab {
            tabs.contains { $0.tabUUID == deeplinkTab.tabUUID }
        } else {
            false
        }

        if isDeeplinkOptimizationRefactorEnabled,
           let deeplinkTab,
           !isDeeplinkTabAlreadyAdded,
           deeplinkTab.url?.absoluteString == tabData.siteUrl {
            // if the deeplink tab has the same url of a tab data then use the deeplink tab for the restore
            // in order to prevent a duplicate tab
            newTab = deeplinkTab
            let data = tabSessionStore.fetchTabSession(tabID: tabData.id)
            newTab.webView?.interactionState = data
            tabs.append(newTab)
        } else {
            newTab = addTab(flushToDisk: false, zombie: true, isPrivate: tabData.isPrivate)
        }

        newTab.url = URL(string: tabData.siteUrl)
        newTab.lastTitle = tabData.title
        newTab.tabUUID = tabData.id.uuidString
        newTab.screenshotUUID = tabData.id
        newTab.firstCreatedTime = tabData.createdAtTime.toTimestamp()
        newTab.lastExecutedTime = tabData.lastUsedTime.toTimestamp()
        if let documentSession = tabData.temporaryDocumentSession {
            newTab.restoreTemporaryDocumentSession(documentSession)
        }

        if newTab.url == nil {
            logger.log("Tab restored has empty URL",
                       level: .debug,
                       category: .tabs,
                       extra: [
                        "tabID": tabData.id.uuidString,
                        "lastUsedTime": tabData.lastUsedTime.description
                       ]
            )
        }

        // Restore screenshot
        restoreScreenshot(tab: newTab)
        return newTab
    }

    @MainActor
    private func handleTabSelectionAfterRestore(tabToSelect: Tab?) {
        assert(Thread.isMainThread)
        if isDeeplinkOptimizationRefactorEnabled, let deeplinkTab {
            if let index = tabs.firstIndex(of: deeplinkTab) {
                selectedIndex = index
            } else {
                // the deeplink tab has already been selected via `selectTab` before tab restoration so
                // it just need to be appended to the tabs array
                tabs.append(deeplinkTab)
                selectedIndex = tabs.count - 1
            }
            self.deeplinkTab = nil
            return
        }
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

    func preserveTabs() {
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
            await windowManager.performMultiWindowAction(.saveSimpleTabs)

            logger.log("Preserve tabs ended", level: .debug, category: .tabs)
            await TabErrorTelemetryHelper.shared.recordTabCountAfterPreservingTabs(windowUUID)
        }
    }

    private func generateTabDataForSaving() -> [TabData] {
        var tabsToSave = tabs
        if shouldClearPrivateTabs() {
            tabsToSave = normalTabs
        }

        let tabData = tabsToSave.map { tab in
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
                           temporaryDocumentSession: tab.getTemporaryDocumentsSession())
        }

        let logInfo: String
        let windowCount = windowManager.windows.count
        let totalTabCount =
        (windowCount > 1 ? windowManager.allWindowTabManagers().map({ $0.normalTabs.count }).reduce(0, +) : 0)
        logInfo = (windowCount == 1) ? "(1 window [\(windowUUID)])" : "(of \(totalTabCount) total tabs across \(windowCount) windows)"
        logger.log("Tab manager is preserving \(tabData.count) tabs \(logInfo)", level: .debug, category: .tabs)

        return tabData
    }

    func commitChanges() {
        preserveTabs()
        saveSessionData(forTab: selectedTab)
    }

    @MainActor
    func notifyCurrentTabDidFinishLoading() {
        delegates.forEach {
            $0.get()?.tabManagerTabDidFinishLoading()
        }
    }

    private func saveSessionData(forTab tab: Tab?) {
        guard let tab = tab,
              let tabSession = tab.webView?.interactionState as? Data,
              let tabID = UUID(uuidString: tab.tabUUID)
        else { return }

        self.tabSessionStore.saveTabSession(tabID: tabID, sessionData: tabSession)
    }

    private func saveAllTabData() {
        // Only preserve tabs after the restore has finished
        guard tabRestoreHasFinished, let url = selectedTab?.url, !url.isFxHomeUrl else { return }

        saveSessionData(forTab: selectedTab)
        preserveTabs(forced: true)
    }

    // MARK: - Select Tab

    /// This function updates the selectedIndex.
    /// Note: it is safe to call this with `tab` and `previous` as the same tab, for use in the case
    /// where the index of the tab has changed (such as after deletion).
    @MainActor
    func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        assert(Thread.isMainThread)
        // Fallback everywhere to selectedTab if no previous tab
        let previous = previous ?? selectedTab
        if isPDFRefactorEnabled {
            previous?.pauseDocumentDownload()
        }

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

        // Make sure to wipe the private tabs if the user has the pref turned on and there are private tabs to remove
        if shouldClearPrivateTabs(), !tab.isPrivate && !privateTabs.isEmpty {
            removeAllPrivateTabs()
        }

        selectedIndex = tabs.firstIndex(of: tab) ?? -1

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
        store.dispatchLegacy(action)

        if isPDFRefactorEnabled {
            tab.resumeDocumentDownload()
        }
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

        // Note: we setup last session private case as the session is tied to user's selected
        // tab but there are times when tab manager isn't available and we need to know
        // users's last state (Private vs Regular)
        UserDefaults.standard.set(selectedTab?.isPrivate ?? false,
                                  forKey: PrefsKeys.LastSessionWasPrivate)
    }

    @MainActor
    private func removeAllPrivateTabs() {
        // reset the selectedTabIndex if we are on a private tab because we will be removing it.
        if selectedTab?.isPrivate ?? false {
            selectedIndex = -1
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
        store.dispatchLegacy(action)
    }

    @MainActor
    private func selectTabWithSession(tab: Tab, sessionData: Data?) {
        assert(Thread.isMainThread, "Currently expected to be called only on main thread.")
        let configuration: WKWebViewConfiguration = tabConfigurationProvider.configuration(
            isPrivate: tab.isPrivate
        ).webViewConfiguration
        selectedTab?.createWebview(with: sessionData, configuration: configuration)
        selectedTab?.lastExecutedTime = Date.now()
    }

    // MARK: - TabEventHandler
    func tabDidSetScreenshot(_ tab: Tab) {
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
            do {
                try await imageStore?.saveImageForKey(tab.tabUUID, image: screenshot)
            } catch {
                logger.log("storing screenshot failed with error: \(error)", level: .warning, category: .redux)
            }
        }
    }

    private func removeScreenshot(tab: Tab) {
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
    func getInactiveTabs() -> [Tab] {
        let inactiveTabsPrefEnabled = profile.prefs.boolForKey(PrefsKeys.FeatureFlags.InactiveTabs) ?? true
        let inactiveTabsEnabled = inactiveTabsPrefEnabled && !isTabTrayUIExperimentsEnabled
        guard inactiveTabsEnabled else { return [] }
        return inactiveTabsManager.getInactiveTabs(tabs: tabs)
    }

    @MainActor
    func removeAllInactiveTabs() async {
        let currentModeTabs = getInactiveTabs()
        backupCloseTabs = currentModeTabs
        for tab in currentModeTabs {
            await self.removeTab(tab.tabUUID)
        }
        commitChanges()
    }

    @MainActor
    func undoCloseInactiveTabs() async {
        tabs.append(contentsOf: backupCloseTabs)
        commitChanges()
        backupCloseTabs = [Tab]()
    }

    @MainActor
    func clearAllTabsHistory() {
        assert(Thread.isMainThread)
        guard let selectedTab = selectedTab, let url = selectedTab.url else { return }

        for tab in tabs where tab !== selectedTab {
            tab.clearAndResetTabHistory()
        }
        let tabToSelect: Tab
        if url.isFxHomeUrl {
            tabToSelect = addTab(PrivilegedRequest(url: url) as URLRequest,
                                 afterTab: selectedTab,
                                 isPrivate: selectedTab.isPrivate)
        } else {
            let request = URLRequest(url: url)
            tabToSelect = addTab(request, afterTab: selectedTab, isPrivate: selectedTab.isPrivate)
        }
        selectTab(tabToSelect)
        removeTabWithCompletion(selectedTab.tabUUID, completion: nil)
        Task {
            await tabSessionStore.deleteUnusedTabSessionData(keeping: [])
        }
    }

    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {
        let currentTabs = privateMode ? privateTabs : normalActiveTabs

        guard visibleFromIndex < currentTabs.count, visibleToIndex < currentTabs.count else { return }

        let fromIndex = tabs.firstIndex(of: currentTabs[visibleFromIndex]) ?? tabs.count - 1
        let toIndex = tabs.firstIndex(of: currentTabs[visibleToIndex]) ?? tabs.count - 1

        let previouslySelectedTab = selectedTab

        tabs.insert(tabs.remove(at: fromIndex), at: toIndex)

        if let previouslySelectedTab = previouslySelectedTab,
           let previousSelectedIndex = tabs.firstIndex(of: previouslySelectedTab) {
            selectedIndex = previousSelectedIndex
        }

        commitChanges()
    }

    func expireLoginAlerts() {
        for tab in tabs {
            tab.expireLoginAlert()
        }
    }

    @MainActor
    func switchPrivacyMode() -> SwitchPrivacyModeResult {
        assert(Thread.isMainThread)
        var result = SwitchPrivacyModeResult.usedExistingTab
        guard let selectedTab = selectedTab else { return result }
        let nextSelectedTab: Tab?

        if selectedTab.isPrivate {
            nextSelectedTab = mostRecentTab(inTabs: normalTabs)
        } else if privateTabs.isEmpty {
            nextSelectedTab = addTab(isPrivate: true)
            result = .createdNewTab
        } else {
            nextSelectedTab = mostRecentTab(inTabs: privateTabs)
        }

        selectTab(nextSelectedTab)

        let notificationObject = [Tab.privateModeKey: nextSelectedTab?.isPrivate ?? true]
        NotificationCenter.default.post(name: .TabsPrivacyModeChanged,
                                        object: notificationObject,
                                        userInfo: windowUUID.userInfo)
        return result
    }

    @MainActor
    func addPopupForParentTab(profile: any Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab {
        assert(Thread.isMainThread)
        let popup = Tab(profile: profile,
                        isPrivate: parentTab.isPrivate,
                        windowUUID: windowUUID)
        // Configure the tab for the child popup webview. In this scenario we need to be sure to pass along
        // the specific `configuration` that we are given by the WKUIDelegate callback, since if we do not
        // use this configuration WebKit will throw an exception.
        configureTab(popup,
                     request: nil,
                     afterTab: parentTab,
                     flushToDisk: true,
                     zombie: false,
                     isPopup: true,
                     requiredConfiguration: configuration)

        // Wait momentarily before selecting the new tab, otherwise the parent tab
        // may be unable to set `window.location` on the popup immediately after
        // calling `window.open("")`.
        DispatchQueue.main.asyncAfter(deadline: .now() + delaySelectingNewPopupTab) {
            self.selectTab(popup)
        }

        return popup
    }

    /// Note: Inserts AND configures the given tab.
    @MainActor
    private func configureTab(
        _ tab: Tab,
        request: URLRequest?,
        afterTab parent: Tab? = nil,
        flushToDisk: Bool,
        zombie: Bool,
        isPopup: Bool = false,
        requiredConfiguration: WKWebViewConfiguration? = nil
    ) {
        assert(Thread.isMainThread)
        // If network is not available webView(_:didCommit:) is not going to be called
        // We should set request url in order to show url in url bar even no network
        tab.url = request?.url
        var placeNextToParentTab = false
        if parent == nil || parent?.isPrivate != tab.isPrivate {
            tabs.append(tab)
        } else if let parent = parent, var insertIndex = tabs.firstIndex(of: parent) {
            placeNextToParentTab = true
            insertIndex += 1

            tab.parent = parent
            tabs.insert(tab, at: insertIndex)
        }

        delegates.forEach {
            $0.get()?.tabManager(self,
                                 didAddTab: tab,
                                 placeNextToParentTab: placeNextToParentTab,
                                 isRestoring: !tabRestoreHasFinished)
        }

        if !zombie {
            let configuration: WKWebViewConfiguration
            if let required = requiredConfiguration {
                configuration = required
            } else {
                configuration = tabConfigurationProvider.configuration(isPrivate: tab.isPrivate).webViewConfiguration
            }
            tab.createWebview(configuration: configuration)
        }
        tab.navigationDelegate = navigationDelegate

        if let request = request {
            tab.loadRequest(request)
        } else if !isPopup {
            let newTabChoice = NewTabAccessors.getNewTabPage(profile.prefs)
            tab.newTabPageType = newTabChoice
            switch newTabChoice {
            case .homePage:
                // We definitely have a homepage if we've got here
                // (so we can safely dereference it).
                let url = NewTabHomePageAccessors.getHomePage(profile.prefs)!
                tab.loadRequest(URLRequest(url: url))
            case .blankPage:
                break
            default:
                // The common case, where the NewTabPage enum defines
                // one of the about:home pages.
                if let url = newTabChoice.url {
                    tab.loadRequest(PrivilegedRequest(url: url) as URLRequest)
                    tab.url = url
                }
            }
        }

        tab.nightMode = NightModeHelper.isActivated()
        tab.noImageMode = NoImageModeHelper.isActivated(profile.prefs)

        if flushToDisk {
            commitChanges()
        }
    }

    func findRightOrLeftTab(forRemovedTab removedTab: Tab, withDeletedIndex deletedIndex: Int) -> Tab? {
        // We know the fomer index of the removed tab in the full `tabs` array. However, if we want to get the closest
        // neighbouring tab of the same type, we need to map this index into a subarray containing only tabs of that type.
        //
        // Example:
        //          An array with private tabs (P), inactive normal tabs (I), and active normal tabs (A) is as follows. The
        //          deleted index is 7, indicating normal active tab A3 was previously removed.
        //          [P1, P2, A1, I1, A2, I2, P3, A3, A4, P4]
        //                                       ^ deletedIndex is 7
        //
        //          We can map this deletedIndex to an index into a filtered subarray containing only normal active tabs.
        //          To do this, we count the number of normal active tabs in the `tabs` array in the range 0..<deletedIndex.
        //          In this case, there are two: A1 and A2.
        //
        //          [A1, A2, _, A4]
        //                   ^ deletedIndex mapped to subarray of normal active tabs is 2
        //
        let arraySlice = tabs[0..<deletedIndex]

        // Get the count of similar tabs on left side of the array
        let mappedDeletedIndex = arraySlice.filter({ removedTab.isSameTypeAs($0) }).count
        let filteredTabs = tabs.filter({ removedTab.isSameTypeAs($0) })

        // Now that we know at which index in the subarray the removedTab was removed, we can look for its nearest left or
        // right neighbours of the same type. This code checks the right tab first, then the left tab.
        // Note: Use safe index into arrays to protect against out of bounds errors (e.g. deletedIndex is 0).
        return filteredTabs[safe: mappedDeletedIndex] ?? filteredTabs[safe: mappedDeletedIndex - 1]
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

    // MARK: - SessionCreator
    @MainActor
    func createPopupSession(configuration: WKWebViewConfiguration, parent: WKWebView) -> WKWebView? {
        guard let parentTab = self[parent] else { return nil }
        return addPopupForParentTab(profile: profile, parentTab: parentTab, configuration: configuration).webView
    }
}

// MARK: - Notifiable
extension TabManagerImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        Task { @MainActor in
            switch notification.name {
            case UIApplication.willResignActiveNotification:
                saveAllTabData()
            case .TabMimeTypeDidSet:
                guard windowUUID == notification.windowUUID else { return }
                updateMenuItemsForSelectedTab()
            case .BlockPopup:
                blockPopUpDidChange()
            case .AutoPlayChanged:
                autoPlayDidChange()
            default:
                break
            }
        }
    }
}

// MARK: - WindowSimpleTabsProvider
extension TabManagerImplementation: WindowSimpleTabsProvider {
    func windowSimpleTabs() -> [TabUUID: SimpleTab] {
        // FIXME possibly also related FXIOS-10059 TabManagerImplementation's preserveTabs is called with a nil selectedTab
        let windowData = WindowData(id: windowUUID,
                                    activeTabId: self.selectedTabUUID ?? UUID(),
                                    tabData: self.generateTabDataForSaving())
        return SimpleTab.convertToSimpleTabs(windowData.tabData)
    }
}
