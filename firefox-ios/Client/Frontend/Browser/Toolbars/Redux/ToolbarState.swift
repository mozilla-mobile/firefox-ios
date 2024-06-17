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
        var url: URL?
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

        self.init(windowUUID: toolbarState.windowUUID)
    }

    init(windowUUID: WindowUUID) {
        let addressToolbar = AddressState(navigationActions: [],
                                          pageActions: [],
                                          browserActions: [],
                                          displayTopBorder: false,
                                          displayBottomBorder: false,
                                          url: nil)
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
            state.addressToolbar.url = addressToolbarModel.url

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

        case ToolbarActionType.urlDidChange:
            var state = state
            state.addressToolbar.url = action.url
            return state

        case ToolbarActionType.backButtonStateChanged:
            guard let isEnabled = action.isButtonEnabled else { return state }
            var state = state

            if let index = state.navigationToolbar.actions.firstIndex(where: { $0.actionType == .back }) {
                state.navigationToolbar.actions[index].isEnabled = isEnabled
            }

            if let index = state.addressToolbar.browserActions.firstIndex(where: { $0.actionType == .back }) {
                state.addressToolbar.navigationActions[index].isEnabled = isEnabled
            }

            return state

        case ToolbarActionType.forwardButtonStateChanged:
            guard let isEnabled = action.isButtonEnabled else { return state }
            var state = state

            if let index = state.navigationToolbar.actions.firstIndex(where: { $0.actionType == .forward }) {
                state.navigationToolbar.actions[index].isEnabled = isEnabled
            }

            if let index = state.addressToolbar.browserActions.firstIndex(where: { $0.actionType == .forward }) {
                state.addressToolbar.navigationActions[index].isEnabled = isEnabled
            }

            return state

        default:
            return state
        }
    }
}
