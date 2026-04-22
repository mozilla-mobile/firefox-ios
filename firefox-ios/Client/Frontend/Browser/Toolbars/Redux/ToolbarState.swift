// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import ToolbarKit

@CopyWithUpdates
struct ToolbarState: ScreenState, Sendable {
    var windowUUID: WindowUUID
    var toolbarPosition: AddressToolbarPosition
    var toolbarLayout: ToolbarLayoutStyle
    var tabTrayButtonStyle: TabTrayButtonStyle
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
    var canShowNavigationHint: Bool
    var shouldAnimate: Bool
    var isTranslucent: Bool
    var previousTabScreenshot: UIImage?
    var nextTabScreenshot: UIImage?

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = appState.componentState(
            ToolbarState.self,
            for: .toolbar,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self = toolbarState.copyWithUpdates()
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.toolbarPosition = .top
        self.toolbarLayout = .version1
        self.tabTrayButtonStyle = .number
        self.isPrivateMode = false
        self.addressToolbar = AddressBarState(windowUUID: windowUUID)
        self.navigationToolbar = NavigationBarState(windowUUID: windowUUID)
        self.isShowingNavigationToolbar = true
        self.isShowingTopTabs = false
        self.canGoBack = false
        self.canGoForward = false
        self.numberOfTabs = 1
        self.scrollAlpha = 1
        self.showMenuWarningBadge = false
        self.canShowNavigationHint = false
        self.shouldAnimate = true
        self.isTranslucent = false
        self.previousTabScreenshot = nil
        self.nextTabScreenshot = nil
    }

    init(
        windowUUID: WindowUUID,
        toolbarPosition: AddressToolbarPosition,
        toolbarLayout: ToolbarLayoutStyle,
        tabTrayButtonStyle: TabTrayButtonStyle,
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
        canShowNavigationHint: Bool,
        shouldAnimate: Bool,
        isTranslucent: Bool,
        previousTabScreenshot: UIImage?,
        nextTabScreenshot: UIImage?
    ) {
        self.windowUUID = windowUUID
        self.toolbarPosition = toolbarPosition
        self.toolbarLayout = toolbarLayout
        self.tabTrayButtonStyle = tabTrayButtonStyle
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
        self.canShowNavigationHint = canShowNavigationHint
        self.shouldAnimate = shouldAnimate
        self.isTranslucent = isTranslucent
        self.previousTabScreenshot = previousTabScreenshot
        self.nextTabScreenshot = nextTabScreenshot
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

        case ToolbarActionType.didSetTabScreenshot:
            return handleDidSetTabScreenshot(state: state, action: action)

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
              let tabTrayButtonStyle = toolbarAction.tabTrayButtonStyle,
              let isTranslucent = toolbarAction.isTranslucent
        else { return defaultState(from: state) }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return state.copyWithUpdates(
            toolbarPosition: position,
            toolbarLayout: toolbarLayout,
            tabTrayButtonStyle: tabTrayButtonStyle,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isTranslucent: isTranslucent
        )
    }

    @MainActor
    private static func handleToolbarUpdates(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let isPrivateMode = toolbarAction.isPrivate ?? state.isPrivateMode
        let isShowingNavigationToolbar = toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar
        let isShowingTopTabs = toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs
        let canGoBack = toolbarAction.canGoBack ?? state.canGoBack
        let canGoForward = toolbarAction.canGoForward ?? state.canGoForward
        let scrollAlpha = toolbarAction.scrollAlpha ?? state.scrollAlpha
        let shouldAnimate = toolbarAction.shouldAnimate ?? state.shouldAnimate
        let isTranslucent = toolbarAction.isTranslucent ?? state.isTranslucent

        return state.copyWithUpdates(
            isPrivateMode: isPrivateMode,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: isShowingNavigationToolbar,
            isShowingTopTabs: isShowingTopTabs,
            canGoBack: canGoBack,
            canGoForward: canGoForward,
            scrollAlpha: scrollAlpha,
            shouldAnimate: shouldAnimate,
            isTranslucent: isTranslucent
        )
    }

    @MainActor
    private static func handleShowMenuWarningBadge(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            showMenuWarningBadge: toolbarAction.showMenuWarningBadge ?? state.showMenuWarningBadge
        )
    }

    @MainActor
    private static func handleNumberOfTabsChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs
        )
    }

    @MainActor
    private static func handleDidSetTabScreenshot(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            previousTabScreenshot: toolbarAction.previousTabScreenshot,
            nextTabScreenshot: toolbarAction.nextTabScreenshot
        )
    }

    @MainActor
    private static func handleToolbarPositionChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
        else {
            return defaultState(from: state)
        }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return state.copyWithUpdates(
            toolbarPosition: position,
            addressToolbar: AddressBarState.reducer(state.addressToolbar, action),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, action)
        )
    }

    @MainActor
    private static func handleBackForwardButtonStateChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            canGoBack: toolbarAction.canGoBack ?? state.canGoBack,
            canGoForward: toolbarAction.canGoForward ?? state.canGoForward
        )
    }

    @MainActor
    private static func handleTraitCollectionDidChange(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar,
            isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs
        )
    }

    @MainActor
    private static func handleNavigationButtonDoubleTapped(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            canShowNavigationHint: true
        )
    }

    @MainActor
    private static func handleNavigationHintFinishedPresenting(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, toolbarAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, toolbarAction),
            canShowNavigationHint: false
        )
    }

    @MainActor
    private static func handleSearchEngineSelectionAction(state: Self, action: Action) -> ToolbarState {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            addressToolbar: AddressBarState.reducer(state.addressToolbar, searchEngineSelectionAction),
            navigationToolbar: NavigationBarState.reducer(state.navigationToolbar, searchEngineSelectionAction)
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
        return state.copyWithUpdates()
    }
}
