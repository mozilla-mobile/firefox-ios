// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import WebKit

struct SummarizeAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType

    init(
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

enum SummarizeMiddlewareActionType: ActionType {
    case configuredSummarizer
}
