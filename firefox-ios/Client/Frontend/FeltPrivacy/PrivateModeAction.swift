// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct PrivateModeAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let isPrivate: Bool?

    init(isPrivate: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.isPrivate = isPrivate
    }
}

enum PrivateModeActionType: ActionType {
    case setPrivateModeTo
    case privateModeUpdated
}
