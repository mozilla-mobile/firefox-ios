// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

final class ToolbarAction: Action {
    let addressToolbarModel: AddressToolbarModel?
    let navigationToolbarModel: NavigationToolbarModel?
    let toolbarPosition: AddressToolbarPosition?
    let numberOfTabs: Int?
    let url: URL?
    let searchTerm: String?
    let isPrivate: Bool?
    let badgeImageName: String?
    let maskImageName: String?
    let isShowingNavigationToolbar: Bool?
    let isShowingTopTabs: Bool?
    let canGoBack: Bool?
    let canGoForward: Bool?
    let readerModeState: ReaderModeState?

    init(addressToolbarModel: AddressToolbarModel? = nil,
         navigationToolbarModel: NavigationToolbarModel? = nil,
         toolbarPosition: AddressToolbarPosition? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         searchTerm: String? = nil,
         isPrivate: Bool? = nil,
         badgeImageName: String? = nil,
         maskImageName: String? = nil,
         isShowingNavigationToolbar: Bool? = nil,
         isShowingTopTabs: Bool? = nil,
         canGoBack: Bool? = nil,
         canGoForward: Bool? = nil,
         readerModeState: ReaderModeState? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.addressToolbarModel = addressToolbarModel
        self.navigationToolbarModel = navigationToolbarModel
        self.toolbarPosition = toolbarPosition
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.searchTerm = searchTerm
        self.isPrivate = isPrivate
        self.badgeImageName = badgeImageName
        self.maskImageName = maskImageName
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.readerModeState = readerModeState
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarActionType: ActionType {
    case didLoadToolbars
    case numberOfTabsChanged
    case addressToolbarActionsDidChange
    case urlDidChange
    case backForwardButtonStatesChanged
    case scrollOffsetChanged
    case toolbarPositionChanged
    case showMenuWarningBadge
    case didPasteSearchTerm
    case didStartEditingUrl
    case cancelEdit
    case didScrollDuringEdit
    case readerModeStateChanged
}

class ToolbarMiddlewareAction: Action {
    let buttonType: ToolbarActionState.ActionType?
    let buttonTapped: UIButton?
    let gestureType: ToolbarButtonGesture?
    let isLoading: Bool?
    let isShowingTopTabs: Bool?
    let isShowingNavigationToolbar: Bool?
    let lockIconImageName: String?
    let numberOfTabs: Int?
    let url: URL?
    let canGoBack: Bool?
    let canGoForward: Bool?
    let badgeImageName: String?
    let readerModeState: ReaderModeState?
    let maskImageName: String?
    let searchTerm: String?

    init(buttonType: ToolbarActionState.ActionType? = nil,
         buttonTapped: UIButton? = nil,
         gestureType: ToolbarButtonGesture? = nil,
         isLoading: Bool? = nil,
         isShowingTopTabs: Bool? = nil,
         isShowingNavigationToolbar: Bool? = nil,
         lockIconImageName: String? = nil,
         numberOfTabs: Int? = nil,
         url: URL? = nil,
         canGoBack: Bool? = nil,
         canGoForward: Bool? = nil,
         badgeImageName: String? = nil,
         readerModeState: ReaderModeState? = nil,
         maskImageName: String? = nil,
         searchTerm: String? = nil,
         windowUUID: WindowUUID,
         actionType: ActionType) {
        self.buttonType = buttonType
        self.buttonTapped = buttonTapped
        self.gestureType = gestureType
        self.isLoading = isLoading
        self.isShowingTopTabs = isShowingTopTabs
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.lockIconImageName = lockIconImageName
        self.numberOfTabs = numberOfTabs
        self.url = url
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.badgeImageName = badgeImageName
        self.readerModeState = readerModeState
        self.maskImageName = maskImageName
        self.searchTerm = searchTerm
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum ToolbarMiddlewareActionType: ActionType {
    case didTapButton
    case customA11yAction
    case numberOfTabsChanged
    case urlDidChange
    case searchEngineDidChange
    case didStartEditingUrl
    case cancelEdit
    case websiteLoadingStateDidChange
    case traitCollectionDidChange
    case backButtonStateChanged
    case forwardButtonStateChanged
    case showMenuWarningBadge
    case readerModeStateChanged
}
