// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct StartAtHomeAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let shouldStartAtHome: Bool?
    let tabManager: TabManager?

    init(
        shouldStartAtHome: Bool? = nil,
        tabManager: TabManager? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.shouldStartAtHome = shouldStartAtHome
        self.tabManager = tabManager
    }
}

enum StartAtHomeActionType: ActionType {
    case didBrowserBecomeActive
}

enum StartAtHomeMiddlewareActionType: ActionType {
    case startAtHomeCheckCompleted
}
