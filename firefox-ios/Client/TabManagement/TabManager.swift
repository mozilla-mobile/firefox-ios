// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

enum TabManagerConstants {
    static let tabScreenshotNamespace = "TabManagerScreenshots"
}

enum TabsDeletionPeriod: String {
    case oneDay, oneWeek, oneMonth
}

// MARK: - TabManager protocol
@MainActor
protocol TabManager: AnyObject {
    nonisolated var windowUUID: WindowUUID { get }
    var isRestoringTabs: Bool { get }
    var tabRestoreHasFinished: Bool { get }
    var recentlyAccessedNormalTabs: [Tab] { get }

    var selectedTab: Tab? { get }
    var backupCloseTab: BackupCloseTab? { get set }

    var tabs: [Tab] { get }
    var normalTabs: [Tab] { get }
    var privateTabs: [Tab] { get }

    subscript(webView: WKWebView) -> Tab? { get }

    // MARK: - Add/Remove Delegate
    func addDelegate(_ delegate: TabManagerDelegate)
    func setNavigationDelegate(_ delegate: WKNavigationDelegate)
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

    /// Remove tab option using tabUUID.
    /// - Parameter tabUUID: UUID from the tab
    func removeTab(_ tabUUID: TabUUID)

    /// Remove all tabs indicating if is on private mode or not
    /// - Parameter isPrivateMode: Is private mode enabled or not
    func removeAllTabs(isPrivateMode: Bool)

    /// Removes all tabs matching the urls, used when other clients request to close tabs on this device.
    func removeTabs(by urls: [URL])
    func removeTabs(_ tabs: [Tab])

    /// Remove normal tabs older than a certain period of time
    func removeNormalTabsOlderThan(period: TabsDeletionPeriod, currentDate: Date)

    // MARK: - Undo Close
    func undoCloseTab()
    /// Undo close all tabs, it will restore the tabs that were backed up when the close action was called.
    func undoCloseAllTabs()

    // MARK: Get Tab
    func getTabForUUID(uuid: TabUUID) -> Tab?
    func getTabForURL(_ url: URL) -> Tab?

    // MARK: Other Tab Actions
    func clearAllTabsHistory()
    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int)
    func preserveTabs()

    /// Commits the pending changes to the persistent store.
    func commitChanges()

    func notifyCurrentTabDidFinishLoading()

    func restoreTabs()

    func expireLoginAlerts()
    @discardableResult

    func switchPrivacyMode() -> SwitchPrivacyModeResult

    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab
    func tabDidSetScreenshot(_ tab: Tab)
}

extension TabManager {
    func selectTab(_ tab: Tab?, previous: Tab? = nil) {
        selectTab(tab, previous: previous)
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
