// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TabManagerAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let recentTabs: [Tab]?

    init(
        recentTabs: [Tab]? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.recentTabs = recentTabs
    }
}

enum TabManagerMiddlewareActionType: ActionType {
    case fetchedRecentTabs
}
