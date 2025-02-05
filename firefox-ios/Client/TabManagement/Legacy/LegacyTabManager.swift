// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Storage
import Shared

// MARK: - TabManagerDelegate
protocol TabManagerDelegate: AnyObject {
    // Must be called on the main thread
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selectedTab: Tab, previousTab: Tab?, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool)

    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?)
    func tabManagerUpdateCount()
}

extension TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selectedTab: Tab, previousTab: Tab?, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) {}
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {}

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {}
    func tabManagerDidAddTabs(_ tabManager: TabManager) {}
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {}
    func tabManagerUpdateCount() {}
}

// MARK: - WeakTabManagerDelegate
// We can't use a WeakList here because this is a protocol.
class WeakTabManagerDelegate: CustomDebugStringConvertible {
    weak var value: TabManagerDelegate?

    init(value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }

    var debugDescription: String {
        let className = String(describing: type(of: self))
        let memAddr = Unmanaged.passUnretained(self).toOpaque()
        let valueStr = (value == nil ? "<nil>" : "\(value!)")
        return "<\(className): \(memAddr)> Value: \(valueStr)"
    }
}

enum SwitchPrivacyModeResult {
    case createdNewTab
    case usedExistingTab
}

struct BackupCloseTab {
    var tab: Tab
    var restorePosition: Int?
    var isSelected: Bool
}

// TabManager must extend NSObjectProtocol in order to implement WKNavigationDelegate
class LegacyTabManager: NSObject, FeatureFlaggable, TabManager, TabEventHandler {
    // MARK: - Variables
    let profile: Profile
    let windowUUID: WindowUUID
    var tabEventWindowResponseType: TabEventHandlerWindowResponseType { return .singleWindow(windowUUID) }
    var isRestoringTabs = false
    var tabRestoreHasFinished = false
    var tabs = [Tab]()
    var _selectedIndex = -1
    var selectedIndex: Int { return _selectedIndex }
    let logger: Logger
    var backupCloseTab: BackupCloseTab?
    var backupCloseTabs = [Tab]()

    let delaySelectingNewPopupTab: TimeInterval = 0.1

    var normalTabs: [Tab] {
        return tabs.filter { !$0.isPrivate }
    }

    var normalActiveTabs: [Tab] {
        if isInactiveTabsEnabled {
            return normalTabs.filter({ $0.isActive })
        } else {
            return normalTabs
        }
    }

    var inactiveTabs: [Tab] {
        return normalTabs.filter({ $0.isInactive })
    }

    var privateTabs: [Tab] {
        return tabs.filter { $0.isPrivate }
    }

