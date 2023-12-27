// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The filtered jumpBack in list to display to the user.
/// Only one group is displayed
struct JumpBackInList {
    let tabs: [Tab]
    var itemsToDisplay: Int {
        return tabs.count
    }
}
