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
        var displayTopBorder: Bool
        var displayBottomBorder: Bool
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
            case qrCode
            case share
            case reload
            case readerMode
            case dataClearance
        }

        var actionType: ActionType
        var iconName: String
        var numberOfTabs: Int?
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
        let addressToolbar = AddressState(navigationActions: [],
                                          pageActions: [],
                                          browserActions: [],
                                          displayTopBorder: false,
                                          displayBottomBorder: false)
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            addressToolbar: addressToolbar,
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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID,
              let action = action as? ToolbarAction
        else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let navToolbarModel = action.navigationToolbarModel,
                    let addressToolbarModel = action.addressToolbarModel
            else { return state }

            var state = state
            state.addressToolbar.navigationActions = addressToolbarModel.navigationActions
            state.addressToolbar.pageActions = addressToolbarModel.pageActions
            state.addressToolbar.browserActions = addressToolbarModel.browserActions
            state.addressToolbar.displayTopBorder = addressToolbarModel.displayTopBorder
            state.addressToolbar.displayBottomBorder = addressToolbarModel.displayBottomBorder

            state.navigationToolbar.actions = navToolbarModel.actions
            state.navigationToolbar.displayBorder = navToolbarModel.displayBorder
            return state

        case ToolbarActionType.numberOfTabsChanged:
            guard let numberOfTabs = action.numberOfTabs else { return state }
            var state = state

            if let index = state.navigationToolbar.actions.firstIndex(where: { $0.actionType == .tabs }) {
                state.navigationToolbar.actions[index].numberOfTabs = numberOfTabs
            }

            if let index = state.addressToolbar.browserActions.firstIndex(where: { $0.actionType == .tabs }) {
                state.addressToolbar.browserActions[index].numberOfTabs = numberOfTabs
            }

            return state

        default:
            return state
        }
    }
}
