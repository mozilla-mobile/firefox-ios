// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var isPrivateMode: Bool
    var addressToolbar: AddressBarState
    var navigationToolbar: NavigationBarState
    let isShowingNavigationToolbar: Bool
    let isShowingTopTabs: Bool
    let readerModeState: ReaderModeState?
    let badgeImageName: String?
    let maskImageName: String?
    let canGoBack: Bool
    let canGoForward: Bool
    var numberOfTabs: Int

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = store.state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: toolbarState.windowUUID,
                  toolbarPosition: toolbarState.toolbarPosition,
                  isPrivateMode: toolbarState.isPrivateMode,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar,
                  isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
                  isShowingTopTabs: toolbarState.isShowingTopTabs,
                  readerModeState: toolbarState.readerModeState,
                  badgeImageName: toolbarState.badgeImageName,
                  maskImageName: toolbarState.maskImageName,
                  canGoBack: toolbarState.canGoBack,
                  canGoForward: toolbarState.canGoForward,
                  numberOfTabs: toolbarState.numberOfTabs)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            isPrivateMode: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID),
            isShowingNavigationToolbar: true,
            isShowingTopTabs: false,
            readerModeState: nil,
            badgeImageName: nil,
            maskImageName: nil,
            canGoBack: false,
            canGoForward: false,
            numberOfTabs: 1
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        isPrivateMode: Bool,
        addressToolbar: AddressBarState,
        navigationToolbar: NavigationBarState,
        isShowingNavigationToolbar: Bool,
        isShowingTopTabs: Bool,
        readerModeState: ReaderModeState?,
        badgeImageName: String?,
        maskImageName: String?,
        canGoBack: Bool,
        canGoForward: Bool,
        numberOfTabs: Int
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.isPrivateMode = isPrivateMode
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.readerModeState = readerModeState
        self.badgeImageName = badgeImageName
        self.maskImageName = maskImageName
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.numberOfTabs = numberOfTabs
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let toolbarAction = action as? ToolbarAction,
                  let toolbarPosition = toolbarAction.toolbarPosition
            else { return state }

            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        case ToolbarActionType.addressToolbarActionsDidChange,
            ToolbarActionType.backForwardButtonStatesChanged,
            ToolbarActionType.scrollOffsetChanged,
            ToolbarActionType.urlDidChange,
            ToolbarActionType.didPasteSearchTerm,
            ToolbarActionType.didStartEditingUrl,
            ToolbarActionType.cancelEdit,
            ToolbarActionType.didScrollDuringEdit:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            let position = if let toolbarPosition = toolbarAction.toolbarPosition {
                addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            } else {
                state.toolbarPosition
            }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
                isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
                canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        case ToolbarActionType.showMenuWarningBadge:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            let position = if let toolbarPosition = toolbarAction.toolbarPosition {
                addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            } else {
                state.toolbarPosition
            }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
                isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: toolbarAction.badgeImageName,
                maskImageName: toolbarAction.maskImageName,
                canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
                canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        case ToolbarActionType.numberOfTabsChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs)

        case GeneralBrowserActionType.updateSelectedTab:
            guard let action = action as? GeneralBrowserAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: action.isPrivateBrowsing ?? state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        case ToolbarActionType.toolbarPositionChanged:
            guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition else { return state }
            let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        case ToolbarActionType.readerModeStateChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: toolbarAction.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs)

        default:
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                addressToolbar: state.addressToolbar,
                navigationToolbar: state.navigationToolbar,
                isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                isShowingTopTabs: state.isShowingTopTabs,
                readerModeState: state.readerModeState,
                badgeImageName: state.badgeImageName,
                maskImageName: state.maskImageName,
                canGoBack: state.canGoBack,
                canGoForward: state.canGoForward,
                numberOfTabs: state.numberOfTabs)
        }
    }

    private static func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition)
    -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }
}
