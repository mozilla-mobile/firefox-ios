// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

struct MessageCardAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let messageCardConfiguration: MessageCardConfiguration?

    init(messageCardConfiguration: MessageCardConfiguration? = nil,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.messageCardConfiguration = messageCardConfiguration
    }
}

enum MessageCardActionType: ActionType {
    case tappedOnActionButton
    case tappedOnCloseButton
}

enum MessageCardMiddlewareActionType: ActionType {
    case initialize
}
