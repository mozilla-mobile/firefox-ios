// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Equatable {
    struct ActionState: Equatable {
        enum ActionType {
            case back
            case forward
            case home
            case search
            case tabs
            case menu
            case qrCode
            case share
            case reload
            case trackingProtection
            case readerMode
            case dataClearance
        }

        var actionType: ActionType
        var iconName: String
        var numberOfTabs: Int?
        var isEnabled: Bool
        var a11yLabel: String
        var a11yId: String

        var canPerformLongPressAction: Bool {
            return actionType == .back ||
                   actionType == .forward ||
                   actionType == .tabs
        }
    }

    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var addressToolbar: AddressState
    var navigationToolbar: NavigationState

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
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            addressToolbar: AddressState(windowUUID: windowUUID),
            navigationToolbar: NavigationState(windowUUID: windowUUID)
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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? ToolbarAction
        else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars,
            ToolbarActionType.numberOfTabsChanged,
            ToolbarActionType.urlDidChange,
            ToolbarActionType.backButtonStateChanged,
            ToolbarActionType.forwardButtonStateChanged:
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                addressToolbar: AddressState.reducer(state.addressToolbar, action),
                navigationToolbar: NavigationState.reducer(state.navigationToolbar, action))

        default:
            return ToolbarState(
                windowUUID: state.windowUUID,
                toolbarPosition: state.toolbarPosition,
                addressToolbar: state.addressToolbar,
                navigationToolbar: NavigationState.reducer(state.navigationToolbar, action))
        }
    }
}
