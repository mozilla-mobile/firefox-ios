// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

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
}
