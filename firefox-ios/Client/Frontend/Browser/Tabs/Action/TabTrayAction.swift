// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux

class TabTrayPanelContext: ActionContext {
    let panelType: TabTrayPanelType
    init(panelType: TabTrayPanelType, windowUUID: WindowUUID) {
        self.panelType = panelType
        super.init(windowUUID: windowUUID)
    }
}

class TabTrayModelContext: ActionContext {
    let tabTrayModel: TabTrayModel
    init(tabTrayModel: TabTrayModel, windowUUID: WindowUUID) {
        self.tabTrayModel = tabTrayModel
        super.init(windowUUID: windowUUID)
    }
}

class HasSyncableAccountContext: ActionContext {
    let hasSyncableAccount: Bool
    init(hasSyncableAccount: Bool, windowUUID: WindowUUID) {
        self.hasSyncableAccount = hasSyncableAccount
        super.init(windowUUID: windowUUID)
    }
}

enum TabTrayAction: Action {
    case tabTrayDidLoad(TabTrayPanelContext)
    case changePanel(TabTrayPanelContext)

    // Middleware actions
    case didLoadTabTray(TabTrayModelContext)
    case dismissTabTray(ActionContext)
    case firefoxAccountChanged(HasSyncableAccountContext)

    var windowUUID: UUID {
        switch self {
        case .tabTrayDidLoad(let context as ActionContext),
                .changePanel(let context as ActionContext),
                .didLoadTabTray(let context as ActionContext),
                .dismissTabTray(let context),
                .firefoxAccountChanged(let context as ActionContext):
            return context.windowUUID
        }
    }
}
