// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarNavigationModelContext: ActionContext {
    let actions: [ToolbarState.ActionState]
    let displayBorder: Bool

    init(actions: [ToolbarState.ActionState],
         displayBorder: Bool,
         windowUUID: WindowUUID) {
        self.actions = actions
        self.displayBorder = displayBorder
        super.init(windowUUID: windowUUID)
    }
}

enum ToolbarAction: Action {
    case didLoadToolbars(ToolbarNavigationModelContext)

    var windowUUID: UUID {
        switch self {
        case .didLoadToolbars(let context):
            return context.windowUUID
        }
    }
}
