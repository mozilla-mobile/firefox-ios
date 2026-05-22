// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct QuickAnswersAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isSettingOn: Bool?

    init(isSettingOn: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType
    ) {
        self.isSettingOn = isSettingOn
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

struct QuickAnswersMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isQuickAnswersEnabled: Bool?

    init(isQuickAnswersEnabled: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isQuickAnswersEnabled = isQuickAnswersEnabled
    }
}

enum QuickAnswersActionType: ActionType {
    case didSettingsChange
}

enum QuickAnswersMiddlewareActionType: ActionType {
    case didInitialize
    case didUpdateSettings
}
