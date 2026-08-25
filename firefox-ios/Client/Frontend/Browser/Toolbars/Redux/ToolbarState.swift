// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux
import ToolbarKit

@Copyable
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
    var numberOfTabs: Int
    var showMenuWarningBadge: Bool
    var canShowNavigationHint: Bool
    var shouldAnimate: Bool
    var isTranslucent: Bool
    var isTranslationsEnabled: Bool
    var previousTabScreenshot: UIImage?
    var nextTabScreenshot: UIImage?
    // Whether the address bar renders as its full toolbar or its minimized "pill" shape
    var isAddressBarMinimized: Bool
    // When a web form's keyboard accessory view is visible on a bottom-positioned address bar.
    var isAccessoryViewVisible: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let toolbarState = appState.componentState(
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
                  tabTrayButtonStyle: toolbarState.tabTrayButtonStyle,
                  isPrivateMode: toolbarState.isPrivateMode,
                  addressToolbar: toolbarState.addressToolbar,
                  navigationToolbar: toolbarState.navigationToolbar,
                  isShowingNavigationToolbar: toolbarState.isShowingNavigationToolbar,
                  isShowingTopTabs: toolbarState.isShowingTopTabs,
                  canGoBack: toolbarState.canGoBack,
                  canGoForward: toolbarState.canGoForward,
                  numberOfTabs: toolbarState.numberOfTabs,
                  showMenuWarningBadge: toolbarState.showMenuWarningBadge,
                  canShowNavigationHint: toolbarState.canShowNavigationHint,
                  shouldAnimate: toolbarState.shouldAnimate,
                  isTranslucent: toolbarState.isTranslucent,
                  isTranslationsEnabled: toolbarState.isTranslationsEnabled,
                  previousTabScreenshot: toolbarState.previousTabScreenshot,
                  nextTabScreenshot: toolbarState.nextTabScreenshot,
                  isAddressBarMinimized: toolbarState.isAddressBarMinimized,
                  isAccessoryViewVisible: toolbarState.isAccessoryViewVisible
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            toolbarPosition: .top,
            toolbarLayout: .version1,
            tabTrayButtonStyle: .number,
            isPrivateMode: false,
            addressToolbar: AddressBarState(windowUUID: windowUUID),
            navigationToolbar: NavigationBarState(windowUUID: windowUUID),
            isShowingNavigationToolbar: true,
            isShowingTopTabs: false,
            canGoBack: false,
            canGoForward: false,
            numberOfTabs: 1,
            showMenuWarningBadge: false,
            canShowNavigationHint: false,
            shouldAnimate: true,
            isTranslucent: false,
            isTranslationsEnabled: true,
            previousTabScreenshot: nil,
            nextTabScreenshot: nil,
            isAddressBarMinimized: false,
            isAccessoryViewVisible: false
        )
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
        showMenuWarningBadge: Bool,
        canShowNavigationHint: Bool,
        shouldAnimate: Bool,
        isTranslucent: Bool,
        isTranslationsEnabled: Bool,
        previousTabScreenshot: UIImage?,
        nextTabScreenshot: UIImage?,
        isAddressBarMinimized: Bool,
        isAccessoryViewVisible: Bool
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
        self.showMenuWarningBadge = showMenuWarningBadge
        self.canShowNavigationHint = canShowNavigationHint
        self.shouldAnimate = shouldAnimate
        self.isTranslucent = isTranslucent
        self.isTranslationsEnabled = isTranslationsEnabled
        self.previousTabScreenshot = previousTabScreenshot
        self.nextTabScreenshot = nextTabScreenshot
        self.isAddressBarMinimized = isAddressBarMinimized
        self.isAccessoryViewVisible = isAccessoryViewVisible
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        guard let action = action as? ToolbarModernAction else { return defaultState(from: state) }

        switch action {
        case .userDidScroll(let minimizeAddressBar):
            return state.copy(isAddressBarMinimized: minimizeAddressBar)

        case .accessoryViewVisibilityChanged(let isVisible):
            // Don't force-minimize while the user is editing the address bar — editing shows its
            // own overlay UI, and minimizing here would visibly shrink the bar mid-edit.
            let shouldMinimize = isVisible && !state.addressToolbar.isEditing
            return state
                .copy(isAccessoryViewVisible: isVisible)
                .copy(isAddressBarMinimized: shouldMinimize ? true : state.isAddressBarMinimized)

        case .keyboardDidHide:
            // The accessory view visible state needs to be reseted when the keyboard hides
            return state
                .copy(isAddressBarMinimized: false)
                .copy(isAccessoryViewVisible: false)

        case .didCancelKeyboardRequest:
            // AddressBarState is a nested sub-state, forwards modern call to AddressBarState
            return state.copy(addressToolbar: AddressBarState.reducer.modernReducer(state.addressToolbar,
                                                                                    action,
                                                                                    actionWindowUUID))
        }
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
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
            ToolbarActionType.lockIconChanged,
            ToolbarActionType.didSetTextInLocationView, ToolbarActionType.didPasteSearchTerm,
            ToolbarActionType.didStartEditingUrl, ToolbarActionType.cancelEdit,
            ToolbarActionType.cancelEditOnHomepage, ToolbarActionType.websiteLoadingStateDidChange,
            ToolbarMiddlewareActionType.googleLensAvailabilityDidChange, ToolbarActionType.clearSearch,
            ToolbarActionType.didDeleteSearchTerm, ToolbarActionType.didEnterSearchTerm,
            ToolbarActionType.didSetSearchTerm, ToolbarActionType.didStartTyping,
            ToolbarActionType.animationStateChanged, ToolbarActionType.translucencyDidChange,
            ToolbarActionType.readerModeStateChanged,
            ToolbarActionType.navigationMiddleButtonDidChange,
            TranslationsActionType.didStartTranslatingPage,
            TranslationsActionType.translationCompleted,
            TranslationsActionType.receivedTranslationLanguage,
            TranslationsActionType.didReceiveErrorTranslating,
            TranslationsActionType.didTranslationSettingsChange,
            ToolbarActionType.didSummarizeSettingsChange:
            return handleToolbarUpdates(state: state, action: action)

        case GeneralBrowserActionType.showToast:
            return handleShowToast(state: state, action: action)

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
        return state
            .copy(toolbarPosition: position)
            .copy(toolbarLayout: toolbarLayout)
            .copy(tabTrayButtonStyle: tabTrayButtonStyle)
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(isTranslucent: isTranslucent)
            .copy(isTranslationsEnabled: toolbarAction.isTranslationsEnabled ?? state.isTranslationsEnabled)
    }

    @MainActor
    private static func handleToolbarUpdates(state: Self, action: Action) -> ToolbarState {
        // Both `ToolbarAction` (lifecycle) and `TranslationsAction` (translation events) reach this
        // handler — translation actions carry only `isTranslationsEnabled` + payload, so every other
        // ToolbarAction-only field falls back to state when the action is not a `ToolbarAction`.
        let toolbarAction = action as? ToolbarAction
        let translationsAction = action as? TranslationsAction
        let actionIsTranslationsEnabled = toolbarAction?.isTranslationsEnabled ?? translationsAction?.isTranslationsEnabled

        return state
            .copy(isPrivateMode: toolbarAction?.isPrivate ?? state.isPrivateMode)
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, action))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, action))
            .copy(isShowingNavigationToolbar: toolbarAction?.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar)
            .copy(isShowingTopTabs: toolbarAction?.isShowingTopTabs ?? state.isShowingTopTabs)
            .copy(canGoBack: toolbarAction?.canGoBack ?? state.canGoBack)
            .copy(canGoForward: toolbarAction?.canGoForward ?? state.canGoForward)
            .copy(shouldAnimate: toolbarAction?.shouldAnimate ?? state.shouldAnimate)
            .copy(isTranslucent: toolbarAction?.isTranslucent ?? state.isTranslucent)
            .copy(isTranslationsEnabled: actionIsTranslationsEnabled ?? state.isTranslationsEnabled)
    }

    @MainActor
    private static func handleShowToast(state: Self, action: Action) -> ToolbarState {
        guard let browserAction = action as? GeneralBrowserAction,
              browserAction.toastType == .shakeToSummarizeNotAvailable
        else { return defaultState(from: state) }

        // Update to use isAddressBarMinimized so the address bar is shown and the toast isn't presented a minimized bar.
        return state
            .copy(isAddressBarMinimized: false)
    }

    @MainActor
    private static func handleShowMenuWarningBadge(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(showMenuWarningBadge: toolbarAction.showMenuWarningBadge ?? state.showMenuWarningBadge)
    }

    @MainActor
    private static func handleNumberOfTabsChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(numberOfTabs: toolbarAction.numberOfTabs ?? state.numberOfTabs)
    }

    @MainActor
    private static func handleDidSetTabScreenshot(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(previousTabScreenshot: toolbarAction.previousTabScreenshot)
            .copy(nextTabScreenshot: toolbarAction.nextTabScreenshot)
    }

    @MainActor
    private static func handleToolbarPositionChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarPosition = (action as? ToolbarAction)?.toolbarPosition
        else {
            return defaultState(from: state)
        }

        let position = addressToolbarPositionFromSearchBarPosition(toolbarPosition)
        return state
            .copy(toolbarPosition: position)
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, action))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, action))
    }

    @MainActor
    private static func handleBackForwardButtonStateChanged(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(canGoBack: toolbarAction.canGoBack ?? state.canGoBack)
            .copy(canGoForward: toolbarAction.canGoForward ?? state.canGoForward)
    }

    @MainActor
    private static func handleTraitCollectionDidChange(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(isShowingNavigationToolbar: toolbarAction.isShowingNavigationToolbar ?? state.isShowingNavigationToolbar)
            .copy(isShowingTopTabs: toolbarAction.isShowingTopTabs ?? state.isShowingTopTabs)
    }

    @MainActor
    private static func handleNavigationButtonDoubleTapped(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(canShowNavigationHint: true)
    }

    @MainActor
    private static func handleNavigationHintFinishedPresenting(state: Self, action: Action) -> ToolbarState {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }
        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, toolbarAction))
            .copy(navigationToolbar: NavigationBarState.reducer.legacyReducer(state.navigationToolbar, toolbarAction))
            .copy(canShowNavigationHint: false)
    }

    @MainActor
    private static func handleSearchEngineSelectionAction(state: Self, action: Action) -> ToolbarState {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction else {
            return defaultState(from: state)
        }

        return state
            .copy(addressToolbar: AddressBarState.reducer.legacyReducer(state.addressToolbar, searchEngineSelectionAction))
            .copy(navigationToolbar: NavigationBarState.reducer
                .legacyReducer(state.navigationToolbar, searchEngineSelectionAction))
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
                            tabTrayButtonStyle: state.tabTrayButtonStyle,
                            isPrivateMode: state.isPrivateMode,
                            addressToolbar: state.addressToolbar,
                            navigationToolbar: state.navigationToolbar,
                            isShowingNavigationToolbar: state.isShowingNavigationToolbar,
                            isShowingTopTabs: state.isShowingTopTabs,
                            canGoBack: state.canGoBack,
                            canGoForward: state.canGoForward,
                            numberOfTabs: state.numberOfTabs,
                            showMenuWarningBadge: state.showMenuWarningBadge,
                            canShowNavigationHint: state.canShowNavigationHint,
                            shouldAnimate: state.shouldAnimate,
                            isTranslucent: state.isTranslucent,
                            isTranslationsEnabled: state.isTranslationsEnabled,
                            previousTabScreenshot: state.previousTabScreenshot,
                            nextTabScreenshot: state.nextTabScreenshot,
                            isAddressBarMinimized: state.isAddressBarMinimized,
                            isAccessoryViewVisible: state.isAccessoryViewVisible)
    }
}
