/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

protocol TabManagerDelegate: class {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?)
    func tabManager(tabManager: TabManager, didCreateTab tab: Browser, restoring: Bool)
    func tabManager(tabManager: TabManager, didAddTab tab: Browser, atIndex: Int, restoring: Bool)
    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser, atIndex index: Int)
    func tabManagerDidRestoreTabs(tabManager: TabManager)
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

    func addDelegate(delegate: TabManagerDelegate) {
        assert(NSThread.isMainThread())
        delegates.append(WeakTabManagerDelegate(value: delegate))
    }

    func removeDelegate(delegate: TabManagerDelegate) {
        assert(NSThread.isMainThread())
        for var i = 0; i < delegates.count; i++ {
            var del = delegates[i]
            if delegate === del.get() {
                delegates.removeAtIndex(i)
                return
            }
        }
    }

    private var tabs: [Browser] = []
    private var _selectedIndex = -1
    var selectedIndex: Int { return _selectedIndex }
    private let defaultNewTabRequest: NSURLRequest
    private let navDelegate: TabManagerNavDelegate
    private var configuration: WKWebViewConfiguration
    let storage: RemoteClientsAndTabs?

    private let prefs: Prefs

    init(defaultNewTabRequest: NSURLRequest, storage: RemoteClientsAndTabs? = nil, prefs: Prefs) {
        // Create a common webview configuration with a shared process pool.
        configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(prefs.boolForKey("blockPopups") ?? true)

        self.defaultNewTabRequest = defaultNewTabRequest
        self.storage = storage
        self.navDelegate = TabManagerNavDelegate()
        self.prefs = prefs
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

        _selectedIndex = -1
        for i in 0..<count {
            if tabs[i] === tab {
                _selectedIndex = i
                break
            }
        }

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()

        for delegate in delegates {
            delegate.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous)
        }
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func addTab(var request: NSURLRequest! = nil, configuration: WKWebViewConfiguration! = nil) -> Browser {
        return self.addTab(request: request, configuration: configuration, flushToDisk: true, zombie: false)
    }

    func addTab(var request: NSURLRequest! = nil, configuration: WKWebViewConfiguration! = nil, flushToDisk: Bool, zombie: Bool, restoring: Bool = false) -> Browser {
        assert(NSThread.isMainThread())

        configuration?.preferences.javaScriptCanOpenWindowsAutomatically = !(prefs.boolForKey("blockPopups") ?? true)

        let tab = Browser(configuration: configuration ?? self.configuration)

        for delegate in delegates {
            delegate.get()?.tabManager(self, didCreateTab: tab, restoring: restoring)
        }

        tabs.append(tab)

        for delegate in delegates {
            delegate.get()?.tabManager(self, didAddTab: tab, atIndex: tabs.count - 1, restoring: restoring)
        }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate
        tab.loadRequest(request ?? defaultNewTabRequest)

        if flushToDisk {
        	storeChanges()
        }

        return tab
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    func removeTab(tab: Browser) {
        self.removeTab(tab, flushToDisk: true)
    }

    private func removeTab(tab: Browser, flushToDisk: Bool) {
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
        var index = -1
        for i in 0..<count {
            if tabs[i] === tab {
                tabs.removeAtIndex(i)
                index = i
                break
            }
        }
        assert(count == prevCount - 1, "Tab removed")

        // There's still some time between this and the webView being destroyed.
        // We don't want to pick up any stray events.
        tab.webView?.navigationDelegate = nil

        for delegate in delegates {
            delegate.get()?.tabManager(self, didRemoveTab: tab, atIndex: index)
        }

        if flushToDisk {
        	storeChanges()
        }
    }

    func removeAll() {
        let tabs = self.tabs

        for tab in tabs {
            self.removeTab(tab, flushToDisk: false)
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

    private func storeChanges() {
        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = optFilter(tabs.map(Browser.toTab))
        storage?.insertOrUpdateTabs(storedTabs)

        // Also save (full) tab state to disk
        preserveTabs()
    }

    func prefsDidChange() {
        let allowPopups = !(prefs.boolForKey("blockPopups") ?? true)
        for tab in tabs {
            tab.webView?.configuration.preferences.javaScriptCanOpenWindowsAutomatically = allowPopups
        }
    }
}

extension TabManager {
    class SavedTab: NSObject, NSCoding {
        let isSelected: Bool
        let screenshot: UIImage?
        var sessionData: SessionData?

        init?(browser: Browser, isSelected: Bool) {
            let currentItem = browser.webView?.backForwardList.currentItem
            if browser.sessionData == nil {
                let backList = browser.webView?.backForwardList.backList as? [WKBackForwardListItem] ?? []
                let forwardList = browser.webView?.backForwardList.forwardList as? [WKBackForwardListItem] ?? []
                let currentList = (currentItem != nil) ? [currentItem!] : []
                var urlList = backList + currentList + forwardList
                var updatedUrlList = [NSURL]()
                for url in urlList {
                    updatedUrlList.append(url.URL)
                }
                var currentPage = -forwardList.count
                self.sessionData = SessionData(currentPage: currentPage, urls: updatedUrlList)
            } else {
                self.sessionData = browser.sessionData
            }
            self.screenshot = browser.screenshot
            self.isSelected = isSelected

            super.init()
        }

        required init(coder: NSCoder) {
            self.sessionData = coder.decodeObjectForKey("sessionData") as? SessionData
            self.screenshot = coder.decodeObjectForKey("screenshot") as? UIImage
            self.isSelected = coder.decodeBoolForKey("isSelected")
        }

        func encodeWithCoder(coder: NSCoder) {
            coder.encodeObject(sessionData, forKey: "sessionData")
            coder.encodeObject(screenshot, forKey: "screenshot")
            coder.encodeBool(isSelected, forKey: "isSelected")
        }
    }

    private func tabsStateArchivePath() -> String? {
        if let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? String {
            return documentsPath.stringByAppendingPathComponent("tabsState.archive")
        }
        return nil
    }

    private func preserveTabsInternal() {
        if let path = tabsStateArchivePath() {
            var savedTabs = [SavedTab]()
            for (tabIndex, tab) in enumerate(tabs) {
                if let savedTab = SavedTab(browser: tab, isSelected: tabIndex == selectedIndex) {
                    savedTabs.append(savedTab)
                }
            }

            let tabStateData = NSMutableData()
            let archiver = NSKeyedArchiver(forWritingWithMutableData: tabStateData)
            archiver.encodeObject(savedTabs, forKey: "tabs")
            archiver.finishEncoding()
            tabStateData.writeToFile(path, atomically: true)
        }
    }

    func preserveTabs() {
        // This is wrapped in an Objective-C @try/@catch handler because NSKeyedArchiver may throw exceptions which Swift cannot handle
        Try(
            try: { () -> Void in
                self.preserveTabsInternal()
            },
            catch: { exception in
                println("Failed to preserve tabs: \(exception)")
            }
        )
    }

    private func restoreTabsInternal() {
        if let tabStateArchivePath = tabsStateArchivePath() {
            if NSFileManager.defaultManager().fileExistsAtPath(tabStateArchivePath) {
                if let data = NSData(contentsOfFile: tabStateArchivePath) {
                    let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)
                    if let savedTabs = unarchiver.decodeObjectForKey("tabs") as? [SavedTab] {
                        var tabToSelect: Browser?

                        for (tabIndex, savedTab) in enumerate(savedTabs) {
                            let tab = self.addTab(flushToDisk: false, zombie: true, restoring: true)
                            tab.screenshot = savedTab.screenshot
                            if savedTab.isSelected {
                                tabToSelect = tab
                            }
                            tab.sessionData = savedTab.sessionData
                        }

                        if tabToSelect == nil {
                            tabToSelect = tabs.first
                        }

                        for delegate in delegates {
                            delegate.get()?.tabManagerDidRestoreTabs(self)
                        }

                        if let tab = tabToSelect {
                            selectTab(tab)
                            tab.createWebview()
                        }
                    }
                }
            }
        }
    }

    func restoreTabs() {
        // This is wrapped in an Objective-C @try/@catch handler because NSKeyedUnarchiver may throw exceptions which Swift cannot handle
        Try(
            try: { () -> Void in
                self.restoreTabsInternal()
            },
            catch: { exception in
                println("Failed to restore tabs: \(exception)")
            }
        )
    }
}

extension TabManager : WKNavigationDelegate {
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        storeChanges()
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
        NSURLCredential!) -> Void) {
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
