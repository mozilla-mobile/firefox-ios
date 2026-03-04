// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

enum PrivateLockActionType: ActionType {
    case enteredPrivatePanel
    case requestAuth(String)
}

struct PrivateLockAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
}

enum PrivateLockMiddlewareActionType: ActionType {
    case setPrivateLockState
}

struct PrivateLockMiddlewareAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let privatePanelLockState: PrivateLockState
}

enum PrivateLockState: Equatable {
    case unlocked
    case lockedPrompt
    case authenticating
    case failed
}
