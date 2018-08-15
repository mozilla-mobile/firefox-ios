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
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?)
    func tabManager(_ tabManager: TabManager, willAddTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab)
    func tabManager(_ tabManager: TabManager, willRemoveTab tab: Tab)
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab)

    func tabManagerDidRestoreTabs(_ tabManager: TabManager)
    func tabManagerDidAddTabs(_ tabManager: TabManager)
    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?)
}

protocol TabManagerStateDelegate: AnyObject {
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
    fileprivate let tabEventHandlers: [TabEventHandler]
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
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        return configuration
    }()

    // A WKWebViewConfiguration used for private mode tabs
    lazy fileprivate var privateConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WKProcessPool()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !(self.prefs.boolForKey("blockPopups") ?? true)
        // We do this to go against the configuration of the <meta name="viewport">
        // tag to behave the same way as Safari :-(
        configuration.ignoresViewportScaleLimits = true
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        return configuration
    }()

    fileprivate let imageStore: DiskImageStore?

    fileprivate let prefs: Prefs
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

    init(prefs: Prefs, imageStore: DiskImageStore?) {
        assert(Thread.isMainThread)

        self.prefs = prefs
        self.navDelegate = TabManagerNavDelegate()
        self.imageStore = imageStore
        self.tabEventHandlers = TabEventHandlers.create(with: prefs)
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

        preserveTabs()

        assert(tab === selectedTab, "Expected tab is selected")
        selectedTab?.createWebview()
        selectedTab?.lastExecutedTime = Date.now()

        delegates.forEach { $0.get()?.tabManager(self, didSelectedTabChange: tab, previous: previous) }
        if let tab = previous {
            TabEvent.post(.didLoseFocus, for: tab)
        }
        if let tab = selectedTab {
            TabEvent.post(.didGainFocus, for: tab)
            UITextField.appearance().keyboardAppearance = tab.isPrivate ? .dark : .light
        }
    }

    func shouldClearPrivateTabs() -> Bool {
        return prefs.boolForKey("settings.closePrivateTabs") ?? false
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

    @discardableResult func addTabAndSelect(_ request: URLRequest! = nil, configuration: WKWebViewConfiguration! = nil, afterTab: Tab? = nil, isPrivate: Bool = false) -> Tab {
        let tab = addTab(request, configuration: configuration, afterTab: afterTab, isPrivate: isPrivate)
        selectTab(tab)
        return tab
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

    fileprivate func addTab(_ request: URLRequest? = nil, configuration: WKWebViewConfiguration? = nil, afterTab: Tab? = nil, flushToDisk: Bool, zombie: Bool, isPrivate: Bool = false) -> Tab {
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

        delegates.forEach { $0.get()?.tabManager(self, didAddTab: tab) }

        if !zombie {
            tab.createWebview()
        }
        tab.navigationDelegate = self.navDelegate

        if let request = request {
            tab.loadRequest(request)
        } else if !isPopup {
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

    func removeTabAndUpdateSelectedIndex(_ tab: Tab) {
        removeTab(tab, flushToDisk: true, notify: true)
        updateIndexAfterRemovalOf(tab)
        hideNetworkActivitySpinner()
    }

    func updateIndexAfterRemovalOf(_ tab: Tab) {
        let closedLastNormalTab = !tab.isPrivate && normalTabs.isEmpty
        let closedLastPrivateTab = tab.isPrivate && privateTabs.isEmpty

        if closedLastNormalTab {
            addTabAndSelect()
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
            delegates.forEach { $0.get()?.tabManager(self, didRemoveTab: tab) }
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
        recentlyClosedForUndo = tabs.compactMap { tab in
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

        self.isRestoring = true

        restoreInternal(savedTabs: recentlyClosedForUndo, clearPrivateTabs: false)
        recentlyClosedForUndo.removeAll()

        tabs.forEach { tab in
            tab.showContent(true)
        }

        // In non-private mode, delete all tabs will automatically create a tab
        if let tab = tabs.first, !tab.isPrivate {
            removeTabAndUpdateSelectedIndex(tab)
        }

        self.isRestoring = false

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

    @objc func prefsDidChange() {
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
        guard let profilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path else {
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            return URL(fileURLWithPath: documentsPath).appendingPathComponent("tabsState.archive").path
        }

        return URL(fileURLWithPath: profilePath).appendingPathComponent("tabsState.archive").path
    }

    static fileprivate func migrateTabsStateArchive() {
        guard let oldPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("tabsState.archive").path, FileManager.default.fileExists(atPath: oldPath) else {
            return
        }

        log.info("Migrating tabsState.archive from ~/Documents to shared container")

        guard let profilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppInfo.sharedContainerIdentifier)?.appendingPathComponent("profile.profile").path else {
            log.error("Unable to get profile path in shared container to move tabsState.archive")
            return
        }

        let newPath = URL(fileURLWithPath: profilePath).appendingPathComponent("tabsState.archive").path

        do {
            try FileManager.default.createDirectory(atPath: profilePath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.moveItem(atPath: oldPath, toPath: newPath)

            log.info("Migrated tabsState.archive to shared container successfully")
        } catch let error as NSError {
            log.error("Unable to move tabsState.archive to shared container: \(error.localizedDescription)")
        }
    }

    static func tabArchiveData() -> Data? {
        migrateTabsStateArchive()

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

    fileprivate func restoreInternal(savedTabs: [SavedTab], clearPrivateTabs: Bool) {
        guard savedTabs.count > 0 else { return }
        var savedTabs = savedTabs
        // Make sure to wipe the private tabs if the user has the pref turned on
        if clearPrivateTabs {
            savedTabs = savedTabs.filter { !$0.isPrivate }
        }

        var tabToSelect: Tab?
        for savedTab in savedTabs {
            // Provide an empty request to prevent a new tab from loading the home screen
            let tab = self.addTab(nil, configuration: nil, afterTab: nil, flushToDisk: false, zombie: true, isPrivate: savedTab.isPrivate)

            // Since this is a restored tab, reset the URL to be loaded as that will be handled by the SessionRestoreHandler
            tab.url = nil

            if let faviconURL = savedTab.faviconURL {
                let icon = Favicon(url: faviconURL, date: Date())
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
            tabToSelect = tabs.first(where: { $0.isPrivate == false })
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
        defer {
            isRestoring = false

            // Always make sure there is a single normal tab.
            if normalTabs.isEmpty {
                let tab = addTab()
                if selectedTab == nil {
                    selectTab(tab)
                }
            }
        }

        guard let savedTabs = TabManager.tabsToRestore() else {
            return
        }

        if count == 0 && !AppConstants.IsRunningTest && !DebugSettingsBundleOptions.skipSessionRestore {
            // This is wrapped in an Objective-C @try/@catch handler because NSKeyedUnarchiver may throw exceptions which Swift cannot handle
            _ = Try(
                withTry: { () -> Void in
                    self.restoreInternal(savedTabs: savedTabs, clearPrivateTabs: self.shouldClearPrivateTabs())
                },
                catch: { exception in
                    Sentry.shared.send(message: "Failed to restore tabs: ", tag: SentryTag.tabManager, severity: .error, description: "\(exception ??? "nil")")
                }
            )
        }
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
        let isNightMode = NightModeAccessors.isNightMode(self.prefs)
        tab.setNightMode(isNightMode)

        if #available(iOS 11, *) {
            let isNoImageMode = self.prefs.boolForKey(PrefsKeys.KeyNoImageModeStatus) ?? false
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

extension TabManager {
    class func tabRestorationDebugInfo() -> String {
        assert(Thread.isMainThread)

        let tabs = TabManager.tabsToRestore()?.map { $0.jsonDictionary } ?? []
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tabs, options: [.prettyPrinted])
            return String(data: jsonData, encoding: .utf8) ?? ""
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
