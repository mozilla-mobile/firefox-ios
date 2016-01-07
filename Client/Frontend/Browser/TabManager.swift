/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

private let log = Logger.browserLogger

protocol TabManagerDelegate: class {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?)
    func tabManager(tabManager: TabManager, didCreateTab tab: Browser)
    func tabManager(tabManager: TabManager, didAddTab tab: Browser)
    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser)
    func tabManagerDidRestoreTabs(tabManager: TabManager)
    func tabManagerDidAddTabs(tabManager: TabManager)
}

protocol TabManagerStateDelegate: class {
    func tabManagerWillStoreTabs(tabs: [Browser])
}

// We can't use a WeakList here because this is a protocol.
class WeakTabManagerDelegate {
    weak var value : TabManagerDelegate?

    init (value: TabManagerDelegate) {
        self.value = value
    }

    func get() -> TabManagerDelegate? {
        return value
    }
}

// TabManager must extend NSObjectProtocol in order to implement WKNavigationDelegate
class TabManager : NSObject {
    private var delegates = [WeakTabManagerDelegate]()
    weak var stateDelegate: TabManagerStateDelegate?

    func addDelegate(delegate: TabManagerDelegate) {
        assert(NSThread.isMainThread())
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func removeDelegate(delegate: TabManagerDelegate) {
        assert(NSThread.isMainThread())
        for var i = 0; i < delegates.count; i++ {
            let del = delegates[i]
            if delegate === del.get() {
                delegates.removeAtIndex(i)
                return
            }
        }
    }

    private(set) var tabs = [Browser]()
    private var _selectedIndex = -1
    private let defaultNewTabRequest: NSURLRequest
    private let navDelegate: TabManagerNavDelegate
    private(set) var isRestoring = false

    // A WKWebViewConfiguration used for normal tabs
    lazy private var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        return configuration
    }()

