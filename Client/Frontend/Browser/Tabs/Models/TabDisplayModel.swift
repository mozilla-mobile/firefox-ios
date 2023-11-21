// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabDisplayModel: Equatable {
    var isPrivateMode: Bool
    var tabs: [TabCellModel]
    var isPrivateTabsEmpty: Bool {
        guard isPrivateMode else { return false }
        return tabs.isEmpty
    }

    // MARK: Inactive tabs
    var inactiveTabs: [String]
    var isInactiveTabsExpanded: Bool
}
