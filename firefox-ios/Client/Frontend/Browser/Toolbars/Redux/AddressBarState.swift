// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct AddressBarState: StateType, Equatable {
    var windowUUID: WindowUUID
    var navigationActions: [ToolbarActionState]
    var pageActions: [ToolbarActionState]
    var browserActions: [ToolbarActionState]
    var displayTopBorder: Bool
    var displayBottomBorder: Bool
    var url: URL?

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  navigationActions: [],
                  pageActions: [],
                  browserActions: [],
                  displayTopBorder: false,
                  displayBottomBorder: false,
                  url: nil)
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionState],
         pageActions: [ToolbarActionState],
         browserActions: [ToolbarActionState],
         displayTopBorder: Bool,
         displayBottomBorder: Bool,
         url: URL?) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.displayTopBorder = displayTopBorder
        self.displayBottomBorder = displayBottomBorder
        self.url = url
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let model = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: model.navigationActions ?? state.navigationActions,
                pageActions: model.pageActions ?? state.pageActions,
                browserActions: model.browserActions ?? state.browserActions,
                displayTopBorder: model.displayTopBorder ?? state.displayTopBorder,
                displayBottomBorder: model.displayBottomBorder ?? state.displayBottomBorder,
                url: model.url
            )

        case ToolbarActionType.numberOfTabsChanged:
            guard let numberOfTabs = (action as? ToolbarAction)?.numberOfTabs else { return state }

            var actions = state.browserActions

            if let index = actions.firstIndex(where: { $0.actionType == .tabs }) {
                actions[index].numberOfTabs = numberOfTabs
            }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: actions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )

        case ToolbarActionType.urlDidChange:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: (action as? ToolbarAction)?.url
            )

        case ToolbarActionType.backButtonStateChanged:
            guard let isEnabled = (action as? ToolbarAction)?.isButtonEnabled else { return state }

            var actions = state.navigationActions

            if let index = actions.firstIndex(where: { $0.actionType == .back }) {
                actions[index].isEnabled = isEnabled
            }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: actions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )

        case ToolbarActionType.forwardButtonStateChanged:
            guard let isEnabled = (action as? ToolbarAction)?.isButtonEnabled else { return state }

            var actions = state.navigationActions

            if let index = actions.firstIndex(where: { $0.actionType == .forward }) {
                actions[index].isEnabled = isEnabled
            }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: actions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )

        case ToolbarActionType.needsBorderUpdate:
            guard let displayTopBorder = (action as? ToolbarAction)?.addressToolbarModel?.displayTopBorder,
                  let displayBottomBorder = (action as? ToolbarAction)?.addressToolbarModel?.displayBottomBorder
            else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: displayTopBorder,
                displayBottomBorder: displayBottomBorder,
                url: state.url
            )

        default:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )
        }
    }
}
