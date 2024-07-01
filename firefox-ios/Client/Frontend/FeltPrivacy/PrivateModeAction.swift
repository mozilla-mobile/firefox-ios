// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

class PrivateModeAction: Action {
    let isPrivate: Bool?

    init(isPrivate: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum PrivateModeActionType: ActionType {
    case setPrivateModeTo
    case privateModeUpdated
}
