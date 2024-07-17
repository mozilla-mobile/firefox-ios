// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct NavigationBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var actions: [ToolbarActionState]
    var displayBorder: Bool

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  actions: [],
                  displayBorder: false)
    }

    init(windowUUID: WindowUUID,
         actions: [ToolbarActionState],
         displayBorder: Bool) {
        self.windowUUID = windowUUID
        self.actions = actions
        self.displayBorder = displayBorder
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars,
            ToolbarActionType.urlDidChange:
            guard let model = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: model.actions ?? state.actions,
                displayBorder: model.displayBorder ?? state.displayBorder
            )

        case ToolbarActionType.numberOfTabsChanged:
            guard let navToolbarModel = (action as? ToolbarAction)?.navigationToolbarModel else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: navToolbarModel.actions ?? state.actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.backButtonStateChanged:
            guard let canGoBack = (action as? ToolbarAction)?.canGoBack else { return state }

            var actions = state.actions

            if let index = actions.firstIndex(where: { $0.actionType == .back }) {
                actions[index].isEnabled = canGoBack
            }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.forwardButtonStateChanged:
            guard let canGoForward = (action as? ToolbarAction)?.canGoForward else { return state }

            var actions = state.actions

            if let index = actions.firstIndex(where: { $0.actionType == .forward }) {
                actions[index].isEnabled = canGoForward
            }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.showMenuWarningBadge:
            let badgeImageName = (action as? ToolbarAction)?.badgeImageName
            var actions = state.actions

            if let index = actions.firstIndex(where: { $0.actionType == .menu }) {
                actions[index].badgeImageName = badgeImageName
            }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: actions,
                displayBorder: state.displayBorder
            )

        case ToolbarActionType.scrollOffsetChanged,
            ToolbarActionType.toolbarPositionChanged:
            guard let displayBorder = (action as? ToolbarAction)?.navigationToolbarModel?.displayBorder
            else { return state }

            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: state.actions,
                displayBorder: displayBorder
            )

        default:
            return NavigationBarState(
                windowUUID: state.windowUUID,
                actions: state.actions,
                displayBorder: state.displayBorder
            )
        }
    }
}
