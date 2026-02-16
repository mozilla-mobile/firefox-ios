// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit

struct ToolbarState: ScreenState, Sendable {
    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var toolbarLayout: ToolbarLayoutStyle
    var isPrivateMode: Bool
    var addressToolbar: AddressBarState
    var navigationToolbar: NavigationBarState
    let isShowingNavigationToolbar: Bool
    let isShowingTopTabs: Bool
    let canGoBack: Bool
    let canGoForward: Bool
    let scrollAlpha: Float
    var numberOfTabs: Int
    var showMenuWarningBadge: Bool
    var isNewTabFeatureEnabled: Bool
    var canShowDataClearanceAction: Bool
    var canShowNavigationHint: Bool
    var shouldAnimate: Bool
    var isTranslucent: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = appState.screenState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: toolbarState.windowUUID,
                  toolbarPosition: toolbarState.toolbarPosition,
                  toolbarLayout: toolbarState.toolbarLayout,
                  isPrivateMode: toolbarState.isPrivateMode,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar,
                  isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
                  isShowingTopTabs: toolbarState.isShowingTopTabs,
                  canGoBack: toolbarState.canGoBack,
                  canGoForward: toolbarState.canGoForward,
                  numberOfTabs: toolbarState.numberOfTabs,
                  scrollAlpha: toolbarState.scrollAlpha,
                  showMenuWarningBadge: toolbarState.showMenuWarningBadge,
                  isNewTabFeatureEnabled: toolbarState.isNewTabFeatureEnabled,
                  canShowDataClearanceAction: toolbarState.canShowDataClearanceAction,
                  canShowNavigationHint: toolbarState.canShowNavigationHint,
                  shouldAnimate: toolbarState.shouldAnimate,
                  isTranslucent: toolbarState.isTranslucent
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            toolbarLayout: .version1,
            isPrivateMode: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID),
            isShowingNavigationToolbar: true,
            isShowingTopTabs: false,
            canGoBack: false,
            canGoForward: false,
            numberOfTabs: 1,
            scrollAlpha: 1,
            showMenuWarningBadge: false,
            isNewTabFeatureEnabled: false,
            canShowDataClearanceAction: false,
            canShowNavigationHint: false,
            shouldAnimate: true,
            isTranslucent: false
        )
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        toolbarLayout: ToolbarLayoutStyle,
        isPrivateMode: Bool,
        addressToolbar: AddressBarState,
        navigationToolbar: NavigationBarState,
        isShowingNavigationToolbar: Bool,
        isShowingTopTabs: Bool,
        canGoBack: Bool,
        canGoForward: Bool,
        numberOfTabs: Int,
        scrollAlpha: Float,
        showMenuWarningBadge: Bool,
        isNewTabFeatureEnabled: Bool,
        canShowDataClearanceAction: Bool,
        canShowNavigationHint: Bool,
        shouldAnimate: Bool,
        isTranslucent: Bool
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.toolbarLayout = toolbarLayout
        self.isPrivateMode = isPrivateMode
        self.addressToolbar = addressToolbar
        self.navigationToolbar = navigationToolbar
        self.isShowingNavigationToolbar = isShowingNavigationToolbar
        self.isShowingTopTabs = isShowingTopTabs
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.numberOfTabs = numberOfTabs
        self.scrollAlpha = scrollAlpha
        self.showMenuWarningBadge = showMenuWarningBadge
        self.isNewTabFeatureEnabled = isNewTabFeatureEnabled
        self.canShowDataClearanceAction = canShowDataClearanceAction
        self.canShowNavigationHint = canShowNavigationHint
        self.shouldAnimate = shouldAnimate
        self.isTranslucent = isTranslucent
    }

    static let reducer: Reducer<Self> = { state, action in
        return handleReducer(state: state, action: action)
    }

    @MainActor
    private static func handleReducer(state: ToolbarState, action: Action) -> ToolbarState {
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
            ToolbarActionType.cancelEditOnHomepage,
            ToolbarActionType.keyboardStateDidChange, ToolbarActionType.websiteLoadingStateDidChange,
            ToolbarActionType.searchEngineDidChange, ToolbarActionType.clearSearch,
            ToolbarActionType.didDeleteSearchTerm, ToolbarActionType.didEnterSearchTerm,
            ToolbarActionType.didSetSearchTerm, ToolbarActionType.didStartTyping,
            ToolbarActionType.animationStateChanged, ToolbarActionType.translucencyDidChange,
            ToolbarActionType.scrollAlphaNeedsUpdate, ToolbarActionType.readerModeStateChanged,
            ToolbarActionType.navigationMiddleButtonDidChange,
            ToolbarActionType.didStartTranslatingPage,
            ToolbarActionType.translationCompleted,
            ToolbarActionType.receivedTranslationLanguage,
            ToolbarActionType.didReceiveErrorTranslating,
            ToolbarActionType.didTranslationSettingsChange,
            ToolbarActionType.didSummarizeSettingsChange:
            return handleToolbarUpdates(state: state, action: action)

        case ToolbarActionType.showMenuWarningBadge:
            return handleShowMenuWarningBadge(state: state, action: action)

        case ToolbarActionType.numberOfTabsChanged:
            return handleNumberOfTabsChanged(state: state, action: action)

        case ToolbarActionType.toolbarPositionChanged:
            return handleToolbarPositionChanged(state: state, action: action)

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

    @MainActor
    private static func handleDidLoadToolbars(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction,
              let toolbarPosition = toolbarAction.toolbarPosition,
              let toolbarLayout = toolbarAction.toolbarLayout,
              let isTranslucent = toolbarAction.isTranslucent
        else { return defaultState(from: state) }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: position,
            toolbarLayout: toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: toolbarAction.isNewTabFeatureEnabled ?? state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: toolbarAction.canShowDataClearanceAction ?? state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: isTranslucent
        )
    }

    @MainActor
    private static func handleToolbarUpdates(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: toolbarAction.isPrivate ?? state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
            canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
            canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: toolbarAction.scrollAlpha ?? state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: toolbarAction.shouldAnimate ?? state.shouldAnimate,
            isTranslucent: toolbarAction.isTranslucent ?? state.isTranslucent
        )
    }

    @MainActor
    private static func handleShowMenuWarningBadge(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: toolbarAction.showMenuWarningBadge ?? state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleNumberOfTabsChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleToolbarPositionChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
        else {
            return defaultState(from: state)
        }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: position,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleBackForwardButtonStateChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
            canGoForward: toolbarAction.canGoForward ?? state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleTraitCollectionDidChange(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleNavigationButtonDoubleTapped(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: true,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleNavigationHintFinishedPresenting(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: false,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
        )
    }

    @MainActor
    private static func handleSearchEngineSelectionAction(state: Self, action: Action) -> ToolbarState {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction else {
            return defaultState(from: state)
        }

        return ToolbarState(
            windowUUID: state.windowUUID,
            toolbarPosition: state.toolbarPosition,
            toolbarLayout: state.toolbarLayout,
            isPrivateMode: state.isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, searchEngineSelectionAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, searchEngineSelectionAction),
            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
            isShowingTopTabs: state.isShowingTopTabs,
            canGoBack: state.canGoBack,
            canGoForward: state.canGoForward,
            numberOfTabs: state.numberOfTabs,
            scrollAlpha: state.scrollAlpha,
            showMenuWarningBadge: state.showMenuWarningBadge,
            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
            canShowDataClearanceAction: state.canShowDataClearanceAction,
            canShowNavigationHint: state.canShowNavigationHint,
            shouldAnimate: state.shouldAnimate,
            isTranslucent: state.isTranslucent
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
                            toolbarLayout: state.toolbarLayout,
                            isPrivateMode: state.isPrivateMode,
                            addressToolbar: state.addressToolbar,
                            navigationToolbar: state.navigationToolbar,
                            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                            isShowingTopTabs: state.isShowingTopTabs,
                            canGoBack: state.canGoBack,
                            canGoForward: state.canGoForward,
                            numberOfTabs: state.numberOfTabs,
                            scrollAlpha: state.scrollAlpha,
                            showMenuWarningBadge: state.showMenuWarningBadge,
                            isNewTabFeatureEnabled: state.isNewTabFeatureEnabled,
                            canShowDataClearanceAction: state.canShowDataClearanceAction,
                            canShowNavigationHint: state.canShowNavigationHint,
                            shouldAnimate: state.shouldAnimate,
                            isTranslucent: state.isTranslucent)
    }
}
