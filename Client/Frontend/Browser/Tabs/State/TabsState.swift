// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabsState: Equatable {
    var isPrivateMode: Bool
    var tabs: [TabCellState]
    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return false }
        return tabs.isEmpty
    }

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded: Bool

    init() {
        self.init(isPrivateMode: false,
                  tabs: [TabCellState](),
                  inactiveTabs: [String](),
                  isInactiveTabsExpanded: false)
    }

    init(isPrivateMode: Bool,
         tabs: [TabCellState],
         inactiveTabs: [String],
         isInactiveTabsExpanded: Bool) {
        self.isPrivateMode = isPrivateMode
        self.tabs = tabs
        self.inactiveTabs = inactiveTabs
        self.isInactiveTabsExpanded = isInactiveTabsExpanded
    }
}
