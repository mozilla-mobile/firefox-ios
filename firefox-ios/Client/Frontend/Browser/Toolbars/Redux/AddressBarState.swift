// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import CopyWithUpdates
import Redux
import ToolbarKit
import SummarizeKit

@CopyWithUpdates
struct AddressBarState: StateType, Sendable, Equatable {
    var windowUUID: WindowUUID
    var navigationActions: [ToolbarActionConfiguration]
    var leadingPageActions: [ToolbarActionConfiguration]
    var trailingPageActions: [ToolbarActionConfiguration]
    var browserActions: [ToolbarActionConfiguration]
    let borderPosition: AddressToolbarBorderPosition?
    var url: URL?
    var searchTerm: String?
    var lockIconButtonA11yId: String?
    var lockIconImageName: String?
    var lockIconNeedsTheming: Bool
    var safeListedURLImageName: String?
    var isEditing: Bool
    var shouldShowKeyboard: Bool
    var shouldSelectSearchTerm: Bool
    var isLoading: Bool
    let readerModeState: ReaderModeState?
    let canSummarize: Bool
    let didStartTyping: Bool
    let isEmptySearch: Bool
    /// Stores the alternative search engine that the user has temporarily selected (otherwise use the default)
    let alternativeSearchEngine: SearchEngineModel?
    let translationConfiguration: TranslationConfiguration?

