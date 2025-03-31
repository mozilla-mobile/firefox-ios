// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common

class TabTrayAction: Action {
    let panelType: TabTrayPanelType?
    let tabTrayModel: TabTrayModel?
    let hasSyncableAccount: Bool?

    init(panelType: TabTrayPanelType? = nil,
         tabTrayModel: TabTrayModel? = nil,
         hasSyncableAccount: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.panelType = panelType
        self.tabTrayModel = tabTrayModel
        self.hasSyncableAccount = hasSyncableAccount
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum  TabTrayActionType: ActionType {
    case tabTrayDidLoad
    case changePanel
    case doneButtonTapped
    case modalSwipedToClose

    // Middleware actions
    case didLoadTabTray
    case dismissTabTray
    case firefoxAccountChanged
    case closePrivateTabsSettingToggled
}
