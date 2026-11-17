// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import SummarizeKit
import Shared

@MainActor
final class ToolbarMiddleware {
    private let toolbarHelper: ToolbarHelperInterface
    private let windowManager: WindowManager
    private let logger: Logger
    private let toolbarTelemetry: ToolbarTelemetry
    private let prefs: Prefs
    private let recentSearchProvider: RecentSearchProvider
    private let summarizerNimbusUtils: SummarizerNimbusUtils
    private let summarizerConfigFactory: SummarizerConfigFactory
    private let featureFlagsProvider: FeatureFlagProviding
    private let userPreferences: UserFeaturePreferring
    private let searchEnginesManager: SearchEnginesManagerProvider
    private var isSummarizerOn: Bool {
        return summarizerNimbusUtils.isSummarizeFeatureToggledOn
    }
    private var isAppleSummarizerEnabled: Bool {
        return summarizerNimbusUtils.isAppleSummarizerEnabled()
    }
    private var isHostedSummaryEnabled: Bool {
        return summarizerNimbusUtils.isHostedSummarizerEnabled()
    }

    init(toolbarHelper: ToolbarHelperInterface = ToolbarHelper(),
         toolbarTelemetry: ToolbarTelemetry = ToolbarTelemetry(),
         profile: Profile = AppContainer.shared.resolve(),
         summarizerNimbusUtils: SummarizerNimbusUtils = DefaultSummarizerNimbusUtils(),
         summarizerConfigFactory: SummarizerConfigFactory = SummarizerMiddleware(),
         recentSearchProvider: RecentSearchProvider? = nil,
         featureFlagsProvider: FeatureFlagProviding = AppContainer.shared.resolve(),
         userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
         searchEnginesManager: SearchEnginesManagerProvider = AppContainer.shared.resolve(SearchEnginesManager.self),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.summarizerNimbusUtils = summarizerNimbusUtils
        self.summarizerConfigFactory = summarizerConfigFactory
        self.featureFlagsProvider = featureFlagsProvider
        self.userPreferences = userPreferences
        self.searchEnginesManager = searchEnginesManager
        self.toolbarHelper = toolbarHelper
        self.toolbarTelemetry = toolbarTelemetry
        self.prefs = profile.prefs
        self.recentSearchProvider = recentSearchProvider ?? DefaultRecentSearchProvider(historyStorage: profile.places)
        self.windowManager = windowManager
        self.logger = logger
    }

