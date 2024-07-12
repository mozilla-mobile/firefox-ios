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
    let badgeImageName: String?

    init(addressToolbarModel: AddressToolbarModel? = nil,
         navigationToolbarModel: NavigationToolbarModel? = nil,
         toolbarPosition: AddressToolbarPosition? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         isButtonEnabled: Bool? = nil,
         isPrivate: Bool? = nil,
         badgeImageName: String? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.addressToolbarModel = addressToolbarModel
        self.navigationToolbarModel = navigationToolbarModel
        self.toolbarPosition = toolbarPosition
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.isButtonEnabled = isButtonEnabled
        self.isPrivate = isPrivate
        self.badgeImageName = badgeImageName
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
    case addressToolbarActionsDidChange
    case urlDidChange
    case backButtonStateChanged
    case forwardButtonStateChanged
    case scrollOffsetChanged
    case toolbarPositionChanged
    case showMenuWarningBadge
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarActionState.ActionType?
    let buttonTapped: UIButton?
    let gestureType: ToolbarButtonGesture?
    let isLoading: Bool?

    init(buttonType: ToolbarActionState.ActionType? = nil,
         buttonTapped: UIButton? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         isLoading: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.buttonTapped = buttonTapped
        self.gestureType = gestureType
        self.isLoading = isLoading
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

final class ToolbarMiddlewareUrlChangeAction: ToolbarMiddlewareAction {
    let url: URL?
    let lockIconImageName: String?
    let isShowingNavigationToolbar: Bool
    let canGoForward: Bool
    let canGoBack: Bool

    init(url: URL? = nil,
         lockIconImageName: String? = nil,
         isShowingNavigationToolbar: Bool,
         canGoForward: Bool,
         canGoBack: Bool,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.url = url
        self.lockIconImageName = lockIconImageName
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.canGoForward = canGoForward
        self.canGoBack = canGoBack
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
    case urlDidChange
    case didStartEditingUrl
    case cancelEdit
    case websiteLoadingStateDidChange
}