    private static let cancelEditAction = ToolbarActionConfiguration(
        actionType: .cancelEdit,
        iconName: StandardImageIdentifiers.Large.chevronLeft,
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: AccessibilityIdentifiers.GeneralizedIdentifiers.back,
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    private static let cancelEditTextAction = ToolbarActionConfiguration(
        actionType: .cancelEdit,
        actionLabel: .CancelString, // Use .AddressToolbar.CancelEditButtonLabel starting v138 (localization)
        isFlippedForRTL: true,
        isEnabled: true,
        a11yLabel: .CancelString, // Use .AddressToolbar.CancelEditButtonLabel starting v138 (localization)
        a11yId: AccessibilityIdentifiers.Browser.UrlBar.cancelButton)

    private static let newTabAction = ToolbarActionConfiguration(
        actionType: .newTab,
        iconName: StandardImageIdentifiers.Large.plus,
        isEnabled: true,
        a11yLabel: .Toolbars.NewTabButton,
        a11yId: AccessibilityIdentifiers.Toolbar.addNewTabButton)

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            navigationActions: [],
            leadingPageActions: [],
            trailingPageActions: [],
            browserActions: [],
            borderPosition: nil,
            url: nil,
            searchTerm: nil,
            lockIconButtonA11yId: nil,
            lockIconImageName: nil,
            lockIconNeedsTheming: true,
            safeListedURLImageName: nil,
            isEditing: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            isLoading: false,
            readerModeState: nil,
            canSummarize: false,
            didStartTyping: false,
            isEmptySearch: true,
            alternativeSearchEngine: nil,
            translationConfiguration: nil
        )
    }

    init(windowUUID: WindowUUID,
         navigationActions: [ToolbarActionConfiguration],
         leadingPageActions: [ToolbarActionConfiguration],
         trailingPageActions: [ToolbarActionConfiguration],
         browserActions: [ToolbarActionConfiguration],
         borderPosition: AddressToolbarBorderPosition?,
         url: URL?,
         searchTerm: String?,
         lockIconButtonA11yId: String?,
         lockIconImageName: String?,
         lockIconNeedsTheming: Bool,
         safeListedURLImageName: String?,
         isEditing: Bool,
         shouldShowKeyboard: Bool,
         shouldSelectSearchTerm: Bool,
         isLoading: Bool,
         readerModeState: ReaderModeState?,
         canSummarize: Bool,
         didStartTyping: Bool,
         isEmptySearch: Bool,
         alternativeSearchEngine: SearchEngineModel?,
         translationConfiguration: TranslationConfiguration?) {
        self.windowUUID = windowUUID
        self.navigationActions = navigationActions
        self.leadingPageActions = leadingPageActions
        self.trailingPageActions = trailingPageActions
        self.browserActions = browserActions
        self.borderPosition = borderPosition
        self.url = url
        self.searchTerm = searchTerm
        self.lockIconButtonA11yId = lockIconButtonA11yId
        self.lockIconImageName = lockIconImageName
        self.lockIconNeedsTheming = lockIconNeedsTheming
        self.safeListedURLImageName = safeListedURLImageName
        self.isEditing = isEditing
        self.shouldShowKeyboard = shouldShowKeyboard
        self.shouldSelectSearchTerm = shouldSelectSearchTerm
        self.isLoading = isLoading
        self.readerModeState = readerModeState
        self.didStartTyping = didStartTyping
        self.isEmptySearch = isEmptySearch
        self.alternativeSearchEngine = alternativeSearchEngine
        self.canSummarize = canSummarize
        self.translationConfiguration = translationConfiguration
    }

    // swiftlint:disable:next closure_body_length
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

        case ToolbarActionType.didSetTabScreenshot:
            return handleDidSetTabScreenshotAction(state: state, action: action)

        // Translation related actions
        case ToolbarActionType.didStartTranslatingPage,
            ToolbarActionType.translationCompleted,
            ToolbarActionType.receivedTranslationLanguage,
            ToolbarActionType.didReceiveErrorTranslating,
            ToolbarActionType.didTranslationSettingsChange:
            return handleLeadingPageChangedAction(state: state, action: action)

        case ToolbarActionType.didSummarizeSettingsChange:
            return handleSummarizeStateChangedAction(state: state, action: action)

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

        case ToolbarActionType.cancelEditOnHomepage:
            return handleCancelEditOnHomepageAction(state: state, action: action)

        case ToolbarActionType.cancelEdit:
            return handleCancelEditAction(state: state, action: action)

        case ToolbarActionType.didSetTextInLocationView:
            return handleDidSetTextInLocationViewAction(state: state, action: action)

        case ToolbarActionType.keyboardStateDidChange:
            return handleShouldShowKeyboardAction(state: state, action: action)

        case ToolbarActionType.clearSearch:
            return handleClearSearchAction(state: state, action: action)

        case ToolbarActionType.didDeleteSearchTerm:
            return handleDidDeleteSearchTermAction(state: state, action: action)

        case ToolbarActionType.didEnterSearchTerm:
            return handleDidEnterSearchTermAction(state: state, action: action)

        case ToolbarActionType.didSetSearchTerm:
            return handleDidSetSearchTermAction(state: state, action: action)

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

        return state.copyWithUpdates(
            navigationActions: [ToolbarActionConfiguration](),
            leadingPageActions: [ToolbarActionConfiguration](),
            trailingPageActions: [ToolbarActionConfiguration](),
            browserActions: [ToolbarActionConfiguration](),
            borderPosition: borderPosition,
            url: nil,
            searchTerm: nil,
            lockIconButtonA11yId: nil,
            lockIconImageName: nil,
            lockIconNeedsTheming: true,
            safeListedURLImageName: nil,
            isEditing: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            isLoading: false,
            readerModeState: nil,
            canSummarize: false,
            didStartTyping: false,
            isEmptySearch: true,
            translationConfiguration: nil,
        )
    }

    @MainActor
    private static func handleNumberOfTabsChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing)
        )
    }

    @MainActor
    private static func handleDidSetTabScreenshotAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing)
        )
    }

    @MainActor
    private static func handleLeadingPageChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else {
            return defaultState(from: state)
        }

        return state.copyWithUpdates(
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            translationConfiguration: toolbarAction.translationConfiguration
        )
    }

    @MainActor
    private static func handleSummarizeStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else {
            return defaultState(from: state)
        }

        let trailingPageActions = trailingPageActions(action: toolbarAction,
                                                      addressBarState: state,
                                                      isEditing: state.isEditing,
                                                      isEmptySearch: state.isEmptySearch)
        return state.copyWithUpdates(
            trailingPageActions: trailingPageActions,
            canSummarize: toolbarAction.canSummarize)
    }

    @MainActor
    private static func handleReaderModeStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let lockIconImageName = toolbarAction.readerModeState == .active ? nil : state.lockIconImageName
        let trailingPageActions = trailingPageActions(action: toolbarAction,
                                                      addressBarState: state,
                                                      isEditing: state.isEditing,
                                                      isEmptySearch: state.isEmptySearch)
        return state.copyWithUpdates(
            trailingPageActions: trailingPageActions,
            lockIconImageName: lockIconImageName,
            readerModeState: toolbarAction.readerModeState,
            canSummarize: toolbarAction.canSummarize
        )
    }

    @MainActor
    private static func handleWebsiteLoadingStateDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing),
            isLoading: toolbarAction.isLoading ?? state.isLoading
        )
    }

    @MainActor
    private static func handleUrlDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let isEmptySearch = toolbarAction.url == nil

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing,
                                                     isEmptySearch: isEmptySearch),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            url: toolbarAction.url,
            searchTerm: nil,
            lockIconButtonA11yId: toolbarAction.lockIconButtonA11yId ?? state.lockIconButtonA11yId,
            lockIconImageName: toolbarAction.lockIconImageName ?? state.lockIconImageName,
            lockIconNeedsTheming: toolbarAction.lockIconNeedsTheming ?? state.lockIconNeedsTheming,
            safeListedURLImageName: toolbarAction.safeListedURLImageName,
            isEmptySearch: isEmptySearch,
            translationConfiguration: resolveTranslationConfig(
                from: toolbarAction,
                existingConfig: state.translationConfiguration
            )
        )
    }

    private static func resolveTranslationConfig(
        from action: ToolbarAction,
        existingConfig: TranslationConfiguration?
    ) -> TranslationConfiguration? {
        guard let actionConfig = action.translationConfiguration else { return nil }
        if actionConfig.state == nil, let existingIconState = existingConfig?.state {
            return TranslationConfiguration(prefs: actionConfig.prefs, state: existingIconState)
        }
        return actionConfig
    }

    @MainActor
    private static func handleBackForwardButtonStateChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing),
            searchTerm: nil
        )
    }

    @MainActor
    private static func handleTraitCollectionDidChangeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing)
        )
    }

    @MainActor
    private static func handleShowMenuWarningBadgeAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing)
        )
    }

    @MainActor
    private static func handlePositionChangedAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction,
                                                 addressBarState: state,
                                                 isEditing: state.isEditing),
            leadingPageActions: leadingPageActions(action: toolbarAction,
                                                   addressBarState: state,
                                                   isEditing: state.isEditing),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: state.isEditing),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: state.isEditing),
            borderPosition: toolbarAction.addressBorderPosition
        )
    }

    @MainActor
    private static func handleDidPasteSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let isEmptySearch = toolbarAction.searchTerm == nil || toolbarAction.searchTerm?.isEmpty == true

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
            leadingPageActions: leadingPageActions(action: toolbarAction, addressBarState: state, isEditing: true),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: isEmptySearch),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: true),
            searchTerm: toolbarAction.searchTerm,
            isEditing: true,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: false,
            didStartTyping: false,
            isEmptySearch: isEmptySearch
        )
    }

    @MainActor
    private static func handleDidStartEditingUrlAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let searchTerm = toolbarAction.searchTerm ?? state.searchTerm
        let locationText = searchTerm ?? state.url?.absoluteString
        let isEmptySearch = locationText == nil || locationText?.isEmpty == true

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
            leadingPageActions: leadingPageActions(action: toolbarAction, addressBarState: state, isEditing: true),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: isEmptySearch),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: true),
            searchTerm: searchTerm,
            isEditing: true,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: true,
            didStartTyping: false,
            isEmptySearch: isEmptySearch
        )
    }

    @MainActor
    private static func handleCancelEditOnHomepageAction(state: Self, action: Action) -> Self {
        if state.url == nil {
            return handleCancelEditAction(state: state, action: action)
        } else {
            return handleShouldShowKeyboardAction(state: state, action: action)
        }
    }

    @MainActor
    private static func handleCancelEditAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let url = toolbarAction.url ?? state.url
        let isEmptySearch = url == nil

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction, addressBarState: state),
            leadingPageActions: leadingPageActions(action: toolbarAction, addressBarState: state),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: false,
                                                     isEmptySearch: isEmptySearch),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: false),
            url: url,
            searchTerm: nil,
            isEditing: false,
            shouldShowKeyboard: false,
            shouldSelectSearchTerm: false,
            didStartTyping: false,
            isEmptySearch: isEmptySearch
        )
    }

    @MainActor
    private static func handleDidSetTextInLocationViewAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        let isEmptySearch = toolbarAction.searchTerm == nil || toolbarAction.searchTerm?.isEmpty == true

        return state.copyWithUpdates(
            navigationActions: navigationActions(action: toolbarAction, addressBarState: state, isEditing: true),
            leadingPageActions: leadingPageActions(action: toolbarAction, addressBarState: state, isEditing: true),
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: isEmptySearch),
            browserActions: browserActions(action: toolbarAction, addressBarState: state, isEditing: true),
            searchTerm: toolbarAction.searchTerm,
            isEditing: true,
            shouldShowKeyboard: true,
            shouldSelectSearchTerm: false,
            didStartTyping: false,
            isEmptySearch: isEmptySearch
        )
    }

    /// This case can occur when scrolling on homepage or in search view
    /// and the user is still in isEditing mode (aka Cancel button is shown)
    /// But we don't show the keyboard and the cursor is not active
    private static func handleShouldShowKeyboardAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            shouldShowKeyboard: toolbarAction.shouldShowKeyboard ?? false
        )
    }

    @MainActor
    private static func handleClearSearchAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: true),
            searchTerm: nil,
            isEditing: true,
            isEmptySearch: true
        )
    }

    @MainActor
    private static func handleDidDeleteSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: true),
            isEditing: true,
            shouldSelectSearchTerm: false,
            didStartTyping: true,
            isEmptySearch: true
        )
    }

    @MainActor
    private static func handleDidEnterSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            trailingPageActions: trailingPageActions(action: toolbarAction,
                                                     addressBarState: state,
                                                     isEditing: true,
                                                     isEmptySearch: false),
            isEditing: true,
            shouldSelectSearchTerm: false,
            didStartTyping: true,
            isEmptySearch: false
        )
    }

    private static func handleDidSetSearchTermAction(state: Self, action: Action) -> Self {
        guard let toolbarAction = action as? ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            searchTerm: toolbarAction.searchTerm,
            didStartTyping: false
        )
    }

    private static func handleDidStartTypingAction(state: Self, action: Action) -> Self {
        guard action is ToolbarAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            shouldSelectSearchTerm: false,
            didStartTyping: true
        )
    }

    private static func handleDidTapSearchEngine(state: Self, action: Action) -> Self {
        guard let searchEngineSelectionAction = action as? SearchEngineSelectionAction,
              let selectedSearchEngine = searchEngineSelectionAction.selectedSearchEngine
        else { return defaultState(from: state) }

        return state.copyWithUpdates(
            alternativeSearchEngine: selectedSearchEngine
        )
    }

    private static func handleDidClearAlternativeSearchEngine(state: Self, action: Action) -> Self {
        guard action is SearchEngineSelectionAction else { return defaultState(from: state) }

        return state.copyWithUpdates(
            alternativeSearchEngine: nil
        )
    }

    static func defaultState(from state: AddressBarState) -> Self {
        return state.copyWithUpdates()
    }

    // MARK: - Address Toolbar Actions
    @MainActor
    private static func navigationActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool = false
    ) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        guard let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return actions }

        let isShowingNavigationToolbar = action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar

        if !isShowingNavigationToolbar {
            // otherwise back/forward and maybe data clearance when navigation toolbar is hidden
            let canGoBack = action.canGoBack ?? toolbarState.canGoBack
            let canGoForward = action.canGoForward ?? toolbarState.canGoForward
            actions.append(backAction(enabled: canGoBack))
            actions.append(forwardAction(enabled: canGoForward))
        }

        return actions
    }

    @MainActor
    private static func leadingPageActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool = false
    ) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        guard let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID),
              !isEditing
        else { return actions }

        let isShowingNavigationToolbar = action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar
        let isURLDidChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let isHomepage = (isURLDidChangeAction ? action.url : toolbarState.addressToolbar.url) == nil
        let isLoadingChangeAction = action.actionType as? ToolbarActionType == .websiteLoadingStateDidChange
        let isLoading = isLoadingChangeAction ? action.isLoading : addressBarState.isLoading
        let hasAlternativeLocationColor = shouldUseAlternativeLocationColor(action: action)

        if !isHomepage, !isShowingNavigationToolbar {
            let shareAction = shareAction(enabled: isLoading == false,
                                          hasAlternativeLocationColor: hasAlternativeLocationColor)
            actions.append(shareAction)

            if let translationAction = configureTranslationIcon(
                for: action,
                addressBarState: addressBarState,
                isLoading: isLoading,
                hasAlternativeLocationColor: hasAlternativeLocationColor
            ) {
                actions.append(translationAction)
            }
        } else if !isHomepage, isShowingNavigationToolbar {
            let shareAction = shareAction(enabled: isLoading == false,
                                          hasAlternativeLocationColor: hasAlternativeLocationColor)
            actions.append(shareAction)

            if let translationAction = configureTranslationIcon(
                for: action,
                addressBarState: addressBarState,
                isLoading: isLoading,
                hasAlternativeLocationColor: hasAlternativeLocationColor
            ) {
                actions.append(translationAction)
            }
        }

        return actions
    }

    // Checks whether we should show the translation icon based on the translation configuration
    // state and setups up the configuration for the translation icon on the toolbar (for iPad and iPhone)
    private static func configureTranslationIcon(
        for action: ToolbarAction,
        addressBarState: AddressBarState,
        isLoading: Bool?,
        hasAlternativeLocationColor: Bool
    ) -> ToolbarActionConfiguration? {
        // Check if action has an updated configuration, otherwise default to state.
        // We need to do this check because of existing architecture
        // in which the state is updated after
        // we configure the button, so we need to check action too.
        let isFeatureEnabledFromAction = action.translationConfiguration?.isTranslationFeatureEnabled ?? false
        let isFeatureEnabledFromState = addressBarState.translationConfiguration?.isTranslationFeatureEnabled ?? false
        let shouldShowTranslationIcon = isFeatureEnabledFromAction || isFeatureEnabledFromState
        guard shouldShowTranslationIcon else { return nil }
        let iconState = action.translationConfiguration?.state ?? addressBarState.translationConfiguration?.state
        guard let iconState else { return nil }
        return translateAction(
            enabled: isLoading == false,
            state: iconState,
            hasAlternativeLocationColor: hasAlternativeLocationColor
        )
    }

    @MainActor
    private static func trailingPageActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool,
        isEmptySearch: Bool? = nil
    ) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        let isReaderModeAction = action.actionType as? ToolbarActionType == .readerModeStateChanged
        let isSummarizeModeAction = action.actionType as? ToolbarActionType == .didSummarizeSettingsChange
        let readerModeState = isReaderModeAction ? action.readerModeState : addressBarState.readerModeState
        let canSummarize = isSummarizeModeAction || isReaderModeAction ? action.canSummarize : addressBarState.canSummarize
        let hasEmptySearchField = isEmptySearch ?? addressBarState.isEmptySearch
        let hasAlternativeLocationColor = shouldUseAlternativeLocationColor(action: action)

        guard !hasEmptySearchField, // When the search field is empty we show no actions
              !isEditing
        else { return actions }

        let summarizerNimbusUtils = DefaultSummarizerNimbusUtils()
        let isSummarizeFeatureForToolbarOn = summarizerNimbusUtils.isToolbarButtonEnabled
        let isReaderModeWithSummarizerEnabled = summarizerNimbusUtils.isLanguageExpansionEnabled && canSummarize
            && readerModeState?.isEnabled == true
        if isReaderModeWithSummarizerEnabled {
            actions.append(readerModeWithSummarizerAction(isSelected: readerModeState == .active,
                                                          hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if isSummarizeFeatureForToolbarOn, canSummarize, readerModeState == .available, !UIWindow.isLandscape {
            actions.append(summaryAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if readerModeState?.isEnabled == true {
            actions.append(readerModeAction(isSelected: readerModeState == .active,
                                            hasAlternativeLocationColor: hasAlternativeLocationColor))
        }

        let isLoadingChangeAction = action.actionType as? ToolbarActionType == .websiteLoadingStateDidChange
        let isLoading = isLoadingChangeAction ? action.isLoading : addressBarState.isLoading

        if isLoading == true {
            actions.append(stopLoadingAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        } else if isLoading == false {
            actions.append(reloadAction(hasAlternativeLocationColor: hasAlternativeLocationColor))
        }

        return actions
    }

    @MainActor
    private static func browserActions(
        action: ToolbarAction,
        addressBarState: AddressBarState,
        isEditing: Bool
    ) -> [ToolbarActionConfiguration] {
        var actions = [ToolbarActionConfiguration]()

        guard let toolbarState = store.state.componentState(ToolbarState.self,
                                                            for: .toolbar,
                                                            window: action.windowUUID)
        else { return actions }

        let isShowingNavigationToolbar = action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar
        let isURLDidChangeAction = action.actionType as? ToolbarActionType == .urlDidChange
        let isShowingTopTabs = action.isShowingTopTabs ?? toolbarState.isShowingTopTabs
        let isHomepage = (isURLDidChangeAction ? action.url : toolbarState.addressToolbar.url) == nil
        let isLoadAction = action.actionType as? ToolbarActionType == .didLoadToolbars
        let layout = isLoadAction ? action.toolbarLayout : toolbarState.toolbarLayout
        let tabTrayButtonStyle = isLoadAction ? action.tabTrayButtonStyle : toolbarState.tabTrayButtonStyle

        if isEditing {
            // cancel button when in edit mode
            actions.append(cancelEditTextAction)
        }

        // In compact only cancel action should be shown
        guard !isShowingNavigationToolbar else {
            return actions
        }

        if !isShowingTopTabs, !isHomepage {
            actions.append(newTabAction)
        }

        let numberOfTabs = action.numberOfTabs ?? toolbarState.numberOfTabs
        let isShowMenuWarningAction = action.actionType as? ToolbarActionType == .showMenuWarningBadge
        let showActionWarningBadge = action.showMenuWarningBadge ?? toolbarState.showMenuWarningBadge
        let showWarningBadge = isShowMenuWarningAction ? showActionWarningBadge : toolbarState.showMenuWarningBadge
        let menuIcon = StandardImageIdentifiers.Large.moreHorizontalRound

        let isTabScreenshotAction = action.actionType as? ToolbarActionType == .didSetTabScreenshot
        let previousTabScreenshot = isTabScreenshotAction ? action.previousTabScreenshot : toolbarState.previousTabScreenshot
        let nextTabScreenshot = isTabScreenshotAction ? action.nextTabScreenshot : toolbarState.nextTabScreenshot

        let iconName: String? = switch tabTrayButtonStyle {
        case .number, .none: StandardImageIdentifiers.Large.tab
        case .screenshot: nil
        }

        switch layout {
        case .version1, .none:
            actions.append(
                contentsOf: [
                    menuAction(iconName: menuIcon, showWarningBadge: showWarningBadge),
                    tabsAction(
                        iconName: iconName,
                        numberOfTabs: numberOfTabs,
                        isPrivateMode: toolbarState.isPrivateMode,
                        previousTabScreenshot: previousTabScreenshot,
                        nextTabScreenshot: nextTabScreenshot
                    )
                ]
            )
        case .version2:
            actions.append(
                contentsOf: [
                    tabsAction(
                        iconName: iconName,
                        numberOfTabs: numberOfTabs,
                        isPrivateMode: toolbarState.isPrivateMode,
                        previousTabScreenshot: previousTabScreenshot,
                        nextTabScreenshot: nextTabScreenshot
                    ),
                    menuAction(iconName: menuIcon, showWarningBadge: showWarningBadge)
                ]
            )
        }

        return actions
    }

    // MARK: - Helper
    @MainActor
    private static func toolbarPosition(action: ToolbarAction) -> AddressToolbarPosition? {
        guard let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return nil }

        guard action.actionType as? ToolbarActionType == .toolbarPositionChanged,
              let toolbarPosition = action.toolbarPosition
        else {
            return toolbarState.toolbarPosition
        }

        switch toolbarPosition {
        case .top: return .top
        case .bottom: return .bottom
        }
    }

    @MainActor
    private static func shouldUseAlternativeLocationColor(action: ToolbarAction) -> Bool {
        guard let toolbarState = store.state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return false }

        let isTraitCollectionDidChangeAction = action.actionType as? ToolbarActionType == .traitCollectionDidChange
        let isShowingNavigationToolbar = if isTraitCollectionDidChangeAction {
            action.isShowingNavigationToolbar ?? toolbarState.isShowingNavigationToolbar
        } else {
            toolbarState.isShowingNavigationToolbar
        }
        let isShowingTopTabs = if isTraitCollectionDidChangeAction {
            action.isShowingTopTabs ?? toolbarState.isShowingTopTabs
        } else {
            toolbarState.isShowingTopTabs
        }

        let toolbarPosition = toolbarPosition(action: action)
        return toolbarPosition == .top && !isShowingTopTabs && isShowingNavigationToolbar
    }

    private static func tabsAction(
        iconName: String?,
        numberOfTabs: Int = 1,
        isPrivateMode: Bool = false,
        previousTabScreenshot: UIImage?,
        nextTabScreenshot: UIImage?)
    -> ToolbarActionConfiguration {
        let largeContentTitle = numberOfTabs > 99 ?
            .Toolbars.TabsButtonOverflowLargeContentTitle :
            String(format: .Toolbars.TabsButtonLargeContentTitle, NSNumber(value: numberOfTabs))

        return ToolbarActionConfiguration(
            actionType: .tabs,
            iconName: iconName,
            badgeImageName: isPrivateMode ? StandardImageIdentifiers.Medium.privateModeCircleFillPurple : nil,
            maskImageName: (isPrivateMode && iconName != nil) ? ImageIdentifiers.badgeMask : nil,
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            previousTabScreenshot: previousTabScreenshot,
            nextTabScreenshot: nextTabScreenshot,
            a11yLabel: .Toolbars.TabsButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.tabsButton)
    }

    private static func menuAction(iconName: String, showWarningBadge: Bool = false) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .menu,
            iconName: iconName,
            badgeImageName: showWarningBadge ? StandardImageIdentifiers.Large.warningFill : nil,
            maskImageName: showWarningBadge ? ImageIdentifiers.menuWarningMask : nil,
            isEnabled: true,
            a11yLabel: .LegacyAppMenu.Toolbar.MenuButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
    }

    private static func backAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .back,
            iconName: StandardImageIdentifiers.Large.chevronLeft,
            isFlippedForRTL: true,
            isEnabled: enabled,
            contextualHintType: ContextualHintType.navigation.rawValue,
            a11yLabel: .TabToolbarBackAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.backButton)
    }

    private static func forwardAction(enabled: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .forward,
            iconName: StandardImageIdentifiers.Large.chevronRight,
            isFlippedForRTL: true,
            isEnabled: enabled,
            a11yLabel: .TabToolbarForwardAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.forwardButton)
    }

    private static func shareAction(enabled: Bool, hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .share,
            iconName: StandardImageIdentifiers.Medium.share,
            isEnabled: enabled,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationShareAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.shareButton)
    }

    private static func stopLoadingAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .stopLoading,
            iconName: StandardImageIdentifiers.Medium.cross,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabToolbarStopAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.stopButton)
    }

    private static func reloadAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .reload,
            iconName: StandardImageIdentifiers.Medium.arrowClockwise,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationReloadAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.reloadButton)
    }

    private static func summaryAction(hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .summarizer,
            iconName: StandardImageIdentifiers.Medium.lightning,
            isEnabled: true,
            hasCustomColor: !hasAlternativeLocationColor,
            contextualHintType: ContextualHintType.summarizeToolbarEntry.rawValue,
            a11yLabel: .Toolbars.SummarizeButtonAccessibilityLabel,
            a11yId: AccessibilityIdentifiers.Toolbar.summarizeButton)
    }

    private static func readerModeAction(isSelected: Bool,
                                         hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .readerMode,
            iconName: StandardImageIdentifiers.Medium.readerView,
            isEnabled: true,
            isSelected: isSelected,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .TabLocationReaderModeAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.readerModeButton,
            a11yCustomActionName: .TabLocationReaderModeAddToReadingListAccessibilityLabel)
    }

    private static func readerModeWithSummarizerAction(isSelected: Bool,
                                                       hasAlternativeLocationColor: Bool) -> ToolbarActionConfiguration {
        return ToolbarActionConfiguration(
            actionType: .readerModeWithSummarizer,
            iconName: StandardImageIdentifiers.Medium.readerView,
            bottomBadgeImage: UIImage(named: ImageIdentifiers.lightningBadge),
            isEnabled: true,
            isSelected: isSelected,
            hasCustomColor: !hasAlternativeLocationColor,
            a11yLabel: .Toolbars.ReaderModeWithSummarizerButtonAccessibilityLabel,
            a11yHint: .TabLocationReloadAccessibilityHint,
            a11yId: AccessibilityIdentifiers.Toolbar.readerModeWithSummarizerButton)
    }

    // Sets up translation icon on the toolbar
    //
    // We handle tapping differently for translation button by showing a loading icon
    // instead of a highlighted color.
    // If we kept the highlighted color, then it will cause the translation icon to flicker
    // when switching from inactive icon to loading icon when user taps on it. Hence, `hasHighlightedColor: false`.
    private static func translateAction(
        enabled: Bool,
        state: TranslationConfiguration.IconState,
        hasAlternativeLocationColor: Bool
    ) -> ToolbarActionConfiguration {
        // We do not want to use template mode for translate active icon.
        let isActiveState = state == .active

        return ToolbarActionConfiguration(
            actionType: .translate,
            iconName: state.buttonImageName,
            templateModeForImage: !isActiveState,
            loadingConfig: LoadingConfig(
                isLoading: state == .loading,
                a11yLabel: .Translations.Sheet.AccessibilityLabels.LoadingCompletedAccessibilityLabel
            ),
            isEnabled: enabled,
            isSelected: isActiveState,
            hasCustomColor: !hasAlternativeLocationColor,
            hasHighlightedColor: false,
            contextualHintType: ContextualHintType.translation.rawValue,
            a11yLabel: state.buttonA11yLabel,
            a11yId: state.buttonA11yIdentifier
        )
    }
}
