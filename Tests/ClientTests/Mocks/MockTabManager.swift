// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

@testable import Client

class MockTabManager: TabManager {
    var selectedTab: Tab?
    var backupCloseTab: Client.BackupCloseTab?

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
        let configuration = WKWebViewConfiguration()
        let profile = MockProfile()
        let tab = Tab(profile: profile, configuration: configuration, isPrivate: isPrivate)
        tabs.append(tab)
        return tab
    }

    func getMostRecentHomepageTab() -> Tab? {
        return addTab(nil, afterTab: nil, isPrivate: false)
    }

    func addDelegate(_ delegate: TabManagerDelegate) {}

    func addNavigationDelegate(_ delegate: WKNavigationDelegate) {}

    func removeDelegate(_ delegate: TabManagerDelegate, completion: (() -> Void)?) {}

    func addTabsForURLs(_ urls: [URL], zombie: Bool, shouldSelectTab: Bool) {}

    func reAddTabs(tabsToAdd: [Tab], previousTabUUID: String) {}

    func removeTab(_ tab: Tab, completion: (() -> Void)?) {}

    func removeTabs(_ tabs: [Tab]) {}

    func undoCloseTab(tab: Client.Tab, position: Int?) {}

    func getTabFor(_ url: URL) -> Tab? {
        return nil
    }

    func clearAllTabsHistory() {}

    func willSwitchTabMode(leavingPBM: Bool) {}

    func cleanupClosedTabs(_ closedTabs: [Tab], previous: Tab?, isPrivate: Bool) {}

    func moveTab(isPrivate privateMode: Bool, fromIndex visibleFromIndex: Int, toIndex visibleToIndex: Int) {}

    func preserveTabs() {}

    func restoreTabs(_ forced: Bool) {}

    func startAtHomeCheck() {}

    func hasTabsToRestoreAtStartup() -> Bool {
        return false
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
        return Tab(profile: MockProfile(), configuration: WKWebViewConfiguration())
    }

    func makeToastFromRecentlyClosedUrls(_ recentlyClosedTabs: [Tab],
                                         isPrivate: Bool,
                                         previousTabUUID: String) {}

    @discardableResult
    func addTab(_ request: URLRequest!,
                configuration: WKWebViewConfiguration!,
                afterTab: Tab?,
                zombie: Bool,
                isPrivate: Bool
    ) -> Tab {
        return Tab(profile: MockProfile(), configuration: WKWebViewConfiguration())
    }

    func backgroundRemoveAllTabs(isPrivate: Bool,
                                 didClearTabs: @escaping (_ tabsToRemove: [Tab],
                                                          _ isPrivate: Bool,
                                                          _ previousTabUUID: String) -> Void) {}

    func testRemoveAll() {}

    func testClearArchive() {}
}
