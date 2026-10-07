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
    /// Whether the entry point glow still has to run, as decided by `QuickAnswersMiddleware`.
    let shouldShowGlow: Bool

    init(isQuickAnswersEnabled: Bool? = nil,
         shouldShowGlow: Bool = false,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isQuickAnswersEnabled = isQuickAnswersEnabled
        self.shouldShowGlow = shouldShowGlow
    }
}

enum QuickAnswersActionType: ActionType {
    case didSettingsChange
    /// The entry point started glowing, so the glow has to be counted towards its display cap.
    case didShowGlow
}

enum QuickAnswersMiddlewareActionType: ActionType {
    case didInitialize
    case didUpdateSettings
}