    var isInactiveTabsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildAndUser)
    }

    /// This variable returns all normal tabs, sorted chronologically, excluding any home page tabs.
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

    var count: Int {
        return tabs.count
    }

    var selectedTab: Tab? {
        if !(0..<count ~= _selectedIndex) {
            return nil
        }
        return tabs[_selectedIndex]
    }

    var selectedTabUUID: UUID? {
        guard let selectedTab = self.selectedTab,
              let uuid = UUID(uuidString: selectedTab.tabUUID) else {
            return nil
        }

        return uuid
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

    // MARK: - Initializer

    init(profile: Profile,
         uuid: WindowUUID,
         logger: Logger = DefaultLogger.shared
    ) {
        self.windowUUID = uuid
        self.profile = profile
        self.navDelegate = TabManagerNavDelegate()
        self.logger = logger

        super.init()

        GlobalTabEventHandlers.configure(with: profile)
        register(self, forTabEvents: .didSetScreenshot)

        addNavigationDelegate(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(blockPopUpDidChange),
                                               name: .BlockPopup,
                                               object: nil)
    }

    // MARK: - Delegates
    var delegates = [WeakTabManagerDelegate]()
    private let navDelegate: TabManagerNavDelegate

    func addDelegate(_ delegate: TabManagerDelegate) {
        self.delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func addNavigationDelegate(_ delegate: WKNavigationDelegate) {
        self.navDelegate.insert(delegate)
    }

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)? = nil) {
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

    // MARK: - Webview configuration
    // A WKWebViewConfiguration used for normal tabs
    lazy var configuration: WKWebViewConfiguration = {
        return LegacyTabManager.makeWebViewConfig(isPrivate: false, prefs: profile.prefs)
    }()

    // A WKWebViewConfiguration used for private mode tabs
    lazy var privateConfiguration: WKWebViewConfiguration = {
        return LegacyTabManager.makeWebViewConfig(isPrivate: true, prefs: profile.prefs)
    }()

    public static func makeWebViewConfig(isPrivate: Bool, prefs: Prefs?) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        let blockPopups = prefs?.boolForKey(PrefsKeys.KeyBlockPopups) ?? true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !blockPopups
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        if isPrivate {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        } else {
            configuration.websiteDataStore = WKWebsiteDataStore.default()
        }

        configuration.setURLSchemeHandler(InternalSchemeHandler(), forURLScheme: InternalURL.scheme)
        return configuration
    }

    // MARK: Get tabs
    func getTabFor(_ url: URL) -> Tab? {
        for tab in tabs {
            if let webViewUrl = tab.webView?.url,
               url.isEqual(webViewUrl) {
                return tab
            }
        }

        return nil
    }

    func getTabForURL(_ url: URL) -> Tab? {
        return tabs.first(where: { $0.webView?.url == url })
    }

    func getTabForUUID(uuid: TabUUID) -> Tab? {
        let filterdTabs = tabs.filter { tab -> Bool in
            tab.tabUUID == uuid
        }
        return filterdTabs.first
    }

    // TODO: FXIOS-7596 Remove when moving the TabManager protocol to TabManagerImplementation
    func restoreTabs(_ forced: Bool = false) { fatalError("should never be called") }

    // MARK: - Select tab

    // TODO: FXIOS-7596 Remove when moving the TabManager protocol to TabManagerImplementation
    func selectTab(_ tab: Tab?, previous: Tab? = nil) { fatalError("should never be called") }

    func getMostRecentHomepageTab() -> Tab? {
        let tabsToFilter = selectedTab?.isPrivate ?? false ? privateTabs : normalTabs
        let homePageTabs = tabsToFilter.filter { $0.isFxHomeTab }

        return mostRecentTab(inTabs: homePageTabs)
    }

    // MARK: - Clear and store
    // TODO: FXIOS-7596 Remove when moving the TabManager protocol to TabManagerImplementation
    func preserveTabs() { fatalError("should never be called") }

    func shouldClearPrivateTabs() -> Bool {
        // FXIOS-9519: By default if no bool value is set we close the private tabs and mark it true
        return profile.prefs.boolForKey(PrefsKeys.Settings.closePrivateTabs) ?? true
    }

    func cleanupClosedTabs(_ closedTabs: [Tab], previous: Tab?, isPrivate: Bool = false) {
        DispatchQueue.main.async { [unowned self] in
            // select normal tab if there are no private tabs, we need to do this
            // to accommodate for the case when a user dismisses tab tray while
            // they are in private mode and there are no tabs
            if isPrivate && self.privateTabs.count < 1 && !self.normalTabs.isEmpty {
                self.selectTab(mostRecentTab(inTabs: self.normalTabs) ?? self.normalTabs.last,
                               previous: previous)
            }
        }

        // perform remaining tab cleanup related to removing wkwebview
        // observers which can only happen on main thread in close() call
        closedTabs.forEach { tab in
            DispatchQueue.main.async {
                tab.close()
                TabEvent.post(.didClose, for: tab)
            }
        }
    }

    // TODO: FXIOS-7596 Remove when moving the TabManager protocol to TabManagerImplementation
    func storeChanges() { fatalError("should never be called") }
    func saveSessionData(forTab tab: Tab?) { fatalError("should never be called") }

    private func addTabForRestoration(isPrivate: Bool) -> Tab {
        return addTab(flushToDisk: false, zombie: true, isPrivate: isPrivate)
    }

    private func checkForSingleTab() {
        // Always make sure there is a single normal tab.
        if normalTabs.isEmpty {
            let tab = addTab()
            if selectedTab == nil { selectTab(tab) }
        }
    }

    /// When all history gets deleted, we use this special way to handle Tab History deletion. To make it appear like
    /// the currently open tab also has its history deleted, we close the tab and reload that URL in a new tab.
    /// We handle it this way because, as far as I can tell, clearing history REQUIRES we nil the webView.
    /// The backForwardList is not directly mutable. When niling out the webView, we should properly close
    /// it since it affects KVO.
    func clearAllTabsHistory() {
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
        removeTab(selectedTab)
    }

    // MARK: - Add tabs
    func addTab(_ request: URLRequest?, afterTab: Tab?, isPrivate: Bool) -> Tab {
        return addTab(request,
                      afterTab: afterTab,
                      flushToDisk: true,
                      zombie: false,
                      isPrivate: isPrivate)
    }

    @discardableResult
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

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool) {
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
        storeChanges()
    }

    func addTab(_ request: URLRequest? = nil,
                afterTab: Tab? = nil,
                flushToDisk: Bool,
                zombie: Bool,
                isPrivate: Bool = false
    ) -> Tab {
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: windowUUID)
        configureTab(tab, request: request, afterTab: afterTab, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab {
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
    func configureTab(_ tab: Tab,
                      request: URLRequest?,
                      afterTab parent: Tab? = nil,
                      flushToDisk: Bool,
                      zombie: Bool,
                      isPopup: Bool = false,
                      requiredConfiguration: WKWebViewConfiguration? = nil
    ) {
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
                configuration = tab.isPrivate ? self.privateConfiguration : self.configuration
            }
            tab.createWebview(configuration: configuration)
        }
        tab.navigationDelegate = self.navDelegate

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
            storeChanges()
        }
    }

    // MARK: - Move tabs
    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {
        let currentTabs = privateMode ? privateTabs : normalActiveTabs

        guard visibleFromIndex < currentTabs.count, visibleToIndex < currentTabs.count else { return }

        let fromIndex = tabs.firstIndex(of: currentTabs[visibleFromIndex]) ?? tabs.count - 1
        let toIndex = tabs.firstIndex(of: currentTabs[visibleToIndex]) ?? tabs.count - 1

        let previouslySelectedTab = selectedTab

        tabs.insert(tabs.remove(at: fromIndex), at: toIndex)

        if let previouslySelectedTab = previouslySelectedTab,
           let previousSelectedIndex = tabs.firstIndex(of: previouslySelectedTab) {
            _selectedIndex = previousSelectedIndex
        }

        storeChanges()
    }

    // MARK: - Privacy change
    func switchPrivacyMode() -> SwitchPrivacyModeResult {
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

    // Called by other classes to signal that they are entering/exiting private mode
    // This is called by TabTrayVC when the private mode button is pressed and BEFORE we've switched to the new mode
    // we only want to remove all private tabs when leaving PBM and not when entering.
    func willSwitchTabMode(leavingPBM: Bool) {
        // Clear every time entering/exiting this mode.
        Tab.ChangeUserAgent.privateModeHostList = Set<String>()
    }

    // MARK: - Remove tabs
    func removeTab(_ tab: Tab, completion: (() -> Void)? = nil) {
        guard let index = tabs.firstIndex(where: { $0 === tab }) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.removeTab(tab, flushToDisk: true)
            self?.updateSelectedTabAfterRemovalOf(tab, deletedIndex: index)
            completion?()
        }

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .tab,
            value: tab.isPrivate ? .privateTab : .normalTab
        )
    }

    @MainActor
    func removeTab(_ tabUUID: TabUUID) async {
        guard let index = tabs.firstIndex(where: { $0.tabUUID == tabUUID }) else { return }

        let tab = tabs[index]
        backupCloseTab = BackupCloseTab(
            tab: tab,
            restorePosition: index,
            isSelected: selectedTab?.tabUUID == tab.tabUUID)

        self.removeTab(tab, flushToDisk: true)
        self.updateSelectedTabAfterRemovalOf(tab, deletedIndex: index)

        TelemetryWrapper.recordEvent(
            category: .action,
            method: .close,
            object: .tab,
            value: tab.isPrivate ? .privateTab : .normalTab
        )
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

        if tab.isPrivate && privateTabs.count < 1 {
            privateConfiguration = LegacyTabManager.makeWebViewConfig(isPrivate: true, prefs: profile.prefs)
        }

        tab.close()

        // Notify of tab removal
        ensureMainThread { [unowned self] in
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab, isRestoring: !tabRestoreHasFinished) }
            TabEvent.post(.didClose, for: tab)
        }

        if flushToDisk {
            storeChanges()
        }
    }

    func removeTabs(_ tabs: [Tab]) {
        for tab in tabs {
            self.removeTab(tab, flushToDisk: false)
        }
        storeChanges()
    }

    @MainActor
    func removeTabs(by urls: [URL]) async {
        let urls = Set(urls)
        let tabsToRemove = normalTabs.filter { tab in
            guard let url = tab.url else { return false }
            return urls.contains(url)
        }
        for tab in tabsToRemove {
            await withCheckedContinuation { continuation in
                removeTab(tab) { continuation.resume() }
            }
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

        storeChanges()
    }

    func undoCloseAllTabs() {
        guard !backupCloseTabs.isEmpty else { return }
        tabs = backupCloseTabs
        storeChanges()
        backupCloseTabs = [Tab]()
        if backupCloseTab != nil {
            selectTab(backupCloseTab?.tab)
            backupCloseTab = nil
        }
    }

    @MainActor
    func removeAllInactiveTabs() async { fatalError("should never be called") }

    func getInactiveTabs() -> [Tab] {
        return inactiveTabs
    }

    @MainActor
    func undoCloseInactiveTabs() async { fatalError("should never be called") }

    func backgroundRemoveAllTabs(isPrivate: Bool = false,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: TabUUID) -> Void) {
        let previousSelectedTabUUID = selectedTab?.tabUUID ?? ""
        // moved closing of multiple tabs to background thread
        DispatchQueue.global().async { [unowned self] in
            let tabsToRemove = isPrivate ? self.privateTabs : self.normalTabs

            if isPrivate && self.privateTabs.count < 1 {
                // Bugzilla 1646756: close last private tab clears the WKWebViewConfiguration (#6827)
                DispatchQueue.main.async { [unowned self] in
                    self.privateConfiguration = LegacyTabManager.makeWebViewConfig(isPrivate: true,
                                                                                   prefs: self.profile.prefs)
                }
            }

            // clear Tabs from the list that we need to remove
            self.tabs = self.tabs.filter { !tabsToRemove.contains($0) }

            // update tab manager count
            DispatchQueue.main.async { [unowned self] in
                self.delegates.forEach { $0.get()?.tabManagerUpdateCount() }
            }

            DispatchQueue.main.async { [unowned self] in
                // after closing all normal tabs we should add a normal tab
                if self.normalTabs.isEmpty {
                    self.selectTab(self.addTab())
                    storeChanges()
                }
            }

            DispatchQueue.main.async {
                didClearTabs(tabsToRemove, isPrivate, previousSelectedTabUUID)
            }
        }
    }

    // MARK: - Login Alerts
    func expireLoginAlerts() {
        for tab in tabs {
            tab.expireLoginAlert()
        }
    }

    // MARK: - Toasts
    func makeToastFromRecentlyClosedUrls(_ recentlyClosedTabs: [Tab],
                                         isPrivate: Bool,
                                         previousTabUUID: TabUUID) {
        guard !recentlyClosedTabs.isEmpty else { return }

        // Add last 10 tab(s) to recently closed list
        // Note: The recently closed tab list is only updated when the undo
        // snackbar disappears and does not update if someone taps on undo button
        recentlyClosedTabs.suffix(10).forEach { tab in
            if let url = tab.lastKnownUrl,
               !(InternalURL(url)?.isAboutURL ?? false),
               !tab.isPrivate {
                profile.recentlyClosedTabs.addTab(url as URL,
                                                  title: tab.lastTitle,
                                                  lastExecutedTime: tab.lastExecutedTime)
            }
        }

        // Toast
        let viewModel = ButtonToastViewModel(
            labelText: String.localizedStringWithFormat(
                .TabsTray.CloseTabsToast.Title,
                recentlyClosedTabs.count),
            buttonText: .TabsTray.CloseTabsToast.Action)
        // Passing nil theme because themeManager is not available,
        // calling to applyTheme with proper theme before showing
        let toast = ButtonToast(viewModel: viewModel,
                                theme: nil,
                                completion: { buttonPressed in
            // Handles undo to Close tabs
            if buttonPressed {
                self.undoCloseAllTabsLegacy(recentlyClosedTabs: recentlyClosedTabs, previousTabUUID: previousTabUUID)
            } else {
                // Finish clean up for recently close tabs
                DispatchQueue.global().async { [unowned self] in
                    let previousTab = tabs.first(where: { $0.tabUUID == previousTabUUID })

                    self.cleanupClosedTabs(recentlyClosedTabs,
                                           previous: previousTab,
                                           isPrivate: isPrivate)
                }
            }
        })
        delegates.forEach { $0.get()?.tabManagerDidRemoveAllTabs(self, toast: toast) }
    }

    /// Restore recently closed tabs when tab tray refactor is disabled
    func undoCloseAllTabsLegacy(recentlyClosedTabs: [Tab], previousTabUUID: TabUUID, isPrivate: Bool = false) {
        self.reAddTabs(
            tabsToAdd: recentlyClosedTabs,
            previousTabUUID: previousTabUUID,
            isPrivate: isPrivate
        )
        NotificationCenter.default.post(name: .DidTapUndoCloseAllTabToast,
                                        object: nil,
                                        userInfo: windowUUID.userInfo)
    }

    func tabDidSetScreenshot(_ tab: Tab, hasHomeScreenshot: Bool) {}

    // MARK: - Private
    @objc
    private func blockPopUpDidChange() {
        let allowPopups = !(profile.prefs.boolForKey(PrefsKeys.KeyBlockPopups) ?? true)
        // Each tab may have its own configuration, so we should tell each of them in turn.
        for tab in tabs {
            tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
        // The default tab configurations also need to change.
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        privateConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
    }

    /// After a tab is removed from the `tabs` array, it is necessary to select the previously selected tab. This method
    /// will select the previously selected tab or, if that tab was deleted, select the next best alternative or create a
    /// new normal active tab.
    ///
    /// We have to handle 3 different types of tabs: private tabs, normal active tabs, and normal inactive tabs.
    /// These tabs are all in the `tabs` array but are differentiated by their respective flags.
    ///
    /// Once a tab has been removed, we must consider several situations:
    /// - A change in the `tabs` array size, which may require us to shift the selected tab index 1 to the left
    /// - If the removed tab was selected, we must choose an appropriate next selected tab from among the existing tabs
    /// - When we close the last tab of a certain type, we may need to perform additional logic
    ///      - For example, closing the last private tab should select the most recent active normal tab, if possible
    ///
    /// - Parameters:
    ///   - removedTab: The tab that has already been removed from the `tabs` array.
    ///   - deletedIndex: The index at which `removedTab` has been removed from the `tabs` array.
    private func updateSelectedTabAfterRemovalOf(_ removedTab: Tab, deletedIndex: Int) {
        // If the currently selected tab has been deleted, try to select the next most reasonable tab.
        if deletedIndex == _selectedIndex {
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
        } else if deletedIndex < _selectedIndex {
            // If we delete a tab in the `tabs` array that's ahead of the selected tab, we need to shift our index.
            // The selected tab itself hasn't actually changed; reselect it to call code paths related to saving, etc.
            if let selectedTab = tabs[safe: _selectedIndex - 1] {
                selectTab(selectedTab, previous: selectedTab)
            } else {
                assertionFailure("This should not happen, we should always be able to get the selected tab again.")
                selectTab(addTab())
            }
        }
    }

    /// Returns a direct neighbouring tab of the same type as the removed tab.
    /// - Parameters:
    ///   - removedTab: A tab that was just removed from the `tabs` array.
    ///   - deletedIndex: The former index of the removed tab in the `tabs` array.
    /// - Returns: Returns the neighbouring tab of the same type as removedTab. Preference given to the tab on the right.
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

    private func reAddTabs(tabsToAdd: [Tab], previousTabUUID: TabUUID, isPrivate: Bool = false) {
        tabs.append(contentsOf: tabsToAdd)
        let tabToSelect = tabs.first(where: { $0.tabUUID == previousTabUUID })
        let currentlySelectedTab = selectedTab
        if let tabToSelect = tabToSelect, let currentlySelectedTab = currentlySelectedTab {
            // remove tab only in normal mode because we don't create a new tab after users closes all tabs in private mode
            if !isPrivate {
                removeTabs([currentlySelectedTab])
            }
            // select previous tab
            selectTab(tabToSelect, previous: nil)
        }
        delegates.forEach { $0.get()?.tabManagerUpdateCount() }
        storeChanges()
    }

    func undoCloseTab() {
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
        storeChanges()
    }

    // MARK: - Start at Home

    /// Public interface for checking whether the StartAtHome Feature should run.
    func startAtHomeCheck() -> Bool {
        let startAtHomeManager = StartAtHomeHelper(prefs: profile.prefs, isRestoringTabs: !tabRestoreHasFinished)

        guard !startAtHomeManager.shouldSkipStartHome else {
            logger.log("Skipping start at home", level: .debug, category: .tabs)
            return false
        }

        if startAtHomeManager.shouldStartAtHome() {
            let wasLastSessionPrivate = selectedTab?.isPrivate ?? false
            let scannableTabs = wasLastSessionPrivate ? privateTabs : normalTabs
            let existingHomeTab = startAtHomeManager.scanForExistingHomeTab(in: scannableTabs,
                                                                            with: profile.prefs)
            let tabToSelect = createStartAtHomeTab(withExistingTab: existingHomeTab,
                                                   inPrivateMode: wasLastSessionPrivate,
                                                   and: profile.prefs)

            logger.log("Start at home triggered with last session private \(wasLastSessionPrivate)",
                       level: .debug,
                       category: .tabs)
            selectTab(tabToSelect)
            return true
        }
        return false
    }

    /// Provides a tab on which to open if the start at home feature is enabled. This tab
    /// can be an existing one, or, if no suitable candidate exists, a new one.
    ///
    /// - Parameters:
    ///   - existingTab: A `Tab` that is the user's homepage, that is already open
    ///   - privateMode: Whether the last session was private or not, so that, if there's
    ///   no homepage open, we open a new tab in the correct state.
    ///   - profilePreferences: Preferences, stored in the user's `Profile`
    /// - Returns: A selectable tab
    private func createStartAtHomeTab(withExistingTab existingTab: Tab?,
                                      inPrivateMode privateMode: Bool,
                                      and profilePreferences: Prefs
    ) -> Tab? {
        let page = NewTabAccessors.getHomePage(profilePreferences)
        let customUrl = HomeButtonHomePageAccessors.getHomePage(profilePreferences)
        let homeUrl = URL(string: "internal://local/about/home")

        if page == .homePage, let customUrl = customUrl {
            return existingTab ?? addTab(URLRequest(url: customUrl), isPrivate: privateMode)
        } else if page == .topSites, let homeUrl = homeUrl {
            let home = existingTab ?? addTab(isPrivate: privateMode)
            home.loadRequest(PrivilegedRequest(url: homeUrl) as URLRequest)
            home.url = homeUrl
            return home
        }

        return selectedTab ?? addTab()
    }
}

