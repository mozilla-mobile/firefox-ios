// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct TabTrayState {
    var tabs = ["Tab1",
                "Tab2",
                "Tab3",
                "Tab4",
                "Tab5"]
    var isPrivateMode: Bool
    var isPrivateTabsEmpty: Bool

    // MARK: Inactive tabs
    var isInactiveTabEmpty: Bool
    var isInactiveTabsExpanded = false
    var inactiveTabs = ["One",
                        "Two",
                        "Three",
                        "Four",
                        "Five",
                        "Six"]

}
