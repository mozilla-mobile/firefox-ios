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
    let readerModeState: ReaderModeState?

    private static let qrCodeScanAction = ToolbarActionState(
        actionType: .qrCode,
        iconName: StandardImageIdentifiers.Large.qrCode,
        isEnabled: true,
        a11yLabel: .QRCode.ToolbarButtonA11yLabel,
        a11yId: AccessibilityIdentifiers.Browser.ToolbarButtons.qrCode)

    private static let shareAction = ToolbarActionState(
        actionType: .share,
        iconName: StandardImageIdentifiers.Large.share,
        isEnabled: true,
        a11yLabel: .TabLocationShareAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.shareButton)

    private static let stopLoadingAction = ToolbarActionState(
        actionType: .stopLoading,
        iconName: StandardImageIdentifiers.Large.cross,
        isEnabled: true,
        a11yLabel: .TabToolbarStopAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.stopButton)

    private static let reloadAction = ToolbarActionState(
        actionType: .reload,
        iconName: StandardImageIdentifiers.Large.arrowClockwise,
        isEnabled: true,
        a11yLabel: .TabLocationReloadAccessibilityLabel,
        a11yHint: .TabLocationReloadAccessibilityHint,
        a11yId: AccessibilityIdentifiers.Toolbar.reloadButton)

    private static let cancelEditAction = ToolbarActionState(
        actionType: .cancelEdit,
        iconName: StandardImageIdentifiers.Large.chevronLeft,
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: AccessibilityIdentifiers.GeneralizedIdentifiers.back,
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    private static let newTabAction = ToolbarActionState(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    private static let dataClearanceAction = ToolbarActionState(
        actionType: .dataClearance,
        iconName: StandardImageIdentifiers.Large.dataClearance,
        isEnabled: true,
        hasContextualHint: true,
        a11yLabel: .TabToolbarDataClearanceAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.fireButton)

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
                  isLoading: false,
                  readerModeState: nil)
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
         isLoading: Bool = false,
         readerModeState: ReaderModeState? = nil) {
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
        self.readerModeState = readerModeState
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
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: toolbarAction.readerModeState
            )

        case ToolbarActionType.readerModeStateChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: false),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: toolbarAction.readerModeState
            )

        case ToolbarActionType.websiteLoadingStateDidChange:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: false),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: toolbarAction.isLoading ?? state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.urlDidChange:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: false),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: toolbarAction.url,
                searchTerm: nil,
                lockIconImageName: toolbarAction.lockIconImageName ?? state.lockIconImageName,
                isEditing: false,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.backButtonStateChanged,
            ToolbarActionType.forwardButtonStateChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: false),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                isEditing: false,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.traitCollectionDidChange:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.showMenuWarningBadge:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: state.pageActions,
                browserActions: state.browserActions,
                borderPosition: toolbarAction.addressBorderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
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
                shouldSelectSearchTerm: false,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.didStartEditingUrl:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: true),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: toolbarAction.searchTerm ?? state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: true,
                isScrollingDuringEdit: false,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.cancelEdit:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
                pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: true),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                isEditing: false,
                isScrollingDuringEdit: false,
                shouldSelectSearchTerm: false,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )

        case ToolbarActionType.didSetTextInLocationView:
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
                shouldSelectSearchTerm: false,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
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
                isScrollingDuringEdit: true,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
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
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState
            )
        }
    }

    // MARK: - Address Toolbar Actions
    private static func navigationActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool = false
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        guard let toolbarState = store.state.screenState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return actions }

        let isShowingNavigationToolbar = action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar

        if isEditing {
            // back carrot when in edit mode
            actions.append(cancelEditAction)
        } else if !isShowingNavigationToolbar {
            // otherwise back/forward and maybe data clearance when navigation toolbar is hidden
            let canGoBack = action.canGoBack ?? toolbarState.canGoBack
            let canGoForward = action.canGoForward ?? toolbarState.canGoForward
            actions.append(backAction(enabled: canGoBack))
            actions.append(forwardAction(enabled: canGoForward))

            if toolbarState.canShowDataClearanceAction && toolbarState.isPrivateMode {
                actions.append(dataClearanceAction)
            }
        }

        return actions
    }

    private static func pageActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        let isUrlChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let isReaderModeAction = action.actionType as? ToolbarActionType == .readerModeStateChanged
        let readerModeState = isReaderModeAction ? action.readerModeState : addressBarState.readerModeState
        let url = isUrlChangeAction ? action.url : addressBarState.url

        guard url != nil, !isEditing else {
            // On homepage we only show the QR code button
            return [qrCodeScanAction]
        }

        switch readerModeState {
        case .active, .available:
            var readerModeAction = ToolbarActionState(
                actionType: .readerMode,
                iconName: StandardImageIdentifiers.Large.readerView,
                isEnabled: true,
                a11yLabel: .TabLocationReaderModeAccessibilityLabel,
                a11yHint: .TabLocationReloadAccessibilityHint,
                a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton,
                a11yCustomActionName: .TabLocationReaderModeAddToReadingListAccessibilityLabel)
            readerModeAction.shouldDisplayAsHighlighted = readerModeState == .active
            actions.append(readerModeAction)
        default: break
        }

        actions.append(shareAction)

        let isLoadingChangeAction = action.actionType as? ToolbarActionType == .websiteLoadingStateDidChange
        let isLoading = isLoadingChangeAction ? action.isLoading : addressBarState.isLoading

        if isLoading == true {
            actions.append(stopLoadingAction)
        } else if isLoading == false {
            actions.append(reloadAction)
        }

        return actions
    }

    private static func browserActions(
        action: ToolbarAction,
        addressBarState: AddressBarState
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        guard let toolbarState = store.state.screenState(ToolbarState.self,
                                                         for: .toolbar,
                                                         window: action.windowUUID)
        else { return actions }

        if !(action.isShowingTopTabs ?? toolbarState.isShowingTopTabs) {
            actions.append(newTabAction)
        }

        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs
        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let showActionWarningBadge = action.showMenuWarningBadge ?? toolbarState.showMenuWarningBadge
        let showWarningBadge = isShowMenuWarningAction ? showActionWarningBadge : toolbarState.showMenuWarningBadge

        actions.append(contentsOf: [
            tabsAction(numberOfTabs: numberOfTabs, isPrivateMode: toolbarState.isPrivateMode),
            menuAction(showWarningBadge: showWarningBadge)
        ])

        return actions
    }

    // MARK: - Helper
    private static func tabsAction(
        numberOfTabs: Int = 1,
        isPrivateMode: Bool = false)
    -> ToolbarActionState {
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

    private static func menuAction(showWarningBadge: Bool = false) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .menu,
            iconName: StandardImageIdentifiers.Large.appMenu,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private static func backAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.back,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    private static func forwardAction(enabled: Bool) -> ToolbarActionState {
        return ToolbarActionState(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.forward,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }
}
