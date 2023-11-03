// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabTrayState {
    var tabs: [String]
    var isPrivateMode: Bool

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded = true

    var isPrivateTabsEmpty: Bool {
        return isPrivateMode && tabs.isEmpty
    }

    // For test and mock purposes will be deleted once Redux is integrated
    static func getMockState(isPrivateMode: Bool) -> TabTrayState {
        let tabs = ["Tab1",
                    "Tab2",
                    "Tab3",
                    "Tab4",
                    "Tab5"]
        return TabTrayState(tabs: tabs,
                            isPrivateMode: isPrivateMode,
                            inactiveTabs: tabs)
    }
}
