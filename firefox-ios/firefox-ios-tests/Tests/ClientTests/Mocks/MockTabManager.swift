// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common
import XCTest

@testable import Client

class MockTabManager: TabManager {
    let windowUUID: WindowUUID
    var isRestoringTabs = false
    var tabRestoreHasFinished = false
    var selectedIndex = 0
    var selectedTab: Tab?
    var selectedTabUUID: UUID?
    var backupCloseTab: BackupCloseTab?
    var backupCloseTabs = [Tab]()

    var recentlyAccessedNormalTabs = [Tab]()

    var tabs = [Tab]()

    var lastSelectedTabs = [Tab]()
    var lastSelectedPreviousTabs = [Tab]()

    var count = 0
    var normalTabs = [Tab]()
    var privateTabs = [Tab]()

    var addTabsForURLsCalled = 0
    var addTabsURLs: [URL] = []

    var removeTabsByURLCalled = 0

    var addTabWasCalled = false
    var notifyCurrentTabDidFinishLoadingCalled = 0
    var commitChangesCalled = 0
    var selectTabExpectation: XCTestExpectation?

    nonisolated init(
        windowUUID: WindowUUID = WindowUUID.XCTestDefaultUUID
    ) {
        self.windowUUID = windowUUID
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

        selectTabExpectation?.fulfill()
    }

    func addDelegate(_ delegate: TabManagerDelegate) {}

    func setNavigationDelegate(_ delegate: WKNavigationDelegate) {}

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?) {}

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool, isPrivate: Bool) {
        addTabsForURLsCalled += 1
        addTabsURLs = urls
    }

    func reAddTabs(tabsToAdd: [Tab], previousTabUUID: String) {}

    func removeTabs(_ tabs: [Tab]) {}

    func removeTab(_ tabUUID: TabUUID) {}

    func removeAllTabs(isPrivateMode: Bool) {}

    func removeTabs(by urls: [URL]) {
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

    func restoreTabs() {}

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
        let isHomePage = request?.url?.absoluteString == "internal://local/about/home"
        return MockTab(profile: MockProfile(), isPrivate: isPrivate, windowUUID: windowUUID, isHomePage: isHomePage)
    }

    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void) {}

    func findRightOrLeftTab(forRemovedTab removedTab: Tab, withDeletedIndex deletedIndex: Int) -> Tab? {
        return nil
    }

    func notifyCurrentTabDidFinishLoading() {
        notifyCurrentTabDidFinishLoadingCalled += 1
    }

    func tabDidSetScreenshot(_ tab: Client.Tab) {}
}
