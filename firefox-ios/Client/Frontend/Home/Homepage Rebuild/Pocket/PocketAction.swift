// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

final class PocketAction: Action {
    var pocketStories: [PocketStoryState]?
    var isEnabled: Bool?

    init(
        pocketStories: [PocketStoryState]? = nil,
        isEnabled: Bool? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.pocketStories = pocketStories
        self.isEnabled = isEnabled
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum PocketActionType: ActionType {
    case enteredForeground
    case toggleShowSectionSetting
}

enum PocketMiddlewareActionType: ActionType {
    case retrievedUpdatedStories
}
