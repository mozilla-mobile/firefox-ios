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
    var selectedTab: Tab?
    var backupCloseTab: BackupCloseTab?
    var backupCloseTabs = [Tab]()

    var nextRecentlyAccessedNormalTabs = [Tab]()

    var recentlyAccessedNormalTabs: [Tab] {
        return nextRecentlyAccessedNormalTabs
    }

    var tabs = [Tab]()

    var lastSelectedTabs = [Tab]()
    var lastSelectedPreviousTabs = [Tab]()

    var delaySelectingNewPopupTab: TimeInterval = 0
    var count: Int = 0
    var normalTabs = [Tab]()
    var normalActiveTabs = [Tab]()
    var inactiveTabs = [Tab]()
    var privateTabs = [Tab]()
    var tabDisplayType: TabDisplayType = .TabGrid

    var addTabsForURLsCalled = 0
    var addTabsURLs: [URL] = []

    var removeTabsByURLCalled = 0

    init(windowUUID: WindowUUID = WindowUUID.XCTestDefaultUUID) {
        self.windowUUID = windowUUID
    }

    subscript(index: Int) -> Tab? {
        return nil
    }

    subscript(webView: WKWebView) -> Tab? {
        return nil
    }

    func selectTab(_ tab: Tab?, previous: Tab?) {
        if let tab = tab {
            lastSelectedTabs.append(tab)
        }

        if let previous = previous {
            lastSelectedPreviousTabs.append(previous)
        }
    }

    func addTab(_ request: URLRequest?, afterTab: Tab?, isPrivate: Bool) -> Tab {
        let profile = MockProfile()
        let tab = Tab(profile: profile, isPrivate: isPrivate, windowUUID: windowUUID)
        tabs.append(tab)
        return tab
    }

    func getMostRecentHomepageTab() -> Tab? {
        return addTab(nil, afterTab: nil, isPrivate: false)
    }

    func addDelegate(_ delegate: TabManagerDelegate) {}

    func addNavigationDelegate(_ delegate: WKNavigationDelegate) {}

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?) {}

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool) {
        addTabsForURLsCalled += 1
        addTabsURLs = urls
    }

    func reAddTabs(tabsToAdd: [Tab], previousTabUUID: String) {}

    func removeTab(_ tab: Tab, completion: (() -> Void)?) {}

    func removeTabs(_ tabs: [Tab]) {}

    func removeTab(_ tabUUID: String) async {}

    func removeAllTabs(isPrivateMode: Bool) async {}

    func removeTabs(by urls: [URL]) async {
        removeTabsByURLCalled += 1
    }

    func undoCloseAllTabs() {}

    func undoCloseTab() {}

    func getTabFor(_ url: URL) -> Tab? {
        return nil
    }

    func clearAllTabsHistory() {}

    func willSwitchTabMode(leavingPBM: Bool) {}

    func cleanupClosedTabs(_ closedTabs: [Tab], previous: Tab?, isPrivate: Bool) {}

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

    func expireSnackbars() {}

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
    func addTab(_ request: URLRequest!,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool
    ) -> Tab {
        return Tab(profile: MockProfile(), windowUUID: windowUUID)
    }

    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void) {}

    // MARK: - Inactive tabs
    func getInactiveTabs() -> [Tab] {
        return inactiveTabs
    }

    func removeAllInactiveTabs() async {}

    func undoCloseInactiveTabs() {}
}
