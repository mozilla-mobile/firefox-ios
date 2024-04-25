// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage

//class TabDisplayModelContext: ActionContext {
//    let tabDisplayModel: TabDisplayModel
//    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
//        self.tabDisplayModel = tabDisplayModel
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class BoolValueContext: ActionContext {
//    let boolValue: Bool
//    init(boolValue: Bool, windowUUID: WindowUUID) {
//        self.boolValue = boolValue
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class FloatValueContext: ActionContext {
//    let floatValue: Float
//    init(floatValue: Float, windowUUID: WindowUUID) {
//        self.floatValue = floatValue
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class AddNewTabContext: ActionContext {
//    let urlRequest: URLRequest?
//    let isPrivate: Bool
//    init(urlRequest: URLRequest?, isPrivate: Bool, windowUUID: WindowUUID) {
//        self.urlRequest = urlRequest
//        self.isPrivate = isPrivate
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class URLRequestContext: ActionContext {
//    let urlRequest: URLRequest
//    init(urlRequest: URLRequest, windowUUID: WindowUUID) {
//        self.urlRequest = urlRequest
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class URLContext: ActionContext {
//    let url: URL
//    init(url: URL, windowUUID: WindowUUID) {
//        self.url = url
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class TabUUIDContext: ActionContext {
//    let tabUUID: TabUUID
//    init(tabUUID: TabUUID, windowUUID: WindowUUID) {
//        self.tabUUID = tabUUID
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//
//class ToastTypeContext: ActionContext {
//    let toastType: ToastType
//    init(toastType: ToastType, windowUUID: WindowUUID) {
//        self.toastType = toastType
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class KeyboardContext: ActionContext {
//    let showOverlay: Bool
//    init(showOverlay: Bool, windowUUID: WindowUUID) {
//        self.showOverlay = showOverlay
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class RefreshTabContext: ActionContext {
//    let tabDisplayModel: TabDisplayModel
//    init(tabDisplayModel: TabDisplayModel, windowUUID: WindowUUID) {
//        self.tabDisplayModel = tabDisplayModel
//        super.init(windowUUID: windowUUID)
//    }
//}
//
//class RefreshInactiveTabsContext: ActionContext {
//    let inactiveTabModels: [InactiveTabsModel]
//    init(tabModels: [InactiveTabsModel], windowUUID: WindowUUID) {
//        self.inactiveTabModels = tabModels
//        super.init(windowUUID: windowUUID)
//    }
//}

//enum TabPanelAction: Action {
//
//
//    // Middleware actions
//
//
//    var windowUUID: UUID {
//        switch self {
//        case .tabPanelDidLoad(let context as ActionContext),
//                .tabPanelDidAppear(let context as ActionContext),
//                .addNewTab(let context as ActionContext),
//                .closeTab(let context as ActionContext),
//                .undoClose(let context),
//                .closeAllTabs(let context),
//                .confirmCloseAllTabs(let context),
//                .undoCloseAllTabs(let context),
//                .moveTab(let context as ActionContext),
//                .toggleInactiveTabs(let context),
//                .closeInactiveTabs(let context as ActionContext),
//                .undoCloseInactiveTab(let context),
//                .closeAllInactiveTabs(let context),
//                .undoCloseAllInactiveTabs(let context),
//                .learnMorePrivateMode(let context as ActionContext),
//                .selectTab(let context as ActionContext),
//                .showToast(let context as ActionContext),
//                .hideUndoToast(let context),
//                .showShareSheet(let context as ActionContext),
//                .didLoadTabPanel(let context as ActionContext),
//                .didChangeTabPanel(let context as ActionContext),
//                .refreshTab(let context as ActionContext),
//                .refreshInactiveTabs(let context as ActionContext):
//            return context.windowUUID
//        }
//    }
//}

struct MoveTabData {
    let originIndex: Int
    let destinationIndex: Int
    let isPrivate: Bool
}


class TabPanelViewAction: Action {
    let panelType: TabTrayPanelType?
    let isPrivateModeActive: Bool?
    let urlRequest: URLRequest?
    let tabUUID: TabUUID?
    let moveTabData: MoveTabData?
    let toastType: ToastType?

    init(panelType: TabTrayPanelType,
         isPrivateModeActive: Bool? = nil,
         urlRequest: URLRequest? = nil,
         tabUUID: TabUUID? = nil,
         moveTabData: MoveTabData? = nil,
         toastType: ToastType? = nil,
         windowUUID: UUID,
         actionType: ActionType) {
        self.panelType = panelType
        self.isPrivateModeActive = isPrivateModeActive
        self.urlRequest = urlRequest
        self.tabUUID = tabUUID
        self.moveTabData = moveTabData
        self.toastType = toastType
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum TabPanelViewActionType: ActionType {
    case tabPanelDidLoad
    case tabPanelDidAppear
    case addNewTab
    case closeTab
    case undoClose
    case closeAllTabs
    case confirmCloseAllTabs
    case undoCloseAllTabs
    case moveTab
    case toggleInactiveTabs
    case closeInactiveTabs
    case undoCloseInactiveTab
    case closeAllInactiveTabs
    case undoCloseAllInactiveTabs
    case learnMorePrivateMode
    case selectTab
    case showToast
    case hideUndoToast
    case showShareSheet
}

class TabPanelMiddlewareAction: Action {
    let tabDisplayModel: TabDisplayModel?
    let inactiveTabModels: [InactiveTabsModel]?

    init(tabDisplayModel: TabDisplayModel? = nil,
         inactiveTabModels: [InactiveTabsModel]? = nil,
         windowUUID: UUID,
         actionType: ActionType) {
        self.tabDisplayModel = tabDisplayModel
        self.inactiveTabModels = inactiveTabModels
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
    }
}

enum TabPanelMiddlewareAtionType: ActionType {
    case didLoadTabPanel
    case didChangeTabPanel
    case refreshTabs
    case refreshInactiveTabs
}
