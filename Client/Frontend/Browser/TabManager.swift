/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

protocol TabManagerDelegate: AnyObject {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool)
    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool)

    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?)
}

// We can't use a WeakList here because this is a protocol.
class WeakTabManagerDelegate {
    weak var value: TabManagerDelegate?

    init (value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }
}

// TabManager must extend NSObjectProtocol in order to implement WKNavigationDelegate
class TabManager: NSObject {
    fileprivate var delegates = [WeakTabManagerDelegate]()
    fileprivate let tabEventHandlers: [TabEventHandler]
    fileprivate let store: TabManagerStore
    fileprivate let profile: Profile
    
    func addDelegate(_ delegate: TabManagerDelegate) {
        assert(Thread.isMainThread)
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func removeDelegate(_ delegate: TabManagerDelegate) {
        assert(Thread.isMainThread)
        for i in 0 ..< delegates.count {
            let del = delegates[i]
            if delegate === del.get() || del.get() == nil {
                delegates.remove(at: i)
                return
            }
        }
    }

    fileprivate(set) var tabs = [Tab]()
    fileprivate var _selectedIndex = -1
    fileprivate let navDelegate: TabManagerNavDelegate

    // A WKWebViewConfiguration used for normal tabs
    lazy fileprivate var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(profile.prefs.boolForKey("blockPopups") ?? true)
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        return configuration
    }()

