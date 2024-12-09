// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var isPrivateMode: Bool
    var addressToolbar: AddressBarState
    var navigationToolbar: NavigationBarState
    let isShowingNavigationToolbar: Bool
    let isShowingTopTabs: Bool
    let canGoBack: Bool
    let canGoForward: Bool
    var numberOfTabs: Int
    var showMenuWarningBadge: Bool
    var isNewTabFeatureEnabled: Bool
    var canShowDataClearanceAction: Bool
    var canShowNavigationHint: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = store.state.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: toolbarState.windowUUID,
                  toolbarPosition: toolbarState.toolbarPosition,
                  isPrivateMode: toolbarState.isPrivateMode,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar,
                  isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
                  isShowingTopTabs: toolbarState.isShowingTopTabs,
                  canGoBack: toolbarState.canGoBack,
                  canGoForward: toolbarState.canGoForward,
                  numberOfTabs: toolbarState.numberOfTabs,
                  showMenuWarningBadge: toolbarState.showMenuWarningBadge,
                  isNewTabFeatureEnabled: toolbarState.isNewTabFeatureEnabled,
                  canShowDataClearanceAction: toolbarState.canShowDataClearanceAction,
                  canShowNavigationHint: toolbarState.canShowNavigationHint
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            isPrivateMode: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID),
            isShowingNavigationToolbar: true,
            isShowingTopTabs: false,
            canGoBack: false,
            canGoForward: false,
            numberOfTabs: 1,
            showMenuWarningBadge: false,
            isNewTabFeatureEnabled: false,
            canShowDataClearanceAction: false,
            canShowNavigationHint: false
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        isPrivateMode: Bool,
        addressToolbar: AddressBarState,
        navigationToolbar: NavigationBarState,
        isShowingNavigationToolbar: Bool,
        isShowingTopTabs: Bool,
        canGoBack: Bool,
        canGoForward: Bool,
        numberOfTabs: Int,
        showMenuWarningBadge: Bool,
        isNewTabFeatureEnabled: Bool,
        canShowDataClearanceAction: Bool,
        canShowNavigationHint: Bool
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.isPrivateMode = isPrivateMode
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.numberOfTabs = numberOfTabs
        self.showMenuWarningBadge = showMenuWarningBadge
        self.isNewTabFeatureEnabled = isNewTabFeatureEnabled
        self.canShowDataClearanceAction = canShowDataClearanceAction
        self.canShowNavigationHint = canShowNavigationHint
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case ToolbarActionType.didLoadToolbars:
            return handleDidLoadToolbars(state: state, action: action)

        case ToolbarActionType.borderPositionChanged, ToolbarActionType.urlDidChange,
            ToolbarActionType.didSetTextInLocationView, ToolbarActionType.didPasteSearchTerm,
            ToolbarActionType.didStartEditingUrl, ToolbarActionType.cancelEdit,
            ToolbarActionType.hideKeyboard, ToolbarActionType.websiteLoadingStateDidChange,
            ToolbarActionType.searchEngineDidChange, ToolbarActionType.clearSearch,
            ToolbarActionType.didDeleteSearchTerm, ToolbarActionType.didEnterSearchTerm,
            ToolbarActionType.didSetSearchTerm, ToolbarActionType.didStartTyping:
            return handleToolbarUpdates(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleShowMenuWarningBadge(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleNumberOfTabsChanged(state: state, action: action)

        case ToolbarActionType.toolbarPositionChanged:
            return handleToolbarPositionChanged(state: state, action: action)

        case ToolbarActionType.readerModeStateChanged:
            return handleReaderModeStateChanged(state: state, action: action)

        case ToolbarActionType.backForwardButtonStateChanged:
            return handleBackForwardButtonStateChanged(state: state, action: action)

        case ToolbarActionType.traitCollectionDidChange:
            return handleTraitCollectionDidChange(state: state, action: action)

        case ToolbarActionType.navigationButtonDoubleTapped:
            return handleNavigationButtonDoubleTapped(state: state, action: action)

        case ToolbarActionType.navigationHintFinishedPresenting:
            return handleNavigationHintFinishedPresenting(state: state, action: action)

        case SearchEngineSelectionActionType.didTapSearchEngine,
            SearchEngineSelectionMiddlewareActionType.didClearAlternativeSearchEngine:
            return handleSearchEngineSelectionAction(state: state, action: action)

        default:
            return defaultState(from: state)
        }
    }

    private static func handleDidLoadToolbars(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction,
              let toolbarPosition = toolbarAction.toolbarPosition
        else { return defaultState(from: state) }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: position,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: toolbarAction.isNewTabFeatureEnabled ?? state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: toolbarAction.canShowDataClearanceAction ?? state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleToolbarUpdates(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: toolbarAction.isPrivate ?? state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
            canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
            canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleShowMenuWarningBadge(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: toolbarAction.showMenuWarningBadge ?? state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleNumberOfTabsChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleToolbarPositionChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
        else {
            return defaultState(from: state)
        }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: position,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleReaderModeStateChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleBackForwardButtonStateChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
            canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleTraitCollectionDidChange(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func handleNavigationButtonDoubleTapped(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: true
        )
    }

    private static func handleNavigationHintFinishedPresenting(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: false
        )
    }

    private static func handleSearchEngineSelectionAction(state: Self, action: Action) -> ToolbarState {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction else {
            return defaultState(from: state)
        }

        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, searchEngineSelectionAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, searchEngineSelectionAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint
        )
    }

    private static func addressToolbarPositionFromSearchBarPosition(_ position: SearchBarPosition)
    -> AddressToolbarPosition {
        switch position {
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    static func defaultState(from state: ToolbarState) -> ToolbarState {
        return ToolbarState(windowUUID: state.windowUUID,
                            toolbarPosition: state.toolbarPosition,
                            isPrivateMode: state.isPrivateMode,
                            addressToolbar: state.addressToolbar,
                            navigationToolbar: state.navigationToolbar,
                            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                            isShowingTopTabs: state.isShowingTopTabs,
                            canGoBack: state.canGoBack,
                            canGoForward: state.canGoForward,
                            numberOfTabs: state.numberOfTabs,
                            showMenuWarningBadge: state.showMenuWarningBadge,
                            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                            canShowDataClearanceAction: state.canShowDataClearanceAction,
                            canShowNavigationHint: state.canShowNavigationHint)
    }
}
