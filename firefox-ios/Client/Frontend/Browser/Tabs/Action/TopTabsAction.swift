// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

/// Actions related to top tabs shown on large device layout (i.e. iPad)
struct TopTabsAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
}

enum  TopTabsActionType: ActionType {
    case didTapNewTab
    case didTapCloseTab
}
