// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class MainMenuAction: Action {
    override init(windowUUID: WindowUUID, actionType: any ActionType) {
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

final class MainMenuMiddlewareAction: Action { }

enum MainMenuActionType: ActionType {
    case mainMenuDidAppear
    case closeMenu
}

enum MainMenuMiddlewareActionType: ActionType {
    case dismissMenu
}
