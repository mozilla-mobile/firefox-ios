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
    var lockIconImageName: String
    var isEditing: Bool
    var isLoading: Bool

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  navigationActions: [],
                  pageActions: [],
                  browserActions: [],
                  borderPosition: nil,
                  url: nil,
                  lockIconImageName: "",
                  isEditing: false,
                  isLoading: false)
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionState],
         pageActions: [ToolbarActionState],
         browserActions: [ToolbarActionState],
         borderPosition: AddressToolbarBorderPosition?,
         url: URL?,
         lockIconImageName: String,
         isEditing: Bool = false,
         isLoading: Bool = false) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.lockIconImageName = lockIconImageName
        self.isEditing = isEditing
        self.isLoading = isLoading
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
                borderPosition: model.borderPosition ?? state.borderPosition,
                url: model.url,
                lockIconImageName: model.lockIconImageName ?? state.lockIconImageName
            )

        case ToolbarActionType.numberOfTabsChanged:
            guard let addressToolbarModel = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: addressToolbarModel.browserActions ?? state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName
            )

        case ToolbarActionType.addressToolbarActionsDidChange:
            guard let addressToolbarModel = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: addressToolbarModel.browserActions ?? state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing
            )

        case ToolbarActionType.urlDidChange:
            guard let addressToolbarModel = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: addressToolbarModel.url,
                lockIconImageName: addressToolbarModel.lockIconImageName ?? state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing
            )

        case ToolbarActionType.backForwardButtonStatesChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }
            var addressToolbarModel = toolbarAction.addressToolbarModel

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel?.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel?.pageActions ?? state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName
            )

        case ToolbarActionType.showMenuWarningBadge:
            let browserActions = (action as? ToolbarAction)?.addressToolbarModel?.browserActions

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: browserActions ?? state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName
            )

        case ToolbarActionType.scrollOffsetChanged,
            ToolbarActionType.toolbarPositionChanged:
            let borderPosition = (action as? ToolbarAction)?.addressToolbarModel?.borderPosition

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName
            )

        default:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                lockIconImageName: state.lockIconImageName
            )
        }
    }
}
