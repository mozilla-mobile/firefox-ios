// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

///Although it's bare bones now, we should keep this in place for when we generalize this VM and VC later.

import Foundation
import Storage

class GroupedHistoryItemsViewModel {

    // MARK: - Properties

    var asGroup: ASGroup<Site>

    // UI
    let notifications = [Notification.Name.DisplayThemeChanged]

    // MARK: - Inits

    init(asGroup: ASGroup<Site>) {
        self.asGroup = asGroup
    }

    // MARK: - Lifecycles

    // MARK: - Misc helpers

}