// MARK: - WKNavigationDelegate
extension LegacyTabManager: WKNavigationDelegate {
    // Note the main frame JSContext (i.e. document, window) is not available yet.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation?) {
        if let tab = self[webView], let blocker = tab.contentBlocker {
            blocker.clearPageStats()
        }
    }

    // The main frame JSContext is available, and DOM parsing has begun.
    // Do not execute JS at this point that requires running prior to DOM parsing.
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        guard let tab = self[webView] else { return }

        if let tpHelper = tab.contentBlocker, !tpHelper.isEnabled {
            webView.evaluateJavascriptInDefaultContentWorld("window.__firefox__.TrackingProtectionStats.setEnabled(false, \(UserScriptManager.appIdToken))")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        // tab restore uses internal pages, so don't call storeChanges unnecessarily on startup
        if let url = webView.url {
            if InternalURL(url) != nil {
                return
            }

            if let title = webView.title, selectedTab?.webView == webView {
                selectedTab?.lastTitle = title
            }

            storeChanges()
        }
    }

    /// Called when the WKWebView's content process has gone away. If this happens for the currently selected tab
    /// then we immediately reload it.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let tab = selectedTab, tab.webView == webView {
            tab.consecutiveCrashes += 1

            // Only automatically attempt to reload the crashed
            // tab three times before giving up.
            if tab.consecutiveCrashes < 3 {
                webView.reload()
            } else {
                tab.consecutiveCrashes = 0
            }
        }
    }
}
