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
    var safeListedURLImageName: String?
    var isEditing: Bool
    var isScrollingDuringEdit: Bool
    var shouldSelectSearchTerm: Bool
    var isLoading: Bool
    let readerModeState: ReaderModeState?
    let didStartTyping: Bool
    let showQRPageAction: Bool

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
        contextualHintType: ContextualHintType.dataClearance.rawValue,
        a11yLabel: .TabToolbarDataClearanceAccessibilityLabel,
        a11yId: AccessibilityIdentifiers.Toolbar.fireButton)

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
         url: URL?,
         searchTerm: String? = nil,
         lockIconImageName: String? = nil,
         safeListedURLImageName: String? = nil,
         isEditing: Bool = false,
         isScrollingDuringEdit: Bool = false,
         shouldSelectSearchTerm: Bool = true,
         isLoading: Bool = false,
         readerModeState: ReaderModeState? = nil,
         didStartTyping: Bool = false,
         showQRPageAction: Bool = true) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.searchTerm = searchTerm
        self.lockIconImageName = lockIconImageName
        self.safeListedURLImageName = safeListedURLImageName
        self.isEditing = isEditing
        self.isScrollingDuringEdit = isScrollingDuringEdit
        self.shouldSelectSearchTerm = shouldSelectSearchTerm
        self.isLoading = isLoading
        self.readerModeState = readerModeState
        self.didStartTyping = didStartTyping
        self.showQRPageAction = showQRPageAction
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleToolbarDidLoadToolbars(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleToolbarNumberOfTabsChanged(state: state, action: action)

        case ToolbarActionType.readerModeStateChanged:
            return handleToolbarReaderModeStateChanged(state: state, action: action)

        case ToolbarActionType.websiteLoadingStateDidChange:
            return handleToolbarWebsiteLoadingStateDidChange(state: state, action: action)

        case ToolbarActionType.urlDidChange:
            return handleToolbarUrlDidChange(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleToolbarBackForwardButtonStateChanged(state: state, action: action)

        case ToolbarActionType.traitCollectionDidChange:
            return handleToolbarTraitCollectionDidChange(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleToolbarShowMenuWarningBadge(state: state, action: action)

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
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: state.didStartTyping,
                showQRPageAction: state.showQRPageAction
            )

        case ToolbarActionType.didPasteSearchTerm:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            let isEmptySearch = toolbarAction.searchTerm == nil || toolbarAction.searchTerm?.isEmpty == true

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: true,
                                         showQRPageAction: isEmptySearch),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: toolbarAction.searchTerm,
                lockIconImageName: state.lockIconImageName,
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: true,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: false,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: false,
                showQRPageAction: isEmptySearch
            )

        case ToolbarActionType.didStartEditingUrl:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            let searchTerm = toolbarAction.searchTerm ?? state.searchTerm
            let locationText = searchTerm ?? state.url?.absoluteString
            let showQRPageAction = locationText == nil || locationText?.isEmpty == true

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: true,
                                         showQRPageAction: showQRPageAction),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: searchTerm,
                lockIconImageName: state.lockIconImageName,
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: true,
                isScrollingDuringEdit: false,
                shouldSelectSearchTerm: true,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: false,
                showQRPageAction: showQRPageAction
            )

        case ToolbarActionType.cancelEdit:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            let url = toolbarAction.url ?? state.url
            let showQRPageAction = url == nil

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: false,
                                         showQRPageAction: showQRPageAction),
                browserActions: browserActions(action: toolbarAction, addressBarState: state),
                borderPosition: state.borderPosition,
                url: url,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: false,
                isScrollingDuringEdit: false,
                shouldSelectSearchTerm: true,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: false,
                showQRPageAction: showQRPageAction
            )

        case ToolbarActionType.didSetTextInLocationView:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            let isEmptySearch = toolbarAction.searchTerm == nil || toolbarAction.searchTerm?.isEmpty == true

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: true,
                                         showQRPageAction: isEmptySearch),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: toolbarAction.searchTerm,
                lockIconImageName: state.lockIconImageName,
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: true,
                shouldSelectSearchTerm: false,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: false,
                showQRPageAction: isEmptySearch
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
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: true,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: state.didStartTyping,
                showQRPageAction: state.showQRPageAction
            )

        case ToolbarActionType.clearSearch:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: state.isEditing,
                                         showQRPageAction: true),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: nil,
                searchTerm: nil,
                lockIconImageName: state.lockIconImageName,
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: state.didStartTyping,
                showQRPageAction: true
            )

        case ToolbarActionType.didDeleteSearchTerm:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: state.isEditing,
                                         showQRPageAction: true),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: true,
                showQRPageAction: true
            )

        case ToolbarActionType.didEnterSearchTerm:
            guard let toolbarAction = action as? ToolbarAction else { return state }

            return AddressBarState(
                windowUUID: state.windowUUID,
                navigationActions: state.navigationActions,
                pageActions: pageActions(action: toolbarAction,
                                         addressBarState: state,
                                         isEditing: state.isEditing,
                                         showQRPageAction: false),
                browserActions: state.browserActions,
                borderPosition: state.borderPosition,
                url: state.url,
                searchTerm: state.searchTerm,
                lockIconImageName: state.lockIconImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: true,
                showQRPageAction: false
            )

        case ToolbarActionType.didStartTyping:
            guard let toolbarAction = action as? ToolbarAction else { return state }

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
                readerModeState: state.readerModeState,
                didStartTyping: true,
                showQRPageAction: state.showQRPageAction
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
                safeListedURLImageName: state.safeListedURLImageName,
                isEditing: state.isEditing,
                isScrollingDuringEdit: state.isScrollingDuringEdit,
                shouldSelectSearchTerm: state.shouldSelectSearchTerm,
                isLoading: state.isLoading,
                readerModeState: state.readerModeState,
                didStartTyping: state.didStartTyping,
                showQRPageAction: state.showQRPageAction
            )
        }
    }

    private static func handleToolbarDidLoadToolbars(state: Self, action: Action) -> Self {
        guard let borderPosition = (action as? ToolbarAction)?.addressBorderPosition else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: [ToolbarActionState](),
            pageActions: [qrCodeScanAction],
            browserActions: [tabsAction(), menuAction()],
            borderPosition: borderPosition,
            url: nil
        )
    }

    private static func handleToolbarNumberOfTabsChanged(state: Self, action: Action) -> Self {
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
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: toolbarAction.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
    }

    private static func handleToolbarReaderModeStateChanged(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction,
                                     addressBarState: state,
                                     isEditing: state.isEditing,
                                     showQRPageAction: state.showQRPageAction),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: toolbarAction.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
    }

    private static func handleToolbarWebsiteLoadingStateDidChange(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: toolbarAction.isLoading ?? state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
    }

    private static func handleToolbarUrlDidChange(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state),
            borderPosition: state.borderPosition,
            url: toolbarAction.url,
            searchTerm: nil,
            lockIconImageName: toolbarAction.lockIconImageName ?? state.lockIconImageName,
            safeListedURLImageName: toolbarAction.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: toolbarAction.url == nil
        )
    }

    private static func handleToolbarBackForwardButtonStateChanged(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: nil,
            lockIconImageName: state.lockIconImageName,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
    }

    private static func handleToolbarTraitCollectionDidChange(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return state }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state),
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: nil,
            lockIconImageName: state.lockIconImageName,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
    }

    private static func handleToolbarShowMenuWarningBadge(state: Self, action: Action) -> Self {
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
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            isScrollingDuringEdit: state.isScrollingDuringEdit,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction
        )
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
        isEditing: Bool,
        showQRPageAction: Bool? = nil
    ) -> [ToolbarActionState] {
        var actions = [ToolbarActionState]()

        let isReaderModeAction = action.actionType as? ToolbarActionType == .readerModeStateChanged
        let readerModeState = isReaderModeAction ? action.readerModeState : addressBarState.readerModeState

        let showQrCodeButton = showQRPageAction ?? addressBarState.showQRPageAction

        guard !showQrCodeButton else {
            // On homepage we only show the QR code button
            return [qrCodeScanAction]
        }

        guard !isEditing else { return actions }

        switch readerModeState {
        case .active, .available:
            let isSelected = readerModeState == .active
            let iconName = isSelected ?
            StandardImageIdentifiers.Large.readerViewFill :
            StandardImageIdentifiers.Large.readerView

            let readerModeAction = ToolbarActionState(
                actionType: .readerMode,
                iconName: iconName,
                isEnabled: true,
                isSelected: isSelected,
                a11yLabel: .TabLocationReaderModeAccessibilityLabel,
                a11yHint: .TabLocationReloadAccessibilityHint,
                a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton,
                a11yCustomActionName: .TabLocationReaderModeAddToReadingListAccessibilityLabel)
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
            contextualHintType: ContextualHintType.navigation.rawValue,
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
