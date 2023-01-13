// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

@testable import Client

class MockTabManager: TabManagerProtocol {
    var selectedTab: Tab?

    var nextRecentlyAccessedNormalTabs = [Tab]()

    var recentlyAccessedNormalTabs: [Tab] {
        return nextRecentlyAccessedNormalTabs
    }

    var tabs = [Tab]()

    var lastSelectedTabs = [Tab]()
    var lastSelectedPreviousTabs = [Tab]()

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
}