    lazy var toolbarProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // Does not test any modern actions
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        if let action = action as? GeneralBrowserMiddlewareAction {
            self.resolveGeneralBrowserMiddlewareActions(action: action)
        } else if let action = action as? ToolbarMiddlewareAction {
            self.resolveToolbarMiddlewareActions(action: action, state: state)
        } else if let action = action as? ToolbarAction {
            self.resolveToolbarActions(action: action, state: state)
        }
    }

    @MainActor
    private func resolveGeneralBrowserMiddlewareActions(action: GeneralBrowserMiddlewareAction) {
        let uuid = action.windowUUID

        switch action.actionType {
        case GeneralBrowserMiddlewareActionType.browserDidLoad:
            guard let toolbarPosition = action.toolbarPosition
            else { return }

            let toolbarConfig = FxNimbus.shared.features.toolbarRefactorFeature.value()
            let toolbarLayout = ToolbarLayoutStyle.style(from: toolbarConfig.layout)
            let tabTrayButtonStyle: TabTrayButtonStyle = featureFlagsProvider.isEnabled(.tabTrayScreenshotButtonStyle)
                ? .screenshot
                : .number

            let middleButton = if let rawValue = prefs.stringForKey(PrefsKeys.Settings.navigationToolbarMiddleButton),
                                  let selectedButton = NavigationBarMiddleButtonType(rawValue: rawValue) {
                selectedButton
            } else {
                NavigationBarMiddleButtonType.newTab
            }

            toolbarTelemetry.middleButtonType(middleButton)

            let action = ToolbarAction(
                toolbarPosition: toolbarPosition,
                toolbarLayout: toolbarLayout,
                tabTrayButtonStyle: tabTrayButtonStyle,
                isTranslucent: toolbarHelper.shouldBlur(),
                middleButton: middleButton,
                isTranslationsEnabled: prefs.boolForKey(PrefsKeys.Settings.translationsFeature) ?? true,
                isNovaDesignEnabled: featureFlagsProvider.isEnabled(.novaDesign),
                windowUUID: uuid,
                actionType: ToolbarActionType.didLoadToolbars)
            store.dispatch(action)
            dispatchGoogleLensAvailability(for: uuid)

        case GeneralBrowserMiddlewareActionType.toolbarPositionChanged:
            updateToolbarPosition(action: action)

        default:
            break
        }
    }

    @MainActor
    private func resolveToolbarMiddlewareActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.actionType {
        case ToolbarMiddlewareActionType.customA11yAction:
            resolveToolbarMiddlewareCustomA11yActions(action: action, state: state)

        case ToolbarMiddlewareActionType.didTapButton:
            resolveToolbarMiddlewareButtonTapActions(action: action, state: state)

        case ToolbarMiddlewareActionType.didClearSearch:
            guard let toolbarState = state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
            else { return }
            store.dispatch(ToolbarModernAction.searchTermDidClear, forWindowUUID: action.windowUUID)
            toolbarTelemetry.clearSearchButtonTapped(isPrivate: toolbarState.isPrivateMode)

        case ToolbarMiddlewareActionType.didStartDragInteraction:
            toolbarTelemetry.dragInteractionStarted()

        case ToolbarMiddlewareActionType.didSwipeToOpenTabTray:
            toolbarTelemetry.addressBarSwiped()
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTabTray)
            store.dispatch(action)

        case ToolbarMiddlewareActionType.loadSummaryState:
            checkPageCanSummarize(action: action)

        default:
            break
        }
    }

    private func resolveToolbarActions(action: ToolbarAction, state: AppState) {
        switch action.actionType {
        case ToolbarActionType.cancelEdit:
            // When editing ends, we need to also clear the address bar's search engine selection (if not default)
            let action = SearchEngineSelectionAction(
                windowUUID: action.windowUUID,
                actionType: SearchEngineSelectionMiddlewareActionType.didClearAlternativeSearchEngine
            )
            store.dispatch(action)

        case ToolbarActionType.searchEngineDidChange, ToolbarActionType.googleLensSettingDidChange:
            dispatchGoogleLensAvailability(for: action.windowUUID)

        case ToolbarActionType.urlDidChange:
            updateGoogleLensAvailabilityIfBrowsingModeChanged(windowUUID: action.windowUUID, state: state)

        case ToolbarActionType.didSubmitSearchTerm:
            // After a user submits a search term, we want to record it in our history storage via recent search provider.
            // We only want to record when in normal mode since recent searches is not available for private mode.
            guard let toolbarState = state.componentState(
                ToolbarState.self,
                for: .toolbar,
                window: action.windowUUID
            ) else {
                return
            }

            guard let url = action.url, let searchTerm = action.searchTerm, !toolbarState.isPrivateMode else { return }
            recentSearchProvider.addRecentSearch(searchTerm, url: url.absoluteString)

        case ToolbarActionType.navigationMiddleButtonDidChange:
            guard let middleButton = action.middleButton else { return }
            toolbarTelemetry.middleButtonType(middleButton)

        default:
            break
        }
    }

    @MainActor
    private func resolveToolbarMiddlewareButtonTapActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let gestureType = action.gestureType else { return }

        switch gestureType {
        case .tap:
            handleToolbarButtonTapActions(action: action, state: state)
        case .longPress:
            handleToolbarButtonLongPressActions(action: action, state: state)
        }
    }

    func resolveToolbarMiddlewareCustomA11yActions(action: ToolbarMiddlewareAction, state: AppState) {
        switch action.buttonType {
        case .readerMode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addToReadingListLongPressAction)
            store.dispatch(action)
        default: break
        }
    }

    @MainActor
    private func handleToolbarButtonTapActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let toolbarState = state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return }

        switch action.buttonType {
        case .home:
            toolbarTelemetry.homeButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.goToHomepage)
            store.dispatch(action)

        case .newTab:
            toolbarTelemetry.oneTapNewTabButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addNewTab)
            store.dispatch(action)

        case .back:
            toolbarTelemetry.backButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateBack)
            store.dispatch(action)

        case .forward:
            toolbarTelemetry.forwardButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.navigateForward)
            store.dispatch(action)

        case .tabs:
            cancelEditMode(windowUUID: action.windowUUID)

            toolbarTelemetry.tabTrayButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTabTray)
            store.dispatch(action)

        case .trackingProtection:
            toolbarTelemetry.siteInfoButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showTrackingProtectionDetails)
            store.dispatch(action)

        case .menu:
            cancelEditMode(windowUUID: action.windowUUID)

            toolbarTelemetry.menuButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showMenu)
            store.dispatch(action)

        case .cancelEdit:
            cancelEditMode(windowUUID: action.windowUUID)

        case .readerMode, .readerModeWithSummarizer:
            recordReaderModeTelemetry(state: state,
                                      windowUUID: action.windowUUID,
                                      hasSummarizer: action.buttonType == .readerModeWithSummarizer)
            let action = NavigationBrowserAction(navigationDestination: NavigationDestination(.readerMode),
                                                 windowUUID: action.windowUUID,
                                                 actionType: NavigationBrowserActionType.tapOnReaderMode)
            store.dispatch(action)

        case .reload:
            toolbarTelemetry.refreshButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.reloadWebsite)
            store.dispatch(action)

        case .stopLoading:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.stopLoadingWebsite)
            store.dispatch(action)

        case .share:
            toolbarTelemetry.shareButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(buttonTapped: action.buttonTapped,
                                              windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showShare)
            store.dispatch(action)

        case .googleLens:
            toolbarTelemetry.googleLensButtonTapped()

        case .googleLensPhotoLibrary:
            toolbarTelemetry.googleLensContextMenuOptionSelected(option: .photoPicker)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showGoogleLensPhotoPicker)
            store.dispatch(action)

        case .googleLensTakePhoto:
            toolbarTelemetry.googleLensContextMenuOptionSelected(option: .camera)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showGoogleLensCamera)
            store.dispatch(action)

        case .search:
            toolbarTelemetry.searchButtonTapped(isPrivate: toolbarState.isPrivateMode)
            let action = ToolbarAction(windowUUID: action.windowUUID, actionType: ToolbarActionType.didStartEditingUrl)
            store.dispatch(action)

        case .summarizer:
            Task { @MainActor in
                guard let webView = windowManager.tabManager(for: action.windowUUID)?.selectedTab?.webView else { return }
                let summarizerConfig = await summarizerConfigFactory.makeConfiguration(from: webView)
                let action = GeneralBrowserAction(summarizerConfig: summarizerConfig,
                                                  summarizerTrigger: .toolbarIcon,
                                                  windowUUID: action.windowUUID,
                                                  actionType: GeneralBrowserActionType.showSummarizer)
                store.dispatch(action)
            }
        case .translate:
            // The effects of tapping on the translate button is also handled in
            // the `TranslationsMiddleware`. This is because we want to
            // separate the translations logic from the toolbar middleware.
            // And anything that needs to interact with our translations scripts
            // can listen and respond to events in that specific middleware.
            break
        default:
            break
        }
    }

    private func handleToolbarButtonLongPressActions(action: ToolbarMiddlewareAction, state: AppState) {
        guard let toolbarState = state.componentState(ToolbarState.self, for: .toolbar, window: action.windowUUID)
        else { return }

        switch action.buttonType {
        case .back:
            toolbarTelemetry.backButtonLongPressed(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showBackForwardList)
            store.dispatch(action)
        case .forward:
            toolbarTelemetry.forwardButtonLongPressed(isPrivate: toolbarState.isPrivateMode)
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.showBackForwardList)
            store.dispatch(action)
        case .readerMode:
            let action = GeneralBrowserAction(windowUUID: action.windowUUID,
                                              actionType: GeneralBrowserActionType.addToReadingListLongPressAction)
            store.dispatch(action)
        case .summarizer:
            let action = NavigationBrowserAction(navigationDestination: NavigationDestination(.readerMode),
                                                 windowUUID: action.windowUUID,
                                                 actionType: NavigationBrowserActionType.tapOnReaderMode)
            store.dispatch(action)
        case .readerModeWithSummarizer:
            Task {
                guard let webView = windowManager.tabManager(for: action.windowUUID)?.selectedTab?.webView else { return }
                let summarizerConfig = await summarizerConfigFactory.makeConfiguration(from: webView)
                let action = GeneralBrowserAction(summarizerConfig: summarizerConfig,
                                                  summarizerTrigger: .readerModeWithSummarizerButton,
                                                  windowUUID: action.windowUUID,
                                                  actionType: GeneralBrowserActionType.showSummarizer)
                store.dispatch(action)
            }
        case .translate:
            // Long-press on translate is handled in TranslationsMiddleware.
            break
        default:
            break
        }
    }

    // MARK: - Position
    private func updateToolbarPosition(action: GeneralBrowserMiddlewareAction) {
        guard let searchBarPosition = action.toolbarPosition else { return }

        let toolbarAction = ToolbarAction(toolbarPosition: searchBarPosition,
                                          windowUUID: action.windowUUID,
                                          actionType: ToolbarActionType.toolbarPositionChanged)
        store.dispatch(toolbarAction)
    }

    @MainActor
    private func checkPageCanSummarize(action: ToolbarMiddlewareAction) {
        guard let webView = windowManager.tabManager(for: action.windowUUID)?.selectedTab?.webView,
              isSummarizerOn
        else { return }

        Task { @MainActor in
            let canSummarize = await summarizerConfigFactory.makeConfiguration(from: webView) != nil
            store.dispatch(
                ToolbarAction(
                    canSummarize: canSummarize,
                    readerModeState: action.readerModeState,
                    windowUUID: action.windowUUID,
                    actionType: ToolbarActionType.readerModeStateChanged
                )
            )
        }
    }

    // MARK: - Helper
    @MainActor
    private func cancelEditMode(windowUUID: WindowUUID) {
        var url = tabManager(for: windowUUID)?.selectedTab?.url
        if let currentURL = url {
            url = (currentURL.isWebPage() && !currentURL.isReaderModeURL) ? url : nil
        }
        let action = ToolbarAction(url: url, windowUUID: windowUUID, actionType: ToolbarActionType.cancelEdit)
        store.dispatch(action)

        let browserAction = GeneralBrowserAction(showOverlay: false,
                                                 windowUUID: windowUUID,
                                                 actionType: GeneralBrowserActionType.leaveOverlay)
        store.dispatch(browserAction)
    }

    private func recordReaderModeTelemetry(state: AppState, windowUUID: WindowUUID, hasSummarizer: Bool) {
        guard let toolbarState = state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID) else { return }

        let isReaderModeEnabled = switch toolbarState.addressToolbar.readerModeState {
        case .available: true // will be enabled after action gets executed
        default: false
        }

        toolbarTelemetry.readerModeButtonTapped(isPrivate: toolbarState.isPrivateMode,
                                                isEnabled: isReaderModeEnabled,
                                                hasSummarizer: hasSummarizer)
    }

    private func tabManager(for uuid: WindowUUID) -> TabManager? {
        return windowManager.tabManager(for: uuid)
    }

    // Only re-dispatch when Google Lens availability would actually change (i.e. the browsing mode flipped it),
    // to avoid churning on every URL.
    private func updateGoogleLensAvailabilityIfBrowsingModeChanged(windowUUID: WindowUUID, state: AppState) {
        guard let toolbarState = state.componentState(ToolbarState.self, for: .toolbar, window: windowUUID)
        else { return }

        let shouldShow = isGoogleLensAvailable(for: windowUUID)
        let isShowing = toolbarState.addressToolbar.editingAccessoryAction?.actionType == .googleLens
        guard shouldShow != isShowing else { return }

        dispatchGoogleLensAvailability(for: windowUUID)
    }

    private func isGoogleLensAvailable(for windowUUID: WindowUUID) -> Bool {
        guard featureFlagsProvider.isEnabled(.googleLens),
              userPreferences.getPreferenceFor(.googleLens),
              tabManager(for: windowUUID)?.selectedTab?.isPrivate != true,
              let defaultEngine = searchEnginesManager.defaultEngine,
              !defaultEngine.isCustomEngine
        else { return false }

        return defaultEngine.isGoogleEngine
    }

    private func dispatchGoogleLensAvailability(for windowUUID: WindowUUID) {
        let action = ToolbarMiddlewareAction(
            isGoogleLensEnabled: isGoogleLensAvailable(for: windowUUID),
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.googleLensAvailabilityDidChange
        )
        store.dispatch(action)
    }
}
