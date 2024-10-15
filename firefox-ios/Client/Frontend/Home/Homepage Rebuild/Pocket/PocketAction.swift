// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

final class PocketAction: Action {
    var pocketStories: [PocketItem]?

    init(
        pocketStories: [PocketItem]? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.pocketStories = pocketStories
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum PocketActionType: ActionType {
    case enteredForeground
}

enum PocketMiddlewareActionType: ActionType {
    case retrievedUpdatedStories
}
