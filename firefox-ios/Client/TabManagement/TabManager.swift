// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Storage
import Shared

enum TabManagerConstants {
    static let tabScreenshotNamespace = "TabManagerScreenshots"
}

// MARK: - TabManager protocol
protocol TabManager: AnyObject {
    var windowUUID: WindowUUID { get }
    var isRestoringTabs: Bool { get }
    var delaySelectingNewPopupTab: TimeInterval { get }
    var recentlyAccessedNormalTabs: [Tab] { get }
    var tabs: [Tab] { get }
    var count: Int { get }
    var selectedTab: Tab? { get }
    var selectedTabUUID: UUID? { get }
    var backupCloseTab: BackupCloseTab? { get set }
    var backupCloseTabs: [Tab] { get set }
    var normalTabs: [Tab] { get } // Includes active and inactive tabs
    var normalActiveTabs: [Tab] { get }
    var normalInactiveTabs: [Tab] { get }
    var privateTabs: [Tab] { get }
    var tabDisplayType: TabDisplayType { get set }
    subscript(index: Int) -> Tab? { get }
    subscript(webView: WKWebView) -> Tab? { get }

    func addDelegate(_ delegate: TabManagerDelegate)
    func addNavigationDelegate(_ delegate: WKNavigationDelegate)
    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?)
    func selectTab(_ tab: Tab?, previous: Tab?)
    func addTab(_ request: URLRequest?, afterTab: Tab?, isPrivate: Bool) -> Tab
    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool)
    func removeTab(_ tab: Tab, completion: (() -> Void)?)
    func removeTabs(_ tabs: [Tab])
    func undoCloseTab()
    func getMostRecentHomepageTab() -> Tab?
    func getTabFor(_ url: URL) -> Tab?
    func clearAllTabsHistory()
    func willSwitchTabMode(leavingPBM: Bool)
    func cleanupClosedTabs(_ closedTabs: [Tab], previous: Tab?, isPrivate: Bool)
    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int)
    func preserveTabs()
    func restoreTabs(_ forced: Bool)
    func startAtHomeCheck() -> Bool
    func getTabForUUID(uuid: TabUUID) -> Tab?
    func getTabForURL(_ url: URL) -> Tab?
    func expireSnackbars()
    @discardableResult
    func switchPrivacyMode() -> SwitchPrivacyModeResult
    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab
    func makeToastFromRecentlyClosedUrls(_ recentlyClosedTabs: [Tab],
                                         isPrivate: Bool,
                                         previousTabUUID: TabUUID)
    func undoCloseAllTabsLegacy(recentlyClosedTabs: [Tab], previousTabUUID: TabUUID, isPrivate: Bool)

    @discardableResult
    func addTab(_ request: URLRequest!,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool) -> Tab
    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void)
    // MARK: TabTray refactor interfaces

    /// Async Remove tab option using tabUUID. Replaces direct usage of removeTab where the whole Tab is needed
    /// - Parameter tabUUID: UUID from the tab
    func removeTab(_ tabUUID: TabUUID) async

    /// Async Remove all tabs indicating if is on private mode or not
    /// - Parameter isPrivateMode: Is private mode enabled or not
    func removeAllTabs(isPrivateMode: Bool) async

    /// Undo close all tabs, it will restore the tabs that were backed up when the close action was called.
    func undoCloseAllTabs()

    /// Removes all tabs matching the urls, used when other clients request to close tabs on this device.
    func removeTabs(by urls: [URL]) async

    /// Get inactive tabs from the list of tabs based on the time condition to be considered inactive.
    /// Replaces LegacyInactiveTabModel and related classes
    /// 
    /// - Returns: Return list of tabs considered inactive
    func getInactiveTabs() -> [Tab]

    /// Async Remove all inactive tabs, used when user closes all inactive tabs and TabTrayFlagManager is enabled
    func removeAllInactiveTabs() async

    /// Undo all inactive tabs closure. All inactive tabs are added back to the list of tabs
    func undoCloseInactiveTabs()
}

extension TabManager {
    func removeDelegate(_ delegate: TabManagerDelegate) {
        removeDelegate(delegate, completion: nil)
    }

    func selectTab(_ tab: Tab?) {
        selectTab(tab, previous: nil)
    }

    func removeTab(_ tab: Tab) {
        let uuid = windowUUID
        removeTab(tab) {
            NotificationCenter.default.post(name: .UpdateLabelOnTabClosed,
                                            object: nil,
                                            userInfo: uuid.userInfo)
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
                afterTab: Tab? = nil,
                zombie: Bool = false,
                isPrivate: Bool = false
    ) -> Tab {
        addTab(request,
               afterTab: afterTab,
               zombie: zombie,
               isPrivate: isPrivate)
    }

    func backgroundRemoveAllTabs(isPrivate: Bool = false,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: TabUUID) -> Void) {
        backgroundRemoveAllTabs(isPrivate: isPrivate,
                                didClearTabs: didClearTabs)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool = true, isPrivate: Bool = false) {
        addTabsForURLs(urls, zombie: zombie, shouldSelectTab: shouldSelectTab, isPrivate: isPrivate)
    }
}
