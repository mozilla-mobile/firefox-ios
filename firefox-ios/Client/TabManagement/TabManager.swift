// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

enum TabManagerConstants {
    static let tabScreenshotNamespace = "TabManagerScreenshots"
}

// MARK: - TabManager protocol
protocol TabManager: AnyObject {
    var windowUUID: WindowUUID { get }
    var isRestoringTabs: Bool { get }
    var delaySelectingNewPopupTab: TimeInterval { get }
    var recentlyAccessedNormalTabs: [Tab] { get }
    var count: Int { get }

    var selectedTab: Tab? { get }
    var backupCloseTab: BackupCloseTab? { get set }

    var tabs: [Tab] { get }
    var normalTabs: [Tab] { get } // Includes active and inactive tabs
    var normalActiveTabs: [Tab] { get }
    var inactiveTabs: [Tab] { get }
    var privateTabs: [Tab] { get }

    subscript(index: Int) -> Tab? { get }
    subscript(webView: WKWebView) -> Tab? { get }

    // MARK: - Add/Remove Delegate
    func addDelegate(_ delegate: TabManagerDelegate)
    func addNavigationDelegate(_ delegate: WKNavigationDelegate)
    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?)

    // MARK: - Select Tab
    func selectTab(_ tab: Tab?, previous: Tab?)

    // MARK: - Add Tab
    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool)
    @discardableResult
    func addTab(_ request: URLRequest?,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool) -> Tab

    // MARK: - Remove Tab
    // TODO: FXIOS-11272 Remove this function in favor of the async remove tab.
    /// GCD remove tab option using tabUUID with completion
    /// - Parameters:
    ///   - tabUUID: UUID from the tab
    ///   - completion: closure called after remove tab completes on main thread
    func removeTabWithCompletion(_ tabUUID: TabUUID, completion: (() -> Void)?)

    /// Async Remove tab option using tabUUID.
    /// - Parameter tabUUID: UUID from the tab
    func removeTab(_ tabUUID: TabUUID) async

    /// Async Remove all tabs indicating if is on private mode or not
    /// - Parameter isPrivateMode: Is private mode enabled or not
    func removeAllTabs(isPrivateMode: Bool) async

    /// Removes all tabs matching the urls, used when other clients request to close tabs on this device.
    func removeTabs(by urls: [URL]) async
    func removeTabs(_ tabs: [Tab])

    // MARK: - Undo Close
    func undoCloseTab()
    /// Undo close all tabs, it will restore the tabs that were backed up when the close action was called.
    func undoCloseAllTabs()

    // MARK: Inactive Tabs

    /// Get inactive tabs from the list of tabs based on the time condition to be considered inactive.
    /// Replaces LegacyInactiveTabModel and related classes
    ///
    /// - Returns: Return list of tabs considered inactive
    func getInactiveTabs() -> [Tab]

    /// Async Remove all inactive tabs, used when user closes all inactive tabs
    func removeAllInactiveTabs() async

    /// Undo all inactive tabs closure. All inactive tabs are added back to the list of tabs
    func undoCloseInactiveTabs() async

    // MARK: Get Tab
    func getTabForUUID(uuid: TabUUID) -> Tab?
    func getTabForURL(_ url: URL) -> Tab?
    func getMostRecentHomepageTab() -> Tab?

    // MARK: Other Tab Actions
    func clearAllTabsHistory()
    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int)
    func preserveTabs()
    func restoreTabs(_ forced: Bool)
    func startAtHomeCheck() -> Bool
    func expireLoginAlerts()
    @discardableResult
    func switchPrivacyMode() -> SwitchPrivacyModeResult
    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab
}

extension TabManager {
    func selectTab(_ tab: Tab?) {
        selectTab(tab, previous: nil)
    }

    func restoreTabs(_ forced: Bool = false) {
        restoreTabs(forced)
    }

    @discardableResult
    func addTab(_ request: URLRequest? = nil,
                afterTab: Tab? = nil,
                zombie: Bool = false,
                isPrivate: Bool = false
    ) -> Tab {
        addTab(request,
               afterTab: afterTab,
               zombie: zombie,
               isPrivate: isPrivate)
    }

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool = true, isPrivate: Bool = false) {
        addTabsForURLs(urls, zombie: zombie, shouldSelectTab: shouldSelectTab, isPrivate: isPrivate)
    }
}
