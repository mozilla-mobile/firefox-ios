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
    var searchTerm: String?
    var lockIconImageName: String?
    var isEditing: Bool
    var isScrollingDuringEdit: Bool
    var shouldSelectSearchTerm: Bool
    var isLoading: Bool

    private static let qrCodeScanAction = ToolbarActionState(
        actionType: .qrCode,
        iconName: StandardImageIdentifiers.Large.qrCode,
        isEnabled: true,
        a11yLabel: .QRCode.ToolbarButtonA11yLabel,
        a11yId: AccessibilityIdentifiers.Browser.ToolbarButtons.qrCode)

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  navigationActions: [],
                  pageActions: [],
                  browserActions: [],
                  borderPosition: nil,
                  url: nil,
                  searchTerm: nil,
                  lockIconImageName: nil,
                  isEditing: false,
                  isScrollingDuringEdit: false,
                  shouldSelectSearchTerm: true,
                  isLoading: false)
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionState],
         pageActions: [ToolbarActionState],
         browserActions: [ToolbarActionState],
         borderPosition: AddressToolbarBorderPosition?,
         url: URL?,
         searchTerm: String? = nil,
         lockIconImageName: String? = nil,
         isEditing: Bool = false,
         isScrollingDuringEdit: Bool = false,
         shouldSelectSearchTerm: Bool = true,
         isLoading: Bool = false) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.searchTerm = searchTerm
        self.lockIconImageName = lockIconImageName
        self.isEditing = isEditing
        self.isScrollingDuringEdit = isScrollingDuringEdit
        self.shouldSelectSearchTerm = shouldSelectSearchTerm
        self.isLoading = isLoading
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            guard let borderPosition = (action as? ToolbarAction)?.addressBorderPosition else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: [ToolbarActionState](),
                pageActions: [qrCodeScanAction],
                browserActions: [tabsAction(), menuAction()],
                borderPosition: borderPosition,
                url: nil
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
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
            )

        case ToolbarActionType.readerModeStateChanged:
            guard let addressToolbarModel = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: addressToolbarModel.url,
                lockIconImageName: addressToolbarModel.lockIconImageName,
                isScrollingDuringEdit: state.isScrollingDuringEdit
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
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
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
                searchTerm: nil,
                lockIconImageName: addressToolbarModel.lockIconImageName ?? state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
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
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
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
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
            )

        case ToolbarActionType.scrollOffsetChanged,
            ToolbarActionType.toolbarPositionChanged:
            guard let borderPosition = (action as? ToolbarAction)?.addressBorderPosition else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
            )

        case ToolbarActionType.didPasteSearchTerm:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: toolbarAction.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: true,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: false
            )

        case ToolbarActionType.didStartEditingUrl:
            guard let action = action as? ToolbarAction,
                  let addressToolbarModel = action.addressToolbarModel
            else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: addressToolbarModel.browserActions ?? state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: action.searchTerm ?? state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing,
                isScrollingDuringEdit: false,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm
            )

        case ToolbarActionType.cancelEdit:
            guard let addressToolbarModel = (action as? ToolbarAction)?.addressToolbarModel else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: addressToolbarModel.navigationActions ?? state.navigationActions,
                pageActions: addressToolbarModel.pageActions ?? state.pageActions,
                browserActions: addressToolbarModel.browserActions ?? state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                isEditing: addressToolbarModel.isEditing ?? state.isEditing,
                isScrollingDuringEdit: false
            )

        case ToolbarActionType.didSetTextInLocationView:
            guard let toolbarAction = (action as? ToolbarAction) else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: toolbarAction.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: true,
                shouldSelectSearchTerm: false
            )

        case ToolbarActionType.didScrollDuringEdit:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: true
            )

        default:
            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit
            )
        }
    }

    // MARK: - Helper
    private static func tabsAction(numberOfTabs: Int = 1,
                                   isPrivateMode: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .tabs,
            iconName: StandardImageIdentifiers.Large.tab,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: isPrivateMode ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            a11yLabel: .TabsButtonShowTabsAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private static func menuAction(badgeImageName: String? = nil, maskImageName: String? = nil) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .menu,
            iconName: StandardImageIdentifiers.Large.appMenu,
            badgeImageName: badgeImageName,
            maskImageName: maskImageName,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }
}
