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
    var isLoginActionRequired: Bool
    var addressToolbar: AddressBarState
    var navigationToolbar: NavigationBarState

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
                  isLoginActionRequired: toolbarState.isLoginActionRequired,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            isPrivateMode: false,
            isLoginActionRequired: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID)
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        isPrivateMode: Bool,
        isLoginActionRequired: Bool,
        addressToolbar: AddressBarState,
        navigationToolbar: NavigationBarState
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.isPrivateMode = isPrivateMode
        self.isLoginActionRequired = isLoginActionRequired
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars,
            ToolbarActionType.numberOfTabsChanged,
            ToolbarActionType.urlDidChange,
            ToolbarActionType.backButtonStateChanged,
            ToolbarActionType.forwardButtonStateChanged,
            ToolbarActionType.scrollOffsetChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: toolbarAction.toolbarPosition ?? state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                isLoginActionRequired: state.isLoginActionRequired,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction))

        case GeneralBrowserActionType.updateSelectedTab:
            guard let action = action as? GeneralBrowserAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: action.isPrivateBrowsing ?? state.isPrivateMode,
                isLoginActionRequired: state.isLoginActionRequired,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action))

        case GeneralBrowserActionType.showWarningBadge:
            guard let action = action as? GeneralBrowserAction else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                isLoginActionRequired: action.isLoginActionRequired ?? state.isLoginActionRequired,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action))

        case ToolbarActionType.toolbarPositionChanged:
            guard let position = (action as? ToolbarAction)?.toolbarPosition else { return state }
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: position,
                isPrivateMode: state.isPrivateMode,
                isLoginActionRequired: state.isLoginActionRequired,
                addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action))

        default:
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                isPrivateMode: state.isPrivateMode,
                isLoginActionRequired: state.isLoginActionRequired,
                addressToolbar: state.addressToolbar,
                navigationToolbar: state.navigationToolbar)
        }
    }
}
