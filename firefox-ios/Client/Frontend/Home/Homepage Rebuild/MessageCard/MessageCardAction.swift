// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class MessageCardAction: Action {
    let messageCardConfiguration: MessageCardConfiguration?

    init(messageCardConfiguration: MessageCardConfiguration? = nil,
         windowUUID: WindowUUID,
         actionType: any ActionType
    ) {
        self.messageCardConfiguration = messageCardConfiguration
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MessageCardActionType: ActionType {
    case tappedOnActionButton
    case tappedOnCloseButton
}

enum MessageCardMiddlewareActionType: ActionType {
    case initialize
}
