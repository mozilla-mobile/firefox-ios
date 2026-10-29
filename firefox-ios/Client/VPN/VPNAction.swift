// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct VPNAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType

    init(windowUUID: WindowUUID, actionType: any ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
    }
}

/// User choices from the VPN failure alert. Each one turns the VPN off.
enum VPNActionType: ActionType {
    case continueWithoutVPN
    case closeThisTab
    case closeAllTabs
    case closeTabsInAllWindows
}
