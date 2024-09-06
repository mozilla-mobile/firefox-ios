// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

final class ToolbarAction: Action {
    let toolbarPosition: SearchBarPosition?
    let numberOfTabs: Int?
    let url: URL?
    let searchTerm: String?
    let isPrivate: Bool?
    let showMenuWarningBadge: Bool?
    let isShowingNavigationToolbar: Bool?
    let isShowingTopTabs: Bool?
    let canGoBack: Bool?
    let canGoForward: Bool?
    let readerModeState: ReaderModeState?
    let addressBorderPosition: AddressToolbarBorderPosition?
    let displayNavBorder: Bool?
    let lockIconImageName: String?
    let isEditing: Bool?
    let isLoading: Bool?

    init(toolbarPosition: SearchBarPosition? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         searchTerm: String? = nil,
         isPrivate: Bool? = nil,
         showMenuWarningBadge: Bool? = nil,
         isShowingNavigationToolbar: Bool? = nil,
         isShowingTopTabs: Bool? = nil,
         canGoBack: Bool? = nil,
         canGoForward: Bool? = nil,
         readerModeState: ReaderModeState? = nil,
         addressBorderPosition: AddressToolbarBorderPosition? = nil,
         displayNavBorder: Bool? = nil,
         lockIconImageName: String? = nil,
         isEditing: Bool? = nil,
         isLoading: Bool? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.toolbarPosition = toolbarPosition
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.searchTerm = searchTerm
        self.isPrivate = isPrivate
        self.showMenuWarningBadge = showMenuWarningBadge
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.readerModeState = readerModeState
        self.addressBorderPosition = addressBorderPosition
        self.displayNavBorder = displayNavBorder
        self.lockIconImageName = lockIconImageName
        self.isEditing = isEditing
        self.isLoading = isLoading
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
    case urlDidChange
    case didSetTextInLocationView
    case borderPositionChanged
    case toolbarPositionChanged
    case showMenuWarningBadge
    case didPasteSearchTerm
    case didStartEditingUrl
    case cancelEdit
    case didScrollDuringEdit
    case readerModeStateChanged
    case backButtonStateChanged
    case forwardButtonStateChanged
    case traitCollectionDidChange
    case websiteLoadingStateDidChange
    case searchEngineDidChange
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarActionState.ActionType?
    let buttonTapped: UIButton?
    let gestureType: ToolbarButtonGesture?

    init(buttonType: ToolbarActionState.ActionType? = nil,
         buttonTapped: UIButton? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.buttonTapped = buttonTapped
        self.gestureType = gestureType
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
    case customA11yAction
}
