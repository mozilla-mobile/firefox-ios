// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct AddressState: StateType, Equatable {
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

            return AddressState(
                windowUUID: state.windowUUID,
                navigationActions: model.navigationActions,
                pageActions: model.pageActions,
                browserActions: model.browserActions,
                displayTopBorder: model.displayTopBorder,
                displayBottomBorder: model.displayBottomBorder,
                url: model.url
            )

        case ToolbarActionType.numberOfTabsChanged:
            guard let numberOfTabs = (action as? ToolbarAction)?.numberOfTabs else { return state }

            var actions = state.browserActions

            if let index = actions.firstIndex(where: { $0.actionType == .tabs }) {
                actions[index].numberOfTabs = numberOfTabs
            }

            return AddressState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: actions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )

        case ToolbarActionType.urlDidChange:
            return AddressState(
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

            return AddressState(
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

            return AddressState(
                windowUUID: state.windowUUID,
                navigationActions: actions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: state.displayTopBorder,
                displayBottomBorder: state.displayBottomBorder,
                url: state.url
            )

        default:
            return AddressState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                displayTopBorder: false,
                displayBottomBorder: false,
                url: nil
            )
        }
    }
}
