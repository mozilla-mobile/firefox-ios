// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class StartAtHomeAction: Action {
    let shouldStartAtHome: Bool?
    init(
        shouldStartAtHome: Bool? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.shouldStartAtHome = shouldStartAtHome
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum StartAtHomeActionType: ActionType {
    case didBrowserBecomeActive
}

enum StartAtHomeMiddlewareActionType: ActionType {
    case startAtHomeCheckCompleted
}
