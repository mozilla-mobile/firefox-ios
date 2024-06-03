// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarAction: Action {
    let addressToolbarModel: AddressToolbarModel?
    let navigationToolbarModel: NavigationToolbarModel?
    let numberOfTabs: Int?

    init(addressToolbarModel: AddressToolbarModel? = nil,
         navigationToolbarModel: NavigationToolbarModel? = nil,
         numberOfTabs: Int? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.addressToolbarModel = addressToolbarModel
        self.navigationToolbarModel = navigationToolbarModel
        self.numberOfTabs = numberOfTabs
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarState.ActionState.ActionType?
    let gestureType: ToolbarButtonGesture?

    init(buttonType: ToolbarState.ActionState.ActionType? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.gestureType = gestureType
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
}
