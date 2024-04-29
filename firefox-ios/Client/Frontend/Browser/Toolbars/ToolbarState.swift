// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Equatable {
    struct AddressState: Equatable {
        var navigationActions: [ActionState]
        var pageActions: [ActionState]
        var browserActions: [ActionState]
    }

    struct NavigationState: Equatable {
        var actions: [ActionState]
        var displayBorder: Bool
    }

    struct ActionState: Equatable {
        enum ActionType {
            case back
            case forward
            case home
            case search
            case tabs
            case menu
        }

        var actionType: ActionType
        var iconName: String
        var isEnabled: Bool
        var a11yLabel: String
        var a11yId: String
    }

    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var addressToolbar: AddressState
    var navigationToolbar: NavigationState

    init(_ appState: BrowserViewControllerState) {
        self.init(
            windowUUID: appState.windowUUID,
            toolbarPosition: appState.toolbarState.toolbarPosition,
            addressToolbar: appState.toolbarState.addressToolbar,
            navigationToolbar: appState.toolbarState.navigationToolbar
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            addressToolbar: AddressState(navigationActions: [], pageActions: [], browserActions: []),
            navigationToolbar: NavigationState(actions: [], displayBorder: false)
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        addressToolbar: AddressState,
        navigationToolbar: NavigationState
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action {
        case ToolbarAction.didLoadToolbars(let context):
            var state = state
            state.navigationToolbar.actions = context.actions
            state.navigationToolbar.displayBorder = context.displayBorder
            return state

        default:
            return state
        }
    }
}
