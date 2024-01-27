// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage

class TabDisplayModelContext: ActionContext {
    let tabDisplayModel: TabDisplayModel
    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
        self.tabDisplayModel = tabDisplayModel
        super.init(windowUUID: windowUUID)
    }
}

class BooleanValueContext: ActionContext {
    let boolValue: Bool
    init(boolValue: Bool, windowUUID: WindowUUID) {
        self.boolValue = boolValue
        super.init(windowUUID: windowUUID)
    }
}

class AddNewTabContext: ActionContext {
    let urlRequest: URLRequest?
    let isPrivate: Bool
    init(urlRequest: URLRequest?, isPrivate: Bool, windowUUID: WindowUUID) {
        self.urlRequest = urlRequest
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID)
    }
}

enum TabPanelAction: Action {
    case tabPanelDidLoad(Bool)
    case tabPanelDidAppear(Bool)
    case addNewTab(AddNewTabContext)
    case closeTab(String)
    case undoClose
    case closeAllTabs
    case undoCloseAllTabs
    case moveTab(Int, Int)
    case toggleInactiveTabs
    case closeInactiveTabs(String)
    case undoCloseInactiveTab
    case closeAllInactiveTabs
    case undoCloseAllInactiveTabs
    case learnMorePrivateMode(URLRequest)
    case selectTab(String)
    case showToast(ToastType)
    case hideUndoToast
    case showShareSheet(URL)

    // Middleware actions
    case didLoadTabPanel(TabDisplayModelContext)
    case refreshTab(TabDisplayModelContext) // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshInactiveTabs([InactiveTabsModel])

    var windowUUID: UUID {
       // TODO: [8188] Use of .unavailable UUID is temporary as part of early MW refactors. WIP. 
        switch self {
        default: return .unavailable
        }
    }
}
