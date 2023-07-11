// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Storage
import Shared

// MARK: - TabManager protocol
protocol TabManager: AnyObject {
    var delaySelectingNewPopupTab: TimeInterval { get }
    var recentlyAccessedNormalTabs: [Tab] { get }
    var tabs: [Tab] { get }
    var count: Int { get }
    var selectedTab: Tab? { get }
    var backupCloseTab: BackupCloseTab? { get set }
    var normalTabs: [Tab] { get }
    var normalActiveTabs: [Tab] { get }
    var inactiveTabs: [Tab] { get }
    var privateTabs: [Tab] { get }
    var tabDisplayType: TabDisplayType { get set }
    subscript(index: Int) -> Tab? { get }
    subscript(webView: WKWebView) -> Tab? { get }

    func addDelegate(_ delegate: TabManagerDelegate)
    func addNavigationDelegate(_ delegate: WKNavigationDelegate)
    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?)
    func selectTab(_ tab: Tab?, previous: Tab?)
    func addTab(_ request: URLRequest?, afterTab: Tab?, isPrivate: Bool) -> Tab
    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool)
    func removeTab(_ tab: Tab, completion: (() -> Void)?)
    func removeTabs(_ tabs: [Tab])
    func undoCloseTab(tab: Tab, position: Int?)
    func getMostRecentHomepageTab() -> Tab?
    func getTabFor(_ url: URL) -> Tab?
    func clearAllTabsHistory()
    func willSwitchTabMode(leavingPBM: Bool)
    func cleanupClosedTabs(_ closedTabs: [Tab], previous: Tab?, isPrivate: Bool)
    func moveTab(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int)
    func preserveTabs()
    func restoreTabs(_ forced: Bool)
    func startAtHomeCheck()
    func hasTabsToRestoreAtStartup() -> Bool
    func getTabForUUID(uuid: String) -> Tab?
    func getTabForURL(_ url: URL) -> Tab?
    func expireSnackbars()
    func switchPrivacyMode() -> SwitchPrivacyModeResult
    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab
    func makeToastFromRecentlyClosedUrls(_ recentlyClosedTabs: [Tab],
                                         isPrivate: Bool,
                                         previousTabUUID: String)
    @discardableResult
    func addTab(_ request: URLRequest!,
                configuration: WKWebViewConfiguration!,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool) -> Tab
    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void)
    func testRemoveAll()
    func testClearArchive()
}

extension TabManager {
    func removeDelegate(_ delegate: TabManagerDelegate) {
        removeDelegate(delegate, completion: nil)
    }

    func selectTab(_ tab: Tab?) {
        selectTab(tab, previous: nil)
    }

    func removeTab(_ tab: Tab) {
        removeTab(tab) {
            NotificationCenter.default.post(name: .UpdateLabelOnTabClosed, object: nil)
        }
    }

    func restoreTabs(_ forced: Bool = false) {
        restoreTabs(forced)
    }

    func cleanupClosedTabs(_ closedTabs: [Tab],
                           previous: Tab?,
                           isPrivate: Bool = false) {
        cleanupClosedTabs(closedTabs,
                          previous: previous,
                          isPrivate: isPrivate)
    }

    @discardableResult
    func addTab(_ request: URLRequest! = nil,
                configuration: WKWebViewConfiguration! = nil,
                afterTab: Tab? = nil,
                zombie: Bool = false,
                isPrivate: Bool = false
    ) -> Tab {
        addTab(request,
               configuration: configuration,
               afterTab: afterTab,
               zombie: zombie,
               isPrivate: isPrivate)
    }

    func backgroundRemoveAllTabs(isPrivate: Bool = false,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void) {
        backgroundRemoveAllTabs(isPrivate: isPrivate,
                                didClearTabs: didClearTabs)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool = true) {
        addTabsForURLs(urls, zombie: zombie, shouldSelectTab: shouldSelectTab)
    }
}
