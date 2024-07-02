// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

class ToolbarAction: Action {
    let addressToolbarModel: AddressToolbarModel?
    let navigationToolbarModel: NavigationToolbarModel?
    let toolbarPosition: AddressToolbarPosition?
    let numberOfTabs: Int?
    let url: URL?
    let isButtonEnabled: Bool?
    let isPrivate: Bool?

    init(addressToolbarModel: AddressToolbarModel? = nil,
         navigationToolbarModel: NavigationToolbarModel? = nil,
         toolbarPosition: AddressToolbarPosition? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         isButtonEnabled: Bool? = nil,
         isPrivate: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.addressToolbarModel = addressToolbarModel
        self.navigationToolbarModel = navigationToolbarModel
        self.toolbarPosition = toolbarPosition
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.isButtonEnabled = isButtonEnabled
        self.isPrivate = isPrivate
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
    case urlDidChange
    case backButtonStateChanged
    case forwardButtonStateChanged
    case scrollOffsetChanged
    case toolbarPositionChanged
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarActionState.ActionType?
    let buttonTapped: UIButton?
    let gestureType: ToolbarButtonGesture?
    let url: URL?
    let traitCollection: UITraitCollection?
    let canGoForward: Bool?
    let canGoBack: Bool?

    init(buttonType: ToolbarActionState.ActionType? = nil,
         buttonTapped: UIButton? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         url: URL? = nil,
         traitCollection: UITraitCollection? = nil,
         canGoForward: Bool? = nil,
         canGoBack: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.buttonTapped = buttonTapped
        self.gestureType = gestureType
        self.url = url
        self.traitCollection = traitCollection
        self.canGoForward = canGoForward
        self.canGoBack = canGoBack
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
    case urlDidChange
}
