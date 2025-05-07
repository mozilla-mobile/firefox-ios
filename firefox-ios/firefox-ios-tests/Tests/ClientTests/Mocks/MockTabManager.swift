// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

@testable import Client

class MockTabManager: TabManager {
    let windowUUID: WindowUUID
    var isRestoringTabs = false
    var selectedIndex = 0
    var selectedTab: Tab?
    var selectedTabUUID: UUID?
    var backupCloseTab: BackupCloseTab?
    var backupCloseTabs = [Tab]()

    var recentlyAccessedNormalTabs: [Tab]

    var tabs = [Tab]()

    var lastSelectedTabs = [Tab]()
    var lastSelectedPreviousTabs = [Tab]()

    var delaySelectingNewPopupTab: TimeInterval = 0
    var count = 0
    var normalTabs = [Tab]()
    var normalActiveTabs = [Tab]()
    var inactiveTabs = [Tab]()
    var privateTabs = [Tab]()

    var addTabsForURLsCalled = 0
    var addTabsURLs: [URL] = []

    var removeTabsByURLCalled = 0

    var addTabWasCalled = false
    var notifyCurrentTabDidFinishLoadingCalled = 0
    var commitChangesCalled = 0

    init(
        windowUUID: WindowUUID = WindowUUID.XCTestDefaultUUID,
        recentlyAccessedNormalTabs: [Tab] = [Tab]()
    ) {
        self.windowUUID = windowUUID
        self.recentlyAccessedNormalTabs = recentlyAccessedNormalTabs
    }

    subscript(index: Int) -> Tab? {
        return tabs[index]
    }

    subscript(webView: WKWebView) -> Tab? {
        return tabs.first {
            $0.webView === webView
        }
    }

    func selectTab(_ tab: Tab?, previous: Tab?) {
        if let tab = tab {
            lastSelectedTabs.append(tab)
            selectedTab = tab
        }

        if let previous = previous {
            lastSelectedPreviousTabs.append(previous)
        }
    }

    func getMostRecentHomepageTab() -> Tab? {
        return addTab(nil, afterTab: nil, isPrivate: false)
    }

    func addDelegate(_ delegate: TabManagerDelegate) {}

    func setNavigationDelegate(_ delegate: WKNavigationDelegate) {}

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?) {}

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool) {
        addTabsForURLsCalled += 1
        addTabsURLs = urls
    }

    func reAddTabs(tabsToAdd: [Tab], previousTabUUID: String) {}

    func removeTabWithCompletion(_ tabUUID: TabUUID, completion: (() -> Void)?) {}

    func removeTabs(_ tabs: [Tab]) {}

    func removeTab(_ tabUUID: TabUUID) async {}

    func removeAllTabs(isPrivateMode: Bool) async {}

    func removeTabs(by urls: [URL]) async {
        removeTabsByURLCalled += 1
    }

    func removeNormalTabsOlderThan(period: TabsDeletionPeriod, currentDate: Date) {}

    func undoCloseAllTabs() {}

    func undoCloseTab() {}

    func clearAllTabsHistory() {}

    func commitChanges() {
        commitChangesCalled += 1
    }

    func willSwitchTabMode(leavingPBM: Bool) {}

    func reorderTabs(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {}

    func preserveTabs() {}

    func restoreTabs(_ forced: Bool) {}

    func startAtHomeCheck() -> Bool {
        false
    }

    func getTabForUUID(uuid: String) -> Tab? {
        return nil
    }

    func getTabForURL(_ url: URL) -> Tab? {
        return nil
    }

    func expireLoginAlerts() {}

    func switchPrivacyMode() -> SwitchPrivacyModeResult {
        return .createdNewTab
    }

    func addPopupForParentTab(profile: Profile, parentTab: Tab, configuration: WKWebViewConfiguration) -> Tab {
        return Tab(profile: MockProfile(), windowUUID: windowUUID)
    }

    func makeToastFromRecentlyClosedUrls(_ recentlyClosedTabs: [Tab],
                                         isPrivate: Bool,
                                         previousTabUUID: String) {}

    func undoCloseAllTabsLegacy(recentlyClosedTabs: [Client.Tab], previousTabUUID: String, isPrivate: Bool) {}

    @discardableResult
    func addTab(_ request: URLRequest?,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool
    ) -> Tab {
        addTabWasCalled = true
        return Tab(profile: MockProfile(), isPrivate: isPrivate, windowUUID: windowUUID)
    }

    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void) {}

    func findRightOrLeftTab(forRemovedTab removedTab: Tab, withDeletedIndex deletedIndex: Int) -> Tab? {
        return nil
    }

    // MARK: - Inactive tabs
    func getInactiveTabs() -> [Tab] {
        return inactiveTabs
    }

    func removeAllInactiveTabs() async {}

    func undoCloseInactiveTabs() async {}

    func notifyCurrentTabDidFinishLoading() {
        notifyCurrentTabDidFinishLoadingCalled += 1
    }

    func tabDidSetScreenshot(_ tab: Client.Tab) {}
}
