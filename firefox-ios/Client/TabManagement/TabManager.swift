// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import TabDataStore

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

    var tabs: [Tab] { get }
    var normalTabs: [Tab] { get }
    var privateTabs: [Tab] { get }

    subscript(webView: WKWebView) -> Tab? { get }

    // MARK: - Add/Remove Delegate
    func addDelegate(_ delegate: TabManagerDelegate)
    func setNavigationDelegate(_ delegate: WKNavigationDelegate)
    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?)

    // MARK: - Select Tab
    /// Selects the given tab as the active tab.
    ///
    /// - Parameters:
    ///   - tab: The tab to select.
    ///   - previous: The tab to treat as the previously selected tab..
    ///   - immediatePreservation: When `true`, tab state is persisted synchronously instead of being deferred.
    func selectTab(_ tab: Tab?, previous: Tab?, immediatePreservation: Bool)

    // MARK: - Add Tab

    /// Add tabs for a list of URLs
    /// - Parameters:
    ///   - urls: The list of URL to create tabs with
    ///   - zombie: Whether the webviews should be created right away or not,
    ///   only set to false if you need to select the tab right away
    ///   - shouldSelectTab: Whether the last tab from the urls added should be selected or not
    ///   - isPrivate: Whether the tabs should be created in private mode or not
    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool)

    /// Add a tab in the tabs array
    /// - Parameters:
    ///   - request: The request created
    ///   - afterTab: Place the new tab after this tab, can be nil to create the tab at the end of the tabs array
    ///   - zombie: Whether the webview should be created right away or not,
    ///   only set to false if you need to select the tab right away
    ///   - isPrivate: whether the tabs should be created in private mode or not
    /// - Returns: The newly created tab
    @discardableResult
    func addTab(_ request: URLRequest?,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool) -> Tab

    // MARK: - Remove tab

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

    // MARK: Get Tab
    func getTabForUUID(uuid: TabUUID) -> Tab?
    func getTabForURL(_ url: URL) -> Tab?

    // MARK: - Window merging

    /// Persists the live session state (back/forward history) of every tab in this window and
    /// returns the serialized tab data, used when merging this window's tabs into another window.
    /// Private tabs are included only when the user's "close private tabs" setting is disabled,
    /// matching the behaviour applied when the window would otherwise be closed.
    /// - Returns: the tab data for every tab that should move to the destination window.
    func tabDataForWindowMerge() -> [TabData]

    /// Appends tabs from other windows' merged data into this window. The tabs are created as
    /// zombies (no webview until selected) and keep their original UUIDs, so their history is
    /// restored from the tab session store on selection. Tabs whose UUID already exists are skipped.
    /// - Parameter tabDataList: the tab data collected from the other windows being merged.
    func addTabs(fromWindowMergeData tabDataList: [TabData])

    // MARK: Other Tab Actions
    func clearAllTabsHistory()
    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int)
    /// Persists the current tab state to disk.
    ///
    /// Should only be called after tab restore has finished. When `immediate` is `true`,
    /// the save is forced synchronously — use this for time-sensitive cases such as
    /// backgrounding the app or switching to another app. When `false`, the save may
    /// be deferred, suitable for llower-priority updates such as opening, closing,
    /// or switching between tabs during normal browsing.
    ///
    /// - Parameter immediate: Whether the tab data should be saved immediately (`true`)
    ///   or can be deferred (`false`).
    func preserveTabs(immediate: Bool)

    /// Commits the pending changes to the persistent store.
    func commitChanges()

    func notifyCurrentTabDidFinishLoading()

    func restoreTabs()

    func expireLoginAlerts()

    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab
    func tabDidSetScreenshot(_ tab: Tab)
    func offloadBackgroundWebViews() async

    /// ADR 0008: load `tab`'s screenshot from disk if it isn't already in memory. Intended for
    /// just-in-time loading driven by the tab tray's prefetch data source. No-op if the tab
    /// already has a screenshot.
    func restoreScreenshot(for tab: Tab)
}

extension TabManager {
    func selectTab(_ tab: Tab?, previous: Tab? = nil, immediatePreservation: Bool = false) {
        selectTab(tab, previous: previous, immediatePreservation: immediatePreservation)
    }

    func preserveTabs(immediate: Bool = false) {
        preserveTabs(immediate: immediate)
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
