/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

protocol TabManagerDelegate: class {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?)
    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab)
    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab)

    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?)
}

protocol TabManagerStateDelegate: class {
    func tabManagerWillStoreTabs(_ tabs: [Tab])
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
    weak var stateDelegate: TabManagerStateDelegate?

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
    fileprivate(set) var isRestoring = false

    // A WKWebViewConfiguration used for normal tabs
    lazy fileprivate var configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        return configuration
    }()

    // A WKWebViewConfiguration used for private mode tabs
    lazy fileprivate var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        return configuration
    }()

    fileprivate let imageStore: DiskImageStore?

    fileprivate let prefs: Prefs
    var selectedIndex: Int { return _selectedIndex }
    var tempTabs: [Tab]?

    var normalTabs: [Tab] {
        assert(Thread.isMainThread)

        return tabs.filter { !$0.isPrivate }
    }

    var privateTabs: [Tab] {
        assert(Thread.isMainThread)
        return tabs.filter { $0.isPrivate }
    }

    init(prefs: Prefs, imageStore: DiskImageStore?) {
        assert(Thread.isMainThread)

        self.prefs = prefs
        self.navDelegate = TabManagerNavDelegate()
        self.imageStore = imageStore
        super.init()

        addNavigationDelegate(self)

        NotificationCenter.default.addObserver(self, selector: #selector(TabManager.prefsDidChange), name: UserDefaults.didChangeNotification, object: nil)
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

        preserveTabs()

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()

        delegates.forEach { $0.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous) }
    }

    func shouldClearPrivateTabs() -> Bool {
        return prefs.boolForKey("settings.closePrivateTabs") ?? false
    }

    //Called by other classes to signal that they are entering/exiting private mode
    //This is called by TabTrayVC when the private mode button is pressed and BEFORE we've switched to the new mode
    func willSwitchTabMode() {
        if shouldClearPrivateTabs() && (selectedTab?.isPrivate ?? false) {
            removeAllPrivateTabs()
        }
    }

    func expireSnackbars() {
        assert(Thread.isMainThread)

        for tab in tabs {
            tab.expireSnackbars()
        }
    }

    @discardableResult func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil, isPrivate: Bool) -> Tab {
        return self.addTab(request, configuration: configuration, afterTab: afterTab, flushToDisk: true, zombie: false, isPrivate: isPrivate)
    }

    func addTabAndSelect(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil, isPrivate: Bool) -> Tab {
        let tab = addTab(request, configuration: configuration, afterTab: afterTab, isPrivate: isPrivate)
        selectTab(tab)
        return tab
    }

    @discardableResult func addTabAndSelect(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil) -> Tab {
        let tab = addTab(request, configuration: configuration, afterTab: afterTab)
        selectTab(tab)
        return tab
    }

    // This method is duplicated to hide the flushToDisk option from consumers.
    @discardableResult func addTab(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil) -> Tab {
        return self.addTab(request, configuration: configuration, afterTab: afterTab, flushToDisk: true, zombie: false)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool) {
        assert(Thread.isMainThread)

        if urls.isEmpty {
            return
        }
        // When bulk adding tabs don't notify delegates until we are done
        self.isRestoring = true
        var tab: Tab!
        for url in urls {
            tab = self.addTab(URLRequest(url: url), flushToDisk: false, zombie: zombie)
        }
        // Flush.
        storeChanges()
        // Select the most recent.
        self.selectTab(tab)
        self.isRestoring = false
        // Okay now notify that we bulk-loaded so we can adjust counts and animate changes.
        delegates.forEach { $0.get()?.tabManagerDidAddTabs(self) }
    }

    fileprivate func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, afterTab: Tab? = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool) -> Tab {
        assert(Thread.isMainThread)

        // Take the given configuration. Or if it was nil, take our default configuration for the current browsing mode.
        let configuration: WKWebViewConfiguration = configuration ?? (isPrivate ? privateConfiguration : self.configuration)

        let tab = Tab(configuration: configuration, isPrivate: isPrivate)
        configureTab(tab, request: request, afterTab: afterTab, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }

    fileprivate func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, afterTab: Tab? = nil, flushToDisk: Bool, zombie: Bool) -> Tab {
        assert(Thread.isMainThread)

        let tab = Tab(configuration: configuration ?? self.configuration)
        configureTab(tab, request: request, afterTab: afterTab, flushToDisk: flushToDisk, zombie: zombie)
        return tab
    }
    
    func moveTab(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {
        assert(Thread.isMainThread)
        
        let currentTabs = privateMode ? privateTabs : normalTabs
        let fromIndex = tabs.index(of: currentTabs[visibleFromIndex]) ?? tabs.count - 1
        let toIndex = tabs.index(of: currentTabs[visibleToIndex]) ?? tabs.count - 1
        
        let previouslySelectedTab = selectedTab
        
        tabs.insert(tabs.remove(at: fromIndex), at: toIndex)
        
        if let previouslySelectedTab = previouslySelectedTab, let previousSelectedIndex = tabs.index(of: previouslySelectedTab) {
            _selectedIndex = previousSelectedIndex
        }
        
        storeChanges()
    }

    func configureTab(_ tab: Tab, request: URLRequest?, afterTab parent: Tab? = nil, flushToDisk: Bool, zombie: Bool) {
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

        delegates.forEach { $0.get()?.tabManager(self, didAddTab: tab) }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate

        if let request = request {
            tab.loadRequest(request)
        } else {
            let newTabChoice = NewTabAccessors.getNewTabPage(prefs)
            switch newTabChoice {
            case .homePage:
                // We definitely have a homepage if we've got here 
                // (so we can safely dereference it).
                let url = HomePageAccessors.getHomePage(prefs)!
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

    // This method is duplicated to hide the flushToDisk option from consumers.
    func removeTab(_ tab: Tab) {
        self.removeTab(tab, flushToDisk: true, notify: true)
        hideNetworkActivitySpinner()
    }

    /// - Parameter notify: if set to true, will call the delegate after the tab
    ///   is removed.
    fileprivate func removeTab(_ tab: Tab, flushToDisk: Bool, notify: Bool) {
        assert(Thread.isMainThread)

        guard let removalIndex = tabs.index(where: { $0 === tab }) else {
            Sentry.shared.sendWithStacktrace(message: "Could not find index of tab to remove", tag: .tabManager, severity: .fatal, description: "Tab count: \(count)")
            return
        }

        if tab.isPrivate {
            removeAllBrowsingDataForTab(tab)
        }

        let oldSelectedTab = selectedTab

        if notify {
            delegates.forEach { $0.get()?.tabManager(self, willRemoveTab: tab) }
        }

        // The index of the tab in its respective tab grouping. Used to figure out which tab is next
        var tabIndex: Int = -1
        if let oldTab = oldSelectedTab {
            tabIndex = (tab.isPrivate ? privateTabs.index(of: oldTab) : normalTabs.index(of: oldTab)) ?? -1
        }

        let prevCount = count
        tabs.remove(at: removalIndex)

        let viableTabs: [Tab] = tab.isPrivate ? privateTabs : normalTabs

        // Let's select the tab to be selected next.
        if let oldTab = oldSelectedTab, tab !== oldTab {
            // If it wasn't the selected tab we removed, then keep it like that.
            // It might have changed index, so we look it up again.
            _selectedIndex = tabs.index(of: oldTab) ?? -1
        } else if let newTab = viableTabs.reduce(viableTabs.first, { currentBestTab, tab2 in
            if let tab1 = currentBestTab, let time1 = tab1.lastExecutedTime {
                if let time2 = tab2.lastExecutedTime {
                    return time1 <= time2 ? tab2 : tab1
                }
                return tab1
            } else {
                return tab2
            }
        }), tab !== newTab, newTab.lastExecutedTime != nil {
            // Next we look for the most recently loaded one. It might not exist, of course.
            _selectedIndex = tabs.index(of: newTab) ?? -1
        } else {
            // By now, we've just removed the selected one, and no previously loaded
            // tabs. So let's load the final one in the tab tray.
            if tabIndex == viableTabs.count {
                tabIndex -= 1
            }
            if tabIndex < viableTabs.count && !viableTabs.isEmpty {
                _selectedIndex = tabs.index(of: viableTabs[tabIndex]) ?? -1
            } else {
                _selectedIndex = -1
            }
        }

        assert(count == prevCount - 1, "Make sure the tab count was actually removed")

        // There's still some time between this and the webView being destroyed. We don't want to pick up any stray events.
        tab.webView?.navigationDelegate = nil

        if notify {
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab) }
        }

        if !tab.isPrivate && viableTabs.isEmpty {
            addTab()
        }

        // If the removed tab was selected, find the new tab to select.
        if selectedTab != nil {
            selectTab(selectedTab, previous: oldSelectedTab)
        } else {
            selectTab(tabs.last, previous: oldSelectedTab)
        }

        if flushToDisk {
            storeChanges()
        }
    }

    /// Removes all private tabs from the manager without notifying delegates.
    private func removeAllPrivateTabs() {
        tabs.forEach { tab in
            if tab.isPrivate {
                removeAllBrowsingDataForTab(tab)
            }
        }

        tabs = tabs.filter { !$0.isPrivate }
    }

    func removeAllBrowsingDataForTab(_ tab: Tab, completionHandler: @escaping () -> Void = {}) {
        let dataTypes = Set([WKWebsiteDataTypeCookies,
                             WKWebsiteDataTypeLocalStorage,
                             WKWebsiteDataTypeSessionStorage,
                             WKWebsiteDataTypeWebSQLDatabases,
                             WKWebsiteDataTypeIndexedDBDatabases])
        tab.webView?.configuration.websiteDataStore.removeData(ofTypes: dataTypes,
                                                               modifiedSince: Date.distantPast,
                                                               completionHandler: completionHandler)
    }

    func removeTabsWithUndoToast(_ tabs: [Tab]) {
        tempTabs = tabs
        var tabsCopy = tabs
        
        // Remove the current tab last to prevent switching tabs while removing tabs
        if let selectedTab = selectedTab {
            if let selectedIndex = tabsCopy.index(of: selectedTab) {
                let removed = tabsCopy.remove(at: selectedIndex)
                removeTabs(tabsCopy)
                removeTab(removed)
            } else {
                removeTabs(tabsCopy)
            }
        }
        for tab in tabs {
            tab.hideContent()
        }
        var toast: ButtonToast?
        if let numberOfTabs = tempTabs?.count, numberOfTabs > 0 {
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
        guard let tempTabs = self.tempTabs, tempTabs.count > 0 else {
            return
        }
        let tabsCopy = normalTabs
        restoreTabs(tempTabs)
        self.isRestoring = true
        for tab in tempTabs {
            tab.showContent(true)
        }
        if !tempTabs[0].isPrivate {
            removeTabs(tabsCopy)
        }
        selectTab(tempTabs.first)
        self.isRestoring = false
        delegates.forEach { $0.get()?.tabManagerDidRestoreTabs(self) }
        self.tempTabs?.removeAll()
        tabs.first?.createWebview()
    }
    
    func eraseUndoCache() {
        tempTabs?.removeAll()
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

    func getIndex(_ tab: Tab) -> Int? {
        assert(Thread.isMainThread)

        for i in 0..<count where tabs[i] === tab {
            return i
        }

        assertionFailure("Tab not in tabs list")
        return nil
    }

    func getTabForURL(_ url: URL) -> Tab? {
        assert(Thread.isMainThread)

        return tabs.filter { $0.webView?.url == url } .first
    }

    func storeChanges() {
        stateDelegate?.tabManagerWillStoreTabs(normalTabs)

        // Also save (full) tab state to disk.
        preserveTabs()
    }

    func prefsDidChange() {
        DispatchQueue.main.async {
            let allowPopups = !(self.prefs.boolForKey("blockPopups") ?? true)
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

class SavedTab: NSObject, NSCoding {
    let isSelected: Bool
    let title: String?
    let isPrivate: Bool
    var sessionData: SessionData?
    var screenshotUUID: UUID?
    var faviconURL: String?

    var jsonDictionary: [String: AnyObject] {
        let title: String = self.title ?? "null"
        let faviconURL: String = self.faviconURL ?? "null"
        let uuid: String = self.screenshotUUID?.uuidString ?? "null"

        var json: [String: AnyObject] = [
            "title": title as AnyObject,
            "isPrivate": String(self.isPrivate) as AnyObject,
            "isSelected": String(self.isSelected) as AnyObject,
            "faviconURL": faviconURL as AnyObject,
            "screenshotUUID": uuid as AnyObject
        ]

        if let sessionDataInfo = self.sessionData?.jsonDictionary {
            json["sessionData"] = sessionDataInfo as AnyObject?
        }

        return json
    }

    init?(tab: Tab, isSelected: Bool) {
        assert(Thread.isMainThread)

        self.screenshotUUID = tab.screenshotUUID as UUID?
        self.isSelected = isSelected
        self.title = tab.displayTitle
        self.isPrivate = tab.isPrivate
        self.faviconURL = tab.displayFavicon?.url
        super.init()

        if tab.sessionData == nil {
            let currentItem: WKBackForwardListItem! = tab.webView?.backForwardList.currentItem

            // Freshly created web views won't have any history entries at all.
            // If we have no history, abort.
            if currentItem == nil {
                return nil
            }

            let backList = tab.webView?.backForwardList.backList ?? []
            let forwardList = tab.webView?.backForwardList.forwardList ?? []
            let urls = (backList + [currentItem] + forwardList).map { $0.url }
            let currentPage = -forwardList.count
            self.sessionData = SessionData(currentPage: currentPage, urls: urls, lastUsedTime: tab.lastExecutedTime ?? Date.now())
        } else {
            self.sessionData = tab.sessionData
        }
    }

    required init?(coder: NSCoder) {
        self.sessionData = coder.decodeObject(forKey: "sessionData") as? SessionData
        self.screenshotUUID = coder.decodeObject(forKey: "screenshotUUID") as? UUID
        self.isSelected = coder.decodeBool(forKey: "isSelected")
        self.title = coder.decodeObject(forKey: "title") as? String
        self.isPrivate = coder.decodeBool(forKey: "isPrivate")
        self.faviconURL = coder.decodeObject(forKey: "faviconURL") as? String
    }

    func encode(with coder: NSCoder) {
        coder.encode(sessionData, forKey: "sessionData")
        coder.encode(screenshotUUID, forKey: "screenshotUUID")
        coder.encode(isSelected, forKey: "isSelected")
        coder.encode(title, forKey: "title")
        coder.encode(isPrivate, forKey: "isPrivate")
        coder.encode(faviconURL, forKey: "faviconURL")
    }
}

extension TabManager {

    static fileprivate func tabsStateArchivePath() -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: documentsPath).appendingPathComponent("tabsState.archive").path
    }

    static func tabArchiveData() -> Data? {
        let tabStateArchivePath = tabsStateArchivePath()
        if FileManager.default.fileExists(atPath: tabStateArchivePath) {
            return (try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)))
        } else {
            return nil
        }
    }

    static func tabsToRestore() -> [SavedTab]? {
        if let tabData = tabArchiveData() {
            let unarchiver = NSKeyedUnarchiver(forReadingWith: tabData)
            unarchiver.decodingFailurePolicy = .setErrorAndReturn
            guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
                Sentry.shared.send(message: "Failed to restore tabs", tag: SentryTag.tabManager, severity: .error, description: "\(unarchiver.error ??? "nil")")
                return nil
            }
            return tabs
        } else {
            return nil
        }
    }

    fileprivate func preserveTabsInternal() {
        assert(Thread.isMainThread)

        guard !isRestoring else { return }

        let path = TabManager.tabsStateArchivePath()
        var savedTabs = [SavedTab]()
        var savedUUIDs = Set<String>()
        for (tabIndex, tab) in tabs.enumerated() {
            if let savedTab = SavedTab(tab: tab, isSelected: tabIndex == selectedIndex) {
                savedTabs.append(savedTab)

                if let screenshot = tab.screenshot,
                   let screenshotUUID = tab.screenshotUUID {
                    savedUUIDs.insert(screenshotUUID.uuidString)
                    imageStore?.put(screenshotUUID.uuidString, image: screenshot)
                }
            }
        }

        // Clean up any screenshots that are no longer associated with a tab.
        _ = imageStore?.clearExcluding(savedUUIDs)

        let tabStateData = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: tabStateData)
        archiver.encode(savedTabs, forKey: "tabs")
        archiver.finishEncoding()
        tabStateData.write(toFile: path, atomically: true)
    }

    func preserveTabs() {
        // This is wrapped in an Objective-C @try/@catch handler because NSKeyedArchiver may throw exceptions which Swift cannot handle
        _ = Try(withTry: { () -> Void in
            self.preserveTabsInternal()
            }) { (exception) -> Void in
            Sentry.shared.send(message: "Failed to preserve tabs", tag: SentryTag.tabManager, severity: .error, description: "\(exception ??? "nil")")
        }
    }

    fileprivate func restoreTabsInternal() {
        guard var savedTabs = TabManager.tabsToRestore() else {
            return
        }

        // Make sure to wipe the private tabs if the user has the pref turned on
        if shouldClearPrivateTabs() {
            savedTabs = savedTabs.filter { !$0.isPrivate }
        }

        var tabToSelect: Tab?
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            let tab = self.addTab(nil, configuration: nil, afterTab: nil, flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)

            // Since this is a restored tab, reset the URL to be loaded as that will be handled by the SessionRestoreHandler
            tab.url = nil

            if let faviconURL = savedTab.faviconURL {
                let icon = Favicon(url: faviconURL, date: Date(), type: IconType.noneFound)
                icon.width = 1
                tab.favicons.append(icon)
            }

            // Set the UUID for the tab, asynchronously fetch the UIImage, then store
            // the screenshot in the tab as long as long as a newer one hasn't been taken.
            if let screenshotUUID = savedTab.screenshotUUID,
               let imageStore = self.imageStore {
                tab.screenshotUUID = screenshotUUID
                imageStore.get(screenshotUUID.uuidString) >>== { screenshot in
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

        // Only tell our delegates that we restored tabs if we actually restored a tab(s)
        if savedTabs.count > 0 {
            for delegate in delegates {
                delegate.get()?.tabManagerDidRestoreTabs(self)
            }
        }

        if let tab = tabToSelect {
            selectTab(tab)
            tab.createWebview()
        }
    }

    func restoreTabs() {
        isRestoring = true

        if count == 0 && !AppConstants.IsRunningTest && !DebugSettingsBundleOptions.skipSessionRestore {
            // This is wrapped in an Objective-C @try/@catch handler because NSKeyedUnarchiver may throw exceptions which Swift cannot handle
            _ = Try(
                withTry: { () -> Void in
                    self.restoreTabsInternal()
                },
                catch: { exception in
                    Sentry.shared.send(message: "Failed to restore tabs: ", tag: SentryTag.tabManager, severity: .error, description: "\(exception ??? "nil")")
                }
            )
        }
        isRestoring = false

        // Always make sure there is a single normal tab.
        if normalTabs.isEmpty {
            let tab = addTab()
            if selectedTab == nil {
                selectTab(tab)
            }
        }
    }
    
    func restoreTabs(_ savedTabs: [Tab]) {
        isRestoring = true
        for tab in savedTabs {
            tabs.append(tab)
            tab.navigationDelegate = self.navDelegate
            for delegate in delegates {
                delegate.get()?.tabManager(self, didAddTab: tab)
            }
        }
        isRestoring = false
    }
}

extension TabManager: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        let tab = self[webView]
        let isNightMode = NightModeAccessors.isNightMode(self.prefs)
        tab?.setNightMode(isNightMode)

        if #available(iOS 11, *) {
            let isNoImageMode = self.prefs.boolForKey(PrefsKeys.KeyNoImageModeStatus) ?? false
            tab?.noImageMode = isNoImageMode
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hideNetworkActivitySpinner()
        // only store changes if this is not an error page
        // as we current handle tab restore as error page redirects then this ensures that we don't
        // call storeChanges unnecessarily on startup
        if let url = webView.url {
            if !url.isErrorPageURL {
                storeChanges()
            }
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

extension TabManager {
    class func tabRestorationDebugInfo() -> String {
        assert(Thread.isMainThread)

        let tabs = TabManager.tabsToRestore()?.map { $0.jsonDictionary } ?? []
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tabs, options: [.prettyPrinted])
            return String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch _ {
            return ""
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

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let authenticatingDelegates = delegates.filter { wv in
                return wv.responds(to: #selector(WKNavigationDelegate.webView(_:didReceive:completionHandler:)))
            }

            guard let firstAuthenticatingDelegate = authenticatingDelegates.first else {
                return completionHandler(URLSession.AuthChallengeDisposition.performDefaultHandling, nil)
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