    // A WKWebViewConfiguration used for private mode tabs
    lazy fileprivate var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(profile.prefs.boolForKey("blockPopups") ?? true)
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        return configuration
    }()

    var selectedIndex: Int { return _selectedIndex }

    // Enables undo of recently closed tabs
    var recentlyClosedForUndo = [SavedTab]()

    var normalTabs: [Tab] {
        assert(Thread.isMainThread)

        return tabs.filter { !$0.isPrivate }
    }

    var privateTabs: [Tab] {
        assert(Thread.isMainThread)
        return tabs.filter { $0.isPrivate }
    }

    init(profile: Profile, imageStore: DiskImageStore?) {
        assert(Thread.isMainThread)

        self.profile = profile
        self.navDelegate = TabManagerNavDelegate()
        self.tabEventHandlers = TabEventHandlers.create(with: profile.prefs)

        self.store = TabManagerStore(imageStore: imageStore)
        super.init()

        addNavigationDelegate(self)

        NotificationCenter.default.addObserver(self, selector: #selector(prefsDidChange), name: UserDefaults.didChangeNotification, object: nil)
    }

    func addNavigationDelegate(_ delegate: WKNavigationDelegate) {
        assert(Thread.isMainThread)

        self.navDelegate.insert(delegate)
    }

    var count: Int {
        assert(Thread.isMainThread)

        return tabs.count
    }

    var selectedTab: Tab? {
        assert(Thread.isMainThread)
        if !(0..<count ~= _selectedIndex) {
            return nil
        }

        return tabs[_selectedIndex]
    }

    subscript(index: Int) -> Tab? {
        assert(Thread.isMainThread)

        if index >= tabs.count {
            return nil
        }
        return tabs[index]
    }

    subscript(webView: WKWebView) -> Tab? {
        assert(Thread.isMainThread)

        for tab in tabs where tab.webView === webView {
            return tab
        }

        return nil
    }

    func getTabFor(_ url: URL) -> Tab? {
        assert(Thread.isMainThread)

        for tab in tabs {
            if tab.webView?.url == url {
                return tab
            }

            // Also look for tabs that haven't been restored yet.
            if let sessionData = tab.sessionData,
                0..<sessionData.urls.count ~= sessionData.currentPage,
                sessionData.urls[sessionData.currentPage] == url {
                return tab
            }
        }

        return nil
    }

    func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        assert(Thread.isMainThread)
        let previous = previous ?? selectedTab

        if previous === tab {
            return
        }

        // Make sure to wipe the private tabs if the user has the pref turned on
        if shouldClearPrivateTabs(), !(tab?.isPrivate ?? false) {
            removeAllPrivateTabs()
        }

        if let tab = tab {
            _selectedIndex = tabs.index(of: tab) ?? -1
        } else {
            _selectedIndex = -1
        }

        store.preserveTabs(tabs, selectedTab: selectedTab)

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()
        selectedTab?.lastExecutedTime = Date.now()

        delegates.forEach { $0.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous, isRestoring: store.isRestoringTabs) }
        if let tab = previous {
            TabEvent.post(.didLoseFocus, for: tab)
        }
        if let tab = selectedTab {
            TabEvent.post(.didGainFocus, for: tab)
            UITextField.appearance().keyboardAppearance = tab.isPrivate ? .dark : .light
        }
    }

    func shouldClearPrivateTabs() -> Bool {
        return profile.prefs.boolForKey("settings.closePrivateTabs") ?? false
    }

    //Called by other classes to signal that they are entering/exiting private mode
    //This is called by TabTrayVC when the private mode button is pressed and BEFORE we've switched to the new mode
    //we only want to remove all private tabs when leaving PBM and not when entering.
    func willSwitchTabMode(leavingPBM: Bool) {
        recentlyClosedForUndo.removeAll()

        if shouldClearPrivateTabs() && leavingPBM {
            removeAllPrivateTabs()
        }
    }

    func expireSnackbars() {
        assert(Thread.isMainThread)

        for tab in tabs {
            tab.expireSnackbars()
        }
    }

    func addPopupForParentTab(_ parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab {
        let popup = Tab(configuration: configuration, isPrivate: parentTab.isPrivate)
        configureTab(popup, request: nil, afterTab: parentTab, flushToDisk: true, zombie: false, isPopup: true)

        // Wait momentarily before selecting the new tab, otherwise the parent tab
        // may be unable to set `window.location` on the popup immediately after
        // calling `window.open("")`.
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.selectTab(popup)
        }

        return popup
    }

    @discardableResult func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil, isPrivate: Bool = false) -> Tab {
        return self.addTab(request, configuration: configuration, afterTab: afterTab, flushToDisk: true, zombie: false, isPrivate: isPrivate)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool) {
        assert(Thread.isMainThread)

        if urls.isEmpty {
            return
        }

        var tab: Tab!
        for url in urls {
            tab = self.addTab(URLRequest(url: url), flushToDisk: false, zombie: zombie)
        }

        // Select the most recent.
        selectTab(tab)
        // Okay now notify that we bulk-loaded so we can adjust counts and animate changes.
        delegates.forEach { $0.get()?.tabManagerDidAddTabs(self) }

        // Flush.
        storeChanges()
    }

    func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, afterTab: Tab? = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool = false) -> Tab {
        assert(Thread.isMainThread)

        // Take the given configuration. Or if it was nil, take our default configuration for the current browsing mode.
        let configuration: WKWebViewConfiguration = configuration ?? (isPrivate ? privateConfiguration : self.configuration)

        let tab = Tab(configuration: configuration, isPrivate: isPrivate)
        configureTab(tab, request: request, afterTab: afterTab, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    func moveTab(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {
        assert(Thread.isMainThread)

        let currentTabs = privateMode ? privateTabs : normalTabs

        guard visibleFromIndex < currentTabs.count, visibleToIndex < currentTabs.count else {
            return
        }

        let fromIndex = tabs.index(of: currentTabs[visibleFromIndex]) ?? tabs.count - 1
        let toIndex = tabs.index(of: currentTabs[visibleToIndex]) ?? tabs.count - 1

        let previouslySelectedTab = selectedTab

        tabs.insert(tabs.remove(at: fromIndex), at: toIndex)

        if let previouslySelectedTab = previouslySelectedTab, let previousSelectedIndex = tabs.index(of: previouslySelectedTab) {
            _selectedIndex = previousSelectedIndex
        }

        storeChanges()
    }

    func configureTab(_ tab: Tab, request: URLRequest?, afterTab parent: Tab? = nil, flushToDisk: Bool, zombie: Bool, isPopup: Bool = false) {
        assert(Thread.isMainThread)

        delegates.forEach { $0.get()?.tabManager(self, willAddTab: tab) }

        if parent == nil || parent?.isPrivate != tab.isPrivate {
            tabs.append(tab)
        } else if let parent = parent, var insertIndex = tabs.index(of: parent) {
            insertIndex += 1
            while insertIndex < tabs.count && tabs[insertIndex].isDescendentOf(parent) {
                insertIndex += 1
            }
            tab.parent = parent
            tabs.insert(tab, at: insertIndex)
        }

        delegates.forEach { $0.get()?.tabManager(self, didAddTab: tab, isRestoring: store.isRestoringTabs) }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate

        if let request = request {
            tab.loadRequest(request)
        } else if !isPopup {
            let newTabChoice = NewTabAccessors.getNewTabPage(profile.prefs)
            switch newTabChoice {
            case .homePage:
                // We definitely have a homepage if we've got here
                // (so we can safely dereference it).
                let url = HomePageAccessors.getHomePage(profile.prefs)!
                tab.loadRequest(URLRequest(url: url))
            case .blankPage:
                // Do nothing: we're already seeing a blank page.
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
        if flushToDisk {
        	storeChanges()
        }
    }

    func removeTabAndUpdateSelectedIndex(_ tab: Tab) {
        removeTab(tab, flushToDisk: true, notify: true)
        updateIndexAfterRemovalOf(tab)
        hideNetworkActivitySpinner()
    }

    func updateIndexAfterRemovalOf(_ tab: Tab) {
        let closedLastNormalTab = !tab.isPrivate && normalTabs.isEmpty
        let closedLastPrivateTab = tab.isPrivate && privateTabs.isEmpty

        if closedLastNormalTab {
            selectTab(addTab(), previous: tab)
        } else if closedLastPrivateTab {
            selectTab(tabs.last, previous: tab)
        } else if !isSelectedParentTab(afterRemoving: tab) {
            let viableTabs: [Tab] = tab.isPrivate ? privateTabs : normalTabs
            if let tabOnTheRight = viableTabs[safe: _selectedIndex] {
                selectTab(tabOnTheRight, previous: tab)
            } else if let tabOnTheLeft = viableTabs[safe: _selectedIndex-1] {
                selectTab(tabOnTheLeft, previous: tab)
            } else {
                selectTab(viableTabs.last, previous: tab)
            }
        }
    }

    /// - Parameter notify: if set to true, will call the delegate after the tab
    ///   is removed.
    fileprivate func removeTab(_ tab: Tab, flushToDisk: Bool, notify: Bool) {
        assert(Thread.isMainThread)

        guard let removalIndex = tabs.index(where: { $0 === tab }) else {
            Sentry.shared.sendWithStacktrace(message: "Could not find index of tab to remove", tag: .tabManager, severity: .fatal, description: "Tab count: \(count)")
            return
        }

        if notify {
            delegates.forEach { $0.get()?.tabManager(self, willRemoveTab: tab) }
        }

        let prevCount = count
        tabs.remove(at: removalIndex)
        assert(count == prevCount - 1, "Make sure the tab count was actually removed")

        tab.closeAndRemovePrivateBrowsingData()

        if notify {
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab, isRestoring: store.isRestoringTabs) }
            TabEvent.post(.didClose, for: tab)
        }

        if flushToDisk {
            storeChanges()
        }
    }

    func isSelectedParentTab(afterRemoving tab: Tab) -> Bool {
        let viableTabs: [Tab] = tab.isPrivate ? privateTabs : normalTabs

        if let parentTab = tab.parent,
            let newTab = viableTabs.reduce(viableTabs.first, { currentBestTab, tab2 in
                if let tab1 = currentBestTab, let time1 = tab1.lastExecutedTime {
                    if let time2 = tab2.lastExecutedTime {
                        return time1 <= time2 ? tab2 : tab1
                    }
                    return tab1
                } else {
                    return tab2
                }
            }), parentTab == newTab, tab !== newTab, newTab.lastExecutedTime != nil {
            // We select the most recently visited tab, only if it is also the parent tab of the closed tab.
            _selectedIndex = tabs.index(of: newTab) ?? -1
            return true
        }
        return false
    }

    private func removeAllPrivateTabs() {
        // reset the selectedTabIndex if we are on a private tab because we will be removing it.
        if selectedTab?.isPrivate ?? false {
            _selectedIndex = -1
        }

        tabs.filter { $0.isPrivate }.forEach { tab in
                tab.closeAndRemovePrivateBrowsingData()
        }

        tabs = tabs.filter { !$0.isPrivate }
    }

    func removeTabsWithUndoToast(_ tabs: [Tab]) {
        recentlyClosedForUndo = normalTabs.compactMap { tab in
            return SavedTab(tab: tab, isSelected: false)
        }

        var tabsCopy = tabs

        // Remove the current tab last to prevent switching tabs while removing tabs
        if let selectedTab = selectedTab {
            if let selectedIndex = tabsCopy.index(of: selectedTab) {
                let removed = tabsCopy.remove(at: selectedIndex)
                removeTabs(tabsCopy)
                removeTabAndUpdateSelectedIndex(removed)
            } else {
                removeTabs(tabsCopy)
            }
        }
        for tab in tabs {
            tab.hideContent()
        }
        var toast: ButtonToast?
        let numberOfTabs = recentlyClosedForUndo.count
        if numberOfTabs > 0 {
            toast = ButtonToast(labelText: String.localizedStringWithFormat(Strings.TabsDeleteAllUndoTitle, numberOfTabs), buttonText: Strings.TabsDeleteAllUndoAction, completion: { buttonPressed in
                if buttonPressed {
                    self.undoCloseTabs()
                    self.storeChanges()
                    for delegate in self.delegates {
                        delegate.get()?.tabManagerDidAddTabs(self)
                    }
                }
                self.eraseUndoCache()
            })
        }

        delegates.forEach { $0.get()?.tabManagerDidRemoveAllTabs(self, toast: toast) }
    }

    func undoCloseTabs() {
        guard recentlyClosedForUndo.count > 0 else {
            return
        }

        _ = store.restoreTabs(savedTabs: recentlyClosedForUndo, clearPrivateTabs: false, tabManager: self)

        recentlyClosedForUndo.removeAll()

        tabs.forEach { tab in
            tab.showContent(true)
        }

        // In non-private mode, delete all tabs will automatically create a tab
        if let tab = tabs.first, !tab.isPrivate {
            removeTabAndUpdateSelectedIndex(tab)
        }

        delegates.forEach { $0.get()?.tabManagerDidRestoreTabs(self) }
    }

    func eraseUndoCache() {
        recentlyClosedForUndo.removeAll()
    }

    func removeTabs(_ tabs: [Tab]) {
        for tab in tabs {
            self.removeTab(tab, flushToDisk: false, notify: true)
        }
        storeChanges()
    }

    func removeAll() {
        removeTabs(self.tabs)
    }

    func getTabForURL(_ url: URL) -> Tab? {
        assert(Thread.isMainThread)

        return tabs.filter { $0.webView?.url == url } .first
    }

    @objc func prefsDidChange() {
        DispatchQueue.main.async {
            let allowPopups = !(self.profile.prefs.boolForKey("blockPopups") ?? true)
            // Each tab may have its own configuration, so we should tell each of them in turn.
            for tab in self.tabs {
                tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
            }
            // The default tab configurations also need to change.
            self.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
            self.privateConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
    }

    func resetProcessPool() {
        assert(Thread.isMainThread)

        configuration.processPool = WKProcessPool()
    }
}

extension TabManager {
    fileprivate func saveTabs(toProfile profile: Profile, _ tabs: [Tab]) {
        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = tabs.compactMap( Tab.toRemoteTab )

        // Don't insert into the DB immediately. We tend to contend with more important
        // work like querying for top sites.
        let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
        queue.asyncAfter(deadline: .now() + .milliseconds(100)) {
            profile.storeTabs(storedTabs)
        }
    }

    @discardableResult func storeChanges() -> Success {
        saveTabs(toProfile: profile, normalTabs)
        return store.preserveTabs(tabs, selectedTab: selectedTab)
    }

    func hasTabsToRestoreAtStartup() -> Bool {
        return store.hasTabsToRestoreAtStartup
    }

    func restoreTabs() {
        defer {
            // Always make sure there is a single normal tab.
            if normalTabs.isEmpty {
                let tab = addTab()
                if selectedTab == nil {
                    selectTab(tab)
                }
            }
        }
        guard count == 0, !AppConstants.IsRunningTest, !DebugSettingsBundleOptions.skipSessionRestore, store.hasTabsToRestoreAtStartup else {
            return
        }

        let tabToSelect = store.restoreStartupTabs(clearPrivateTabs: shouldClearPrivateTabs(), tabManager: self)

        for delegate in self.delegates {
            delegate.get()?.tabManagerDidRestoreTabs(self)
        }

        selectTab(tabToSelect)
    }
}

extension TabManager: WKNavigationDelegate {

    // Note the main frame JSContext (i.e. document, window) is not available yet.
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true

        if #available(iOS 11, *), let tab = self[webView], let blocker = tab.contentBlocker as? ContentBlockerHelper {
            blocker.clearPageStats()
        }
    }

    // The main frame JSContext is available, and DOM parsing has begun.
    // Do not excute JS at this point that requires running prior to DOM parsing.
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let tab = self[webView] else { return }
        let isNightMode = NightModeAccessors.isNightMode(profile.prefs)
        tab.setNightMode(isNightMode)

        if #available(iOS 11, *) {
            let isNoImageMode = profile.prefs.boolForKey(PrefsKeys.KeyNoImageModeStatus) ?? false
            tab.noImageMode = isNoImageMode

            if let tpHelper = tab.contentBlocker as? ContentBlockerHelper, !tpHelper.isEnabled {
                webView.evaluateJavaScript("window.__firefox__.TrackingProtectionStats.setEnabled(false, \(UserScriptManager.securityToken))", completionHandler: nil)
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideNetworkActivitySpinner()
        // only store changes if this is not an error page
        // as we current handle tab restore as error page redirects then this ensures that we don't
        // call storeChanges unnecessarily on startup
        if let url = webView.url, !url.isErrorPageURL {
            storeChanges()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideNetworkActivitySpinner()
    }

    func hideNetworkActivitySpinner() {
        for tab in tabs {
            if let tabWebView = tab.webView {
                // If we find one tab loading, we don't hide the spinner
                if tabWebView.isLoading {
                    return
                }
            }
        }
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    /// Called when the WKWebView's content process has gone away. If this happens for the currently selected tab
    /// then we immediately reload it.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if let tab = selectedTab, tab.webView == webView {
            webView.reload()
        }
    }
}

// WKNavigationDelegates must implement NSObjectProtocol
class TabManagerNavDelegate: NSObject, WKNavigationDelegate {
    fileprivate var delegates = WeakList<WKNavigationDelegate>()

    func insert(_ delegate: WKNavigationDelegate) {
        delegates.insert(delegate)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didCommit: navigation)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        for delegate in delegates {
            delegate.webView?(webView, didFail: navigation, withError: error)
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            for delegate in delegates {
                delegate.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
            }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didFinish: navigation)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        for delegate in delegates {
            delegate.webViewWebContentProcessDidTerminate?(webView)
        }
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let authenticatingDelegates = delegates.filter { wv in
                return wv.responds(to: #selector(webView(_:didReceive:completionHandler:)))
            }

            guard let firstAuthenticatingDelegate = authenticatingDelegates.first else {
                return completionHandler(.performDefaultHandling, nil)
            }

            firstAuthenticatingDelegate.webView?(webView, didReceive: challenge) { (disposition, credential) in
                completionHandler(disposition, credential)
            }
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didStartProvisionalNavigation: navigation)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            var res = WKNavigationActionPolicy.allow
            for delegate in delegates {
                delegate.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: { policy in
                    if policy == .cancel {
                        res = policy
                    }
                })
            }

            decisionHandler(res)
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        var res = WKNavigationResponsePolicy.allow
        for delegate in delegates {
            delegate.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: { policy in
                if policy == .cancel {
                    res = policy
                }
            })
        }

        if res == .allow, let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let tab = appDelegate.browserViewController.tabManager[webView]
            tab?.mimeType = navigationResponse.response.mimeType
        }

        decisionHandler(res)
    }
}

// Helper functions for test cases
extension TabManager {
    func testTabCountOnDisk() -> Int {
        assert(AppConstants.IsRunningTest)
        return store.testTabCountOnDisk()
    }

    func testCountRestoredTabs() -> Int {
        assert(AppConstants.IsRunningTest)
        _ = store.restoreStartupTabs(clearPrivateTabs: true, tabManager: self)
        return count
    }

    func testClearArchive() {
        assert(AppConstants.IsRunningTest)
        store.testClearArchive()
    }
}
