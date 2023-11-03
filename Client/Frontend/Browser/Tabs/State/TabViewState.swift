// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabViewState {
    var isPrivateMode: Bool
    var tabs: [TabCellState]

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded = true

    var isPrivateTabsEmpty: Bool {
        return isPrivateMode && tabs.isEmpty
    }

    // For test and mock purposes will be deleted once Redux is integrated
    static func getMockState(isPrivateMode: Bool) -> TabViewState {
        var tabs = [TabCellState]()

        for index in 0...4 {
            let cellState = TabCellState.emptyTabState(title: "Tab \(index)")
            tabs.append(cellState)
        }
        return TabViewState(isPrivateMode: isPrivateMode,
                            tabs: tabs,
                            inactiveTabs: ["Tab1",
                                           "Tab2",
                                           "Tab3"])
    }
}
