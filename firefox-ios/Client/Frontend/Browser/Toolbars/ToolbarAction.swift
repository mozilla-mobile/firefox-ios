// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarNavigationModelAction: Action {
    let actions: [ToolbarState.ActionState]
    let displayBorder: Bool

    init(actions: [ToolbarState.ActionState],
         displayBorder: Bool,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.actions = actions
        self.displayBorder = displayBorder
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars(ToolbarNavigationModelAction)
}
