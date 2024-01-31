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

class BoolValueContext: ActionContext {
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

class URLRequestContext: ActionContext {
    let urlRequest: URLRequest
    init(urlRequest: URLRequest, windowUUID: WindowUUID) {
        self.urlRequest = urlRequest
        super.init(windowUUID: windowUUID)
    }
}

class URLContext: ActionContext {
    let url: URL
    init(url: URL, windowUUID: WindowUUID) {
        self.url = url
        super.init(windowUUID: windowUUID)
    }
}

class TabUUIDContext: ActionContext {
    let tabUUID: String
    init(tabUUID: String, windowUUID: WindowUUID) {
        self.tabUUID = tabUUID
        super.init(windowUUID: windowUUID)
    }
}

class MoveTabContext: ActionContext {
    let originIndex: Int
    let destinationIndex: Int
    init(originIndex: Int, destinationIndex: Int, windowUUID: WindowUUID) {
        self.originIndex = originIndex
        self.destinationIndex = destinationIndex
        super.init(windowUUID: windowUUID)
    }
}

class ToastTypeContext: ActionContext {
    let toastType: ToastType
    init(toastType: ToastType, windowUUID: WindowUUID) {
        self.toastType = toastType
        super.init(windowUUID: windowUUID)
    }
}

class RefreshTabContext: ActionContext {
    let tabDisplayModel: TabDisplayModel
    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
        self.tabDisplayModel = tabDisplayModel
        super.init(windowUUID: windowUUID)
    }
}

class RefreshInactiveTabsContext: ActionContext {
    let inactiveTabModels: [InactiveTabsModel]
    init(tabModels: [InactiveTabsModel], windowUUID: WindowUUID) {
        self.inactiveTabModels = tabModels
        super.init(windowUUID: windowUUID)
    }
}

enum TabPanelAction: Action {
    case tabPanelDidLoad(BoolValueContext)
    case tabPanelDidAppear(BoolValueContext)
    case addNewTab(AddNewTabContext)
    case closeTab(TabUUIDContext)
    case undoClose(ActionContext)
    case closeAllTabs(ActionContext)
    case undoCloseAllTabs(ActionContext)
    case moveTab(MoveTabContext)
    case toggleInactiveTabs(ActionContext)
    case closeInactiveTabs(TabUUIDContext)
    case undoCloseInactiveTab(ActionContext)
    case closeAllInactiveTabs(ActionContext)
    case undoCloseAllInactiveTabs(ActionContext)
    case learnMorePrivateMode(URLRequestContext)
    case selectTab(TabUUIDContext)
    case showToast(ToastTypeContext)
    case hideUndoToast(ActionContext)
    case showShareSheet(URLContext)

    // Middleware actions
    case didLoadTabPanel(TabDisplayModelContext)
    case refreshTab(RefreshTabContext) // Response to all user actions involving tabs ex: add, close and close all tabs
    case refreshInactiveTabs(RefreshInactiveTabsContext)

    var windowUUID: UUID {
        switch self {
        case .tabPanelDidLoad(let context as ActionContext),
                .tabPanelDidAppear(let context as ActionContext),
                .addNewTab(let context as ActionContext),
                .closeTab(let context as ActionContext),
                .undoClose(let context),
                .closeAllTabs(let context),
                .undoCloseAllTabs(let context),
                .moveTab(let context as ActionContext),
                .toggleInactiveTabs(let context),
                .closeInactiveTabs(let context as ActionContext),
                .undoCloseInactiveTab(let context),
                .closeAllInactiveTabs(let context),
                .undoCloseAllInactiveTabs(let context),
                .learnMorePrivateMode(let context as ActionContext),
                .selectTab(let context as ActionContext),
                .showToast(let context as ActionContext),
                .hideUndoToast(let context),
                .showShareSheet(let context as ActionContext),
                .didLoadTabPanel(let context as ActionContext),
                .refreshTab(let context as ActionContext),
                .refreshInactiveTabs(let context as ActionContext):
            return context.windowUUID
        }
    }
}
