// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

enum NavigationBarMiddleButtonType: String, Equatable, CaseIterable {
    case home
    case newTab

    var label: String {
        return switch self {
        case .home:
            .Settings.Appearance.NavigationToolbar.Home
        case .newTab:
            .Settings.Appearance.NavigationToolbar.NewTab
        }
    }

    var imageName: String {
        return switch self {
        case .home:
            StandardImageIdentifiers.Large.home
        case .newTab:
            StandardImageIdentifiers.Large.plus
        }
    }
}

@Copyable
struct NavigationBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var displayBorder: Bool
    var middleButton: NavigationBarMiddleButtonType
    var isNovaDesignEnabled: Bool

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  displayBorder: false,
                  middleButton: .newTab,
                  isNovaDesignEnabled: false)
    }

    init(windowUUID: WindowUUID,
         displayBorder: Bool,
         middleButton: NavigationBarMiddleButtonType,
         isNovaDesignEnabled: Bool) {
        self.windowUUID = windowUUID
        self.displayBorder = displayBorder
        self.middleButton = middleButton
        self.isNovaDesignEnabled = isNovaDesignEnabled
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleDidLoadToolbarsAction(state: state, action: action)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            return handlePositionChangedAction(state: state, action: action)

        case ToolbarActionType.navigationMiddleButtonDidChange:
            return handleNavigationMiddleButtonDidChange(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func handleDidLoadToolbarsAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction,
              let displayBorder = toolbarAction.displayNavBorder,
              let middleButton = toolbarAction.middleButton
        else {
            return defaultState(from: state)
        }

        return state
            .copy(displayBorder: displayBorder)
            .copy(middleButton: middleButton)
            .copy(isNovaDesignEnabled: toolbarAction.isNovaDesignEnabled ?? state.isNovaDesignEnabled)
    }

    private static func handlePositionChangedAction(state: Self, action: Action) -> Self {
        guard let displayBorder = (action as? ToolbarAction)?.displayNavBorder
        else {
            return defaultState(from: state)
        }

        return state.copy(displayBorder: displayBorder)
    }

    private static func handleNavigationMiddleButtonDidChange(state: Self, action: Action) -> Self {
        guard let middleButton = (action as? ToolbarAction)?.middleButton
        else { return defaultState(from: state) }

        return state.copy(middleButton: middleButton)
    }

    static func defaultState(from state: NavigationBarState) -> NavigationBarState {
        return NavigationBarState(
            windowUUID: state.windowUUID,
            displayBorder: state.displayBorder,
            middleButton: state.middleButton,
            isNovaDesignEnabled: state.isNovaDesignEnabled
        )
    }
}
