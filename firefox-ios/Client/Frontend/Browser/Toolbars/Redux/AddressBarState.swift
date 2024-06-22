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
    var borderPosition: AddressToolbarBorderPosition?
    var url: URL?

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  navigationActions: [],
                  pageActions: [],
                  browserActions: [],
                  borderPosition: nil,
                  url: nil)
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionState],
         pageActions: [ToolbarActionState],
         browserActions: [ToolbarActionState],
         borderPosition: AddressToolbarBorderPosition?,
         url: URL?) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleToolbarDidLoadToolbars(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleToolbarNumberOfTabsChanged(state: state, action: action)

        case ToolbarActionType.urlDidChange:
            return handleToolbarUrlDidChange(state: state, action: action)

        case ToolbarActionType.backButtonStateChanged:
            return handleToolbarBackButtonStateChanged(state: state, action: action)

        case ToolbarActionType.forwardButtonStateChanged:
            return handleToolbarForwardButtonStateChanged(state: state, action: action)

        case ToolbarActionType.scrollOffsetChanged:
            let borderPosition = (action as? ToolbarAction)?.addressToolbarModel?.borderPosition

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: borderPosition,
                url: state.url
            )

        default:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url
            )
        }
    }

    private static func handleToolbarDidLoadToolbars(state: Self, action: Action) -> Self {
        guard let model = (action as? ToolbarAction)?.addressToolbarModel else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: model.navigationActions ?? state.navigationActions,
            pageActions: model.pageActions ?? state.pageActions,
            browserActions: model.browserActions ?? state.browserActions,
            borderPosition: model.borderPosition ?? state.borderPosition,
            url: model.url
        )
    }

    private static func handleToolbarNumberOfTabsChanged(state: Self, action: Action) -> Self {
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
            borderPosition: state.borderPosition,
            url: state.url
        )
    }

    private static func handleToolbarUrlDidChange(state: Self, action: Action) -> Self {
        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: (action as? ToolbarAction)?.url
        )
    }

    private static func handleToolbarBackButtonStateChanged(state: Self, action: Action) -> Self {
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
            borderPosition: state.borderPosition,
            url: state.url
        )
    }

    private static func handleToolbarForwardButtonStateChanged(state: Self, action: Action) -> Self {
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
            borderPosition: state.borderPosition,
            url: state.url
        )
    }
}
