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
    var lockIconNeedsTheming: Bool
    var safeListedURLImageName: String?
    var isEditing: Bool
    var shouldShowKeyboard: Bool
    var shouldSelectSearchTerm: Bool
    var isLoading: Bool
    let readerModeState: ReaderModeState?
    let didStartTyping: Bool
    let showQRPageAction: Bool
    /// Stores the alternative search engine that the user has temporarily selected (otherwise use the default)
    let alternativeSearchEngine: SearchEngineModel?

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
        self.init(
            windowUUID: windowUUID,
            navigationActions: [],
            pageActions: [],
            browserActions: [],
            borderPosition: nil,
            url: nil,
            searchTerm: nil,
            lockIconImageName: nil,
            lockIconNeedsTheming: true,
            safeListedURLImageName: nil,
            isEditing: false,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: true,
            isLoading: false,
            readerModeState: nil,
            didStartTyping: false,
            showQRPageAction: true,
            alternativeSearchEngine: nil
        )
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionState],
         pageActions: [ToolbarActionState],
         browserActions: [ToolbarActionState],
         borderPosition: AddressToolbarBorderPosition?,
         url: URL?,
         searchTerm: String?,
         lockIconImageName: String?,
         lockIconNeedsTheming: Bool,
         safeListedURLImageName: String?,
         isEditing: Bool,
         shouldShowKeyboard: Bool,
         shouldSelectSearchTerm: Bool,
         isLoading: Bool,
         readerModeState: ReaderModeState?,
         didStartTyping: Bool,
         showQRPageAction: Bool,
         alternativeSearchEngine: SearchEngineModel?) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.pageActions = pageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.searchTerm = searchTerm
        self.lockIconImageName = lockIconImageName
        self.lockIconNeedsTheming = lockIconNeedsTheming
        self.safeListedURLImageName = safeListedURLImageName
        self.isEditing = isEditing
        self.shouldShowKeyboard = shouldShowKeyboard
        self.shouldSelectSearchTerm = shouldSelectSearchTerm
        self.isLoading = isLoading
        self.readerModeState = readerModeState
        self.didStartTyping = didStartTyping
        self.showQRPageAction = showQRPageAction
        self.alternativeSearchEngine = alternativeSearchEngine
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleDidLoadToolbarsAction(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleNumberOfTabsChangedAction(state: state, action: action)

        case ToolbarActionType.readerModeStateChanged:
            return handleReaderModeStateChangedAction(state: state, action: action)

        case ToolbarActionType.websiteLoadingStateDidChange:
            return handleWebsiteLoadingStateDidChangeAction(state: state, action: action)

        case ToolbarActionType.urlDidChange:
            return handleUrlDidChangeAction(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleBackForwardButtonStateChangedAction(state: state, action: action)

        case ToolbarActionType.traitCollectionDidChange:
            return handleTraitCollectionDidChangeAction(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleShowMenuWarningBadgeAction(state: state, action: action)

        case ToolbarActionType.borderPositionChanged,
            ToolbarActionType.toolbarPositionChanged:
            return handlePositionChangedAction(state: state, action: action)

        case ToolbarActionType.didPasteSearchTerm:
            return handleDidPasteSearchTermAction(state: state, action: action)

        case ToolbarActionType.didStartEditingUrl:
            return handleDidStartEditingUrlAction(state: state, action: action)

        case ToolbarActionType.cancelEdit:
            return handleCancelEditAction(state: state, action: action)

        case ToolbarActionType.didSetTextInLocationView:
            return handleDidSetTextInLocationViewAction(state: state, action: action)

        case ToolbarActionType.hideKeyboard:
            return handleHideKeyboardAction(state: state)

        case ToolbarActionType.clearSearch:
            return handleClearSearchAction(state: state, action: action)

        case ToolbarActionType.didDeleteSearchTerm:
            return handleDidDeleteSearchTermAction(state: state, action: action)

        case ToolbarActionType.didEnterSearchTerm:
            return handleDidEnterSearchTermAction(state: state, action: action)

        case ToolbarActionType.didStartTyping:
            return handleDidStartTypingAction(state: state, action: action)

        case SearchEngineSelectionActionType.didTapSearchEngine:
            return handleDidTapSearchEngine(state: state, action: action)

        case SearchEngineSelectionMiddlewareActionType.didClearAlternativeSearchEngine:
            return handleDidClearAlternativeSearchEngine(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func handleDidLoadToolbarsAction(state: Self, action: Action) -> Self {
        guard let borderPosition = (action as? ToolbarAction)?.addressBorderPosition else {
            return defaultState(from: state)
        }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: [ToolbarActionState](),
            pageActions: [qrCodeScanAction],
            browserActions: [tabsAction(), menuAction()],
            borderPosition: borderPosition,
            url: nil,
            searchTerm: nil,
            lockIconImageName: nil,
            lockIconNeedsTheming: true,
            safeListedURLImageName: nil,
            isEditing: false,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: true,
            isLoading: false,
            readerModeState: nil,
            didStartTyping: false,
            showQRPageAction: true,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleNumberOfTabsChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: browserActions(action: toolbarAction, addressBarState: state),
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleReaderModeStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let lockIconImageName = toolbarAction.readerModeState == .active ? nil : state.lockIconImageName

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
            lockIconImageName: lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: toolbarAction.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleWebsiteLoadingStateDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: toolbarAction.isLoading ?? state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleUrlDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let showQRPageAction = toolbarAction.url == nil

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            pageActions: pageActions(action: toolbarAction,
                                     addressBarState: state,
                                     isEditing: state.isEditing,
                                     showQRPageAction: showQRPageAction),
            browserActions: browserActions(action: toolbarAction, addressBarState: state),
            borderPosition: state.borderPosition,
            url: toolbarAction.url,
            searchTerm: nil,
            lockIconImageName: toolbarAction.lockIconImageName ?? state.lockIconImageName,
            lockIconNeedsTheming: toolbarAction.lockIconNeedsTheming ?? state.lockIconNeedsTheming,
            safeListedURLImageName: toolbarAction.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleBackForwardButtonStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleTraitCollectionDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleShowMenuWarningBadgeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            pageActions: pageActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state),
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handlePositionChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: toolbarAction.addressBorderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidPasteSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: false,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: false,
            showQRPageAction: isEmptySearch,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidStartEditingUrlAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: true,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: false,
            showQRPageAction: showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleCancelEditAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: false,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: true,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: false,
            showQRPageAction: showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidSetTextInLocationViewAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

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
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: false,
            showQRPageAction: isEmptySearch,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleHideKeyboardAction(state: Self) -> Self {
        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleClearSearchAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction,
                                     addressBarState: state,
                                     isEditing: true,
                                     showQRPageAction: true),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: nil,
            searchTerm: nil,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: true,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidDeleteSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction,
                                     addressBarState: state,
                                     isEditing: true,
                                     showQRPageAction: true),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: true,
            showQRPageAction: true,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidEnterSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: pageActions(action: toolbarAction,
                                     addressBarState: state,
                                     isEditing: true,
                                     showQRPageAction: false),
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: true,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: true,
            showQRPageAction: false,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidStartTypingAction(state: Self, action: Action) -> Self {
        guard action is ToolbarAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: true,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
        )
    }

    private static func handleDidTapSearchEngine(state: Self, action: Action) -> Self {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction,
              let selectedSearchEngine = searchEngineSelectionAction.selectedSearchEngine
        else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: selectedSearchEngine
        )
    }

    private static func handleDidClearAlternativeSearchEngine(state: Self, action: Action) -> Self {
        guard action is SearchEngineSelectionAction else { return defaultState(from: state) }

        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: nil
        )
    }

    static func defaultState(from state: AddressBarState) -> Self {
        return AddressBarState(
            windowUUID: state.windowUUID,
            navigationActions: state.navigationActions,
            pageActions: state.pageActions,
            browserActions: state.browserActions,
            borderPosition: state.borderPosition,
            url: state.url,
            searchTerm: state.searchTerm,
            lockIconImageName: state.lockIconImageName,
            lockIconNeedsTheming: state.lockIconNeedsTheming,
            safeListedURLImageName: state.safeListedURLImageName,
            isEditing: state.isEditing,
            shouldShowKeyboard: state.shouldShowKeyboard,
            shouldSelectSearchTerm: state.shouldSelectSearchTerm,
            isLoading: state.isLoading,
            readerModeState: state.readerModeState,
            didStartTyping: state.didStartTyping,
            showQRPageAction: state.showQRPageAction,
            alternativeSearchEngine: state.alternativeSearchEngine
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
            // back caret when in edit mode
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

        let isURLDidChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let isShowingTopTabs = action.isShowingTopTabs ?? toolbarState.isShowingTopTabs
        let isHomepage = (isURLDidChangeAction ? action.url : toolbarState.addressToolbar.url) == nil

        if !isShowingTopTabs, !isHomepage {
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
