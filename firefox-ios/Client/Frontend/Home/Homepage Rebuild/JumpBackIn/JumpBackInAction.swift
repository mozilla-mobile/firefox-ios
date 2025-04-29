// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

final class JumpBackInAction: Action {
    let isEnabled: Bool?
    let tab: Tab?

    init(
        isEnabled: Bool? = nil,
        tab: Tab? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.isEnabled = isEnabled
        self.tab = tab
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum JumpBackInActionType: ActionType {
    case tapOnCell
    case toggleShowSectionSetting
}