    // A WKWebViewConfiguration used for private mode tabs
    @available(iOS 9, *)
    lazy private var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore()
        return configuration
    }()

    private let imageStore: DiskImageStore?

    private let prefs: Prefs
    var selectedIndex: Int { return _selectedIndex }

    var normalTabs: [Browser] {
        return tabs.filter { !$0.isPrivate }
    }

    var privateTabs: [Browser] {
        if #available(iOS 9, *) {
            return tabs.filter { $0.isPrivate }
        } else {
            return []
        }
    }

    init(defaultNewTabRequest: NSURLRequest, prefs: Prefs, imageStore: DiskImageStore?) {
        self.prefs = prefs
        self.defaultNewTabRequest = defaultNewTabRequest
        self.navDelegate = TabManagerNavDelegate()
        self.imageStore = imageStore
        super.init()

        addNavigationDelegate(self)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prefsDidChange", name: NSUserDefaultsDidChangeNotification, object: nil)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func addNavigationDelegate(delegate: WKNavigationDelegate) {
        self.navDelegate.insert(delegate)
    }

    var count: Int {
        return tabs.count
    }

    var selectedTab: Browser? {
        if !(0..<count ~= _selectedIndex) {
            return nil
        }

        return tabs[_selectedIndex]
    }

    subscript(index: Int) -> Browser? {
        if index >= tabs.count {
            return nil
        }
        return tabs[index]
    }

    subscript(webView: WKWebView) -> Browser? {
        for tab in tabs {
            if tab.webView === webView {
                return tab
            }
        }

        return nil
    }

    func selectTab(tab: Browser?) {
        assert(NSThread.isMainThread())

        if selectedTab === tab {
            return
        }

        let previous = selectedTab

        if let tab = tab {
            _selectedIndex = tabs.indexOf(tab) ?? -1
        } else {
            _selectedIndex = -1
        }

        preserveTabs()

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()

        for delegate in delegates {
            delegate.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous)
        }
    }

    func expireSnackbars() {
        for tab in tabs {
            tab.expireSnackbars()
        }
    }

    @available(iOS 9, *)
    func addTab(request: NSURLRequest! = nil, configuration: WKWebViewConfiguration! = nil, isPrivate: Bool) -> Browser {
        return self.addTab(request, configuration: configuration, flushToDisk: true, zombie: false, isPrivate: isPrivate)
    }

    func addTabAndSelect(request: NSURLRequest! = nil, configuration: WKWebViewConfiguration! = nil) -> Browser {
        let tab = addTab(request, configuration: configuration)
        selectTab(tab)
        return tab
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func addTab(request: NSURLRequest! = nil, configuration: WKWebViewConfiguration! = nil) -> Browser {
        return self.addTab(request, configuration: configuration, flushToDisk: true, zombie: false)
    }

    func addTabsForURLs(urls: [NSURL], zombie: Bool) {
        if urls.isEmpty {
            return
        }

        var tab: Browser!
        for url in urls {
            tab = self.addTab(NSURLRequest(URL: url), flushToDisk: false, zombie: zombie)
        }

        // Flush.
        storeChanges()

        // Select the most recent.
        self.selectTab(tab)

        // Notify that we bulk-loaded so we can adjust counts.
        for delegate in delegates {
            delegate.get()?.tabManagerDidAddTabs(self)
        }
    }

    @available(iOS 9, *)
    private func addTab(request: NSURLRequest? = nil, var configuration: WKWebViewConfiguration! = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool) -> Browser {
        assert(NSThread.isMainThread())

        if configuration == nil {
            configuration = isPrivate ? privateConfiguration : self.configuration
        }
        
        let tab = Browser(configuration: configuration, isPrivate: isPrivate)
        configureTab(tab, request: request, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    private func addTab(request: NSURLRequest? = nil, configuration: WKWebViewConfiguration! = nil, flushToDisk: Bool, zombie: Bool) -> Browser {
        assert(NSThread.isMainThread())

        let tab = Browser(configuration: configuration ?? self.configuration)
        configureTab(tab, request: request, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    func configureTab(tab: Browser, request: NSURLRequest?, flushToDisk: Bool, zombie: Bool) {
        for delegate in delegates {
            delegate.get()?.tabManager(self, didCreateTab: tab)
        }

        tabs.append(tab)

        for delegate in delegates {
            delegate.get()?.tabManager(self, didAddTab: tab)
        }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate
        tab.loadRequest(request ?? defaultNewTabRequest)

        if flushToDisk {
        	storeChanges()
        }
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func removeTab(tab: Browser) {
        self.removeTab(tab, flushToDisk: true, notify: true)
        hideNetworkActivitySpinner()
    }

    /// - Parameter notify: if set to true, will call the delegate after the tab 
    ///   is removed.
    private func removeTab(tab: Browser, flushToDisk: Bool, notify: Bool) {
        assert(NSThread.isMainThread())
        // If the removed tab was selected, find the new tab to select.
        if tab === selectedTab {
            let index = getIndex(tab)
            if index + 1 < count {
                selectTab(tabs[index + 1])
            } else if index - 1 >= 0 {
                selectTab(tabs[index - 1])
            } else {
                assert(count == 1, "Removing last tab")
                selectTab(nil)
            }
        }

        let prevCount = count
        for i in 0..<count {
            if tabs[i] === tab {
                tabs.removeAtIndex(i)
                break
            }
        }
        assert(count == prevCount - 1, "Tab removed")

        if tab != selectedTab {
            _selectedIndex = selectedTab == nil ? -1 : tabs.indexOf(selectedTab!) ?? 0
        }

        // There's still some time between this and the webView being destroyed.
        // We don't want to pick up any stray events.
        tab.webView?.navigationDelegate = nil

        if notify {
            for delegate in delegates {
                delegate.get()?.tabManager(self, didRemoveTab: tab)
            }
        }

        // Make sure we never reach 0 normal tabs
        if !tab.isPrivate && normalTabs.count == 0 {
            addTab()
        }

        if flushToDisk {
        	storeChanges()
        }
    }

    /// Removes all private tabs from the manager.
    /// - Parameter notify: if set to true, the delegate is called when a tab is 
    ///   removed.
    func removeAllPrivateTabsAndNotify(notify: Bool) {
        privateTabs.forEach({ removeTab($0, flushToDisk: true, notify: notify) })
    }
    
    func removeAll() {
        let tabs = self.tabs

        for tab in tabs {
            self.removeTab(tab, flushToDisk: false, notify: true)
        }
        storeChanges()
    }

    func getIndex(tab: Browser) -> Int {
        for i in 0..<count {
            if tabs[i] === tab {
                return i
            }
        }
        
        assertionFailure("Tab not in tabs list")
        return -1
    }

    func storeChanges() {
        stateDelegate?.tabManagerWillStoreTabs(normalTabs)

        // Also save (full) tab state to disk.
        preserveTabs()
    }

    func prefsDidChange() {
        let allowPopups = !(self.prefs.boolForKey("blockPopups") ?? true)
        // Each tab may have its own configuration, so we should tell each of them in turn.
        for tab in tabs {
            tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
        // The default tab configurations also need to change.
        self.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        if #available(iOS 9, *) {
            self.privateConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
    }

    func resetProcessPool() {
        configuration.processPool = WKProcessPool()
    }
}

extension TabManager {

    class SavedTab: NSObject, NSCoding {
        let isSelected: Bool
        let title: String?
        let isPrivate: Bool
        var sessionData: SessionData?
        var screenshotUUID: NSUUID?

        var jsonDictionary: [String: AnyObject] {
            let title: String = self.title ?? "null"
            let uuid: String = String(self.screenshotUUID ?? "null")

            var json: [String: AnyObject] = [
                "title": title,
                "isPrivate": String(self.isPrivate),
                "isSelected": String(self.isSelected),
                "screenshotUUID": uuid
            ]

            if let sessionDataInfo = self.sessionData?.jsonDictionary {
                json["sessionData"] = sessionDataInfo
            }

            return json
        }

        init?(browser: Browser, isSelected: Bool) {
            self.screenshotUUID = browser.screenshotUUID
            self.isSelected = isSelected
            self.title = browser.displayTitle
            self.isPrivate = browser.isPrivate
            super.init()

            if browser.sessionData == nil {
                let currentItem: WKBackForwardListItem! = browser.webView?.backForwardList.currentItem

                // Freshly created web views won't have any history entries at all.
                // If we have no history, abort.
                if currentItem == nil {
                    return nil
                }

                let backList = browser.webView?.backForwardList.backList ?? []
                let forwardList = browser.webView?.backForwardList.forwardList ?? []
                let urls = (backList + [currentItem] + forwardList).map { $0.URL }
                let currentPage = -forwardList.count
                self.sessionData = SessionData(currentPage: currentPage, urls: urls, lastUsedTime: browser.lastExecutedTime ?? NSDate.now())
            } else {
                self.sessionData = browser.sessionData
            }
        }

        required init?(coder: NSCoder) {
            self.sessionData = coder.decodeObjectForKey("sessionData") as? SessionData
            self.screenshotUUID = coder.decodeObjectForKey("screenshotUUID") as? NSUUID
            self.isSelected = coder.decodeBoolForKey("isSelected")
            self.title = coder.decodeObjectForKey("title") as? String
            self.isPrivate = coder.decodeBoolForKey("isPrivate")
        }

        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(sessionData, forKey: "sessionData")
            coder.encodeObject(screenshotUUID, forKey: "screenshotUUID")
            coder.encodeBool(isSelected, forKey: "isSelected")
            coder.encodeObject(title, forKey: "title")
            coder.encodeBool(isPrivate, forKey: "isPrivate")
        }
    }

    static private func tabsStateArchivePath() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        return NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent("tabsState.archive").path!
    }

    static func tabsToRestore() -> [SavedTab]? {
        let tabStateArchivePath = tabsStateArchivePath()
        if NSFileManager.defaultManager().fileExistsAtPath(tabStateArchivePath) {
            if let data = NSData(contentsOfFile: tabStateArchivePath) {
                let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
                return unarchiver.decodeObjectForKey("tabs") as? [SavedTab]
            }
        }
        return nil
    }

    private func preserveTabsInternal() {
        guard !isRestoring else { return }

        let path = TabManager.tabsStateArchivePath()
        var savedTabs = [SavedTab]()
        var savedUUIDs = Set<String>()
        for (tabIndex, tab) in tabs.enumerate() {
            if let savedTab = SavedTab(browser: tab, isSelected: tabIndex == selectedIndex) {
                savedTabs.append(savedTab)

                if let screenshot = tab.screenshot,
                   let screenshotUUID = tab.screenshotUUID
                {
                    savedUUIDs.insert(screenshotUUID.UUIDString)
                    imageStore?.put(screenshotUUID.UUIDString, image: screenshot)
                }
            }
        }

        // Clean up any screenshots that are no longer associated with a tab.
        imageStore?.clearExcluding(savedUUIDs)

        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: tabStateData)
        archiver.encodeObject(savedTabs, forKey: "tabs")
        archiver.finishEncoding()
        tabStateData.writeToFile(path, atomically: true)
    }

    func preserveTabs() {
        // This is wrapped in an Objective-C @try/@catch handler because NSKeyedArchiver may throw exceptions which Swift cannot handle
        _ = Try(withTry: { () -> Void in
            self.preserveTabsInternal()
            }) { (exception) -> Void in
            print("Failed to preserve tabs: \(exception)")
        }
    }

    private func restoreTabsInternal() {
        log.debug("Restoring tabs.")
        guard let savedTabs = TabManager.tabsToRestore() else {
            log.debug("Nothing to restore.")
            return
        }

        var tabToSelect: Browser?
        for (_, savedTab) in savedTabs.enumerate() {
            let tab: Browser
            if #available(iOS 9, *) {
                tab = self.addTab(flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)
            } else {
                tab = self.addTab(flushToDisk: false, zombie: true)
            }

            // Set the UUID for the tab, asynchronously fetch the UIImage, then store
            // the screenshot in the tab as long as long as a newer one hasn't been taken.
            if let screenshotUUID = savedTab.screenshotUUID,
               let imageStore = self.imageStore {
                tab.screenshotUUID = screenshotUUID
                imageStore.get(screenshotUUID.UUIDString) >>== { screenshot in
                    if tab.screenshotUUID == screenshotUUID {
                        tab.setScreenshot(screenshot, revUUID: false)
                    }
                }
            }

            if savedTab.isSelected {
                tabToSelect = tab
            }

            tab.sessionData = savedTab.sessionData
            tab.lastTitle = savedTab.title
        }

        if tabToSelect == nil {
            tabToSelect = tabs.first
        }

        log.debug("Done adding tabs.")

        // Only tell our delegates that we restored tabs if we actually restored a tab(s)
        if savedTabs.count > 0 {
            log.debug("Notifying delegates.")
            for delegate in delegates {
                delegate.get()?.tabManagerDidRestoreTabs(self)
            }
        }

        if let tab = tabToSelect {
            log.debug("Selecting a tab.")
            selectTab(tab)
            log.debug("Creating webview for selected tab.")
            tab.createWebview()
        }

        log.debug("Done.")
    }

    func restoreTabs() {
        isRestoring = true

        if count == 0 && !AppConstants.IsRunningTest && !DebugSettingsBundleOptions.skipSessionRestore {
            // This is wrapped in an Objective-C @try/@catch handler because NSKeyedUnarchiver may throw exceptions which Swift cannot handle
            let _ = Try(
                `withTry`: { () -> Void in
                    self.restoreTabsInternal()
                },
                `catch`: { exception in
                    print("Failed to restore tabs: \(exception)")
                }
            )
        }

        if count == 0 {
            let tab = addTab()
            selectTab(tab)
        }

        isRestoring = false
    }
}

extension TabManager : WKNavigationDelegate {
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        hideNetworkActivitySpinner()
        // only store changes if this is not an error page
        // as we current handle tab restore as error page redirects then this ensures that we don't
        // call storeChanges unnecessarily on startup
        if let url = webView.URL {
            if !ErrorPageHelper.isErrorPageURL(url) {
                storeChanges()
            }
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        hideNetworkActivitySpinner()
    }

    func hideNetworkActivitySpinner() {
        for tab in tabs {
            if let tabWebView = tab.webView {
                // If we find one tab loading, we don't hide the spinner
                if tabWebView.loading {
                    return
                }
            }
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    /// Called when the WKWebView's content process has gone away. If this happens for the currently selected tab
    /// then we immediately reload it.

    func webViewWebContentProcessDidTerminate(webView: WKWebView) {
        if let browser = selectedTab where browser.webView == webView {
            webView.reload()
        }
    }
}

extension TabManager {
    class func tabRestorationDebugInfo() -> String {
        let tabs = TabManager.tabsToRestore()?.map { $0.jsonDictionary } ?? []
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(tabs, options: [.PrettyPrinted])
            return String(data: jsonData, encoding: NSUTF8StringEncoding) ?? ""
        } catch _ {
            return ""
        }
    }
}

// WKNavigationDelegates must implement NSObjectProtocol
class TabManagerNavDelegate : NSObject, WKNavigationDelegate {
    private var delegates = WeakList<WKNavigationDelegate>()

    func insert(delegate: WKNavigationDelegate) {
        delegates.insert(delegate)
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didCommitNavigation: navigation)
        }
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        for delegate in delegates {
            delegate.webView?(webView, didFailNavigation: navigation, withError: error)
        }
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: NSError) {
            for delegate in delegates {
                delegate.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
            }
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didFinishNavigation: navigation)
        }
    }

    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition,
        NSURLCredential?) -> Void) {
            var disp: NSURLSessionAuthChallengeDisposition? = nil
            for delegate in delegates {
                delegate.webView?(webView, didReceiveAuthenticationChallenge: challenge) { (disposition, credential) in
                    // Whoever calls this method first wins. All other calls are ignored.
                    if disp != nil {
                        return
                    }

                    disp = disposition
                    completionHandler(disposition, credential)
                }
            }
    }

    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
        }
    }

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        for delegate in delegates {
            delegate.webView?(webView, didStartProvisionalNavigation: navigation)
        }
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction,
        decisionHandler: (WKNavigationActionPolicy) -> Void) {
            var res = WKNavigationActionPolicy.Allow
            for delegate in delegates {
                delegate.webView?(webView, decidePolicyForNavigationAction: navigationAction, decisionHandler: { policy in
                    if policy == .Cancel {
                        res = policy
                    }
                })
            }

            decisionHandler(res)
    }

    func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse,
        decisionHandler: (WKNavigationResponsePolicy) -> Void) {
            var res = WKNavigationResponsePolicy.Allow
            for delegate in delegates {
                delegate.webView?(webView, decidePolicyForNavigationResponse: navigationResponse, decisionHandler: { policy in
                    if policy == .Cancel {
                        res = policy
                    }
                })
            }

            decisionHandler(res)
    }
}
