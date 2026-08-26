// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common
import WebKit
import SummarizeKit
import ModifiedCopy

struct TranslationLanguagePickerData: Equatable {
    let languages: [String]
    let isTranslated: Bool
    let translatedToLanguage: String?
}

@Copyable
struct BrowserViewControllerState: ScreenState {
    enum NavigationType: Equatable {
        case home
        case back
        case forward
        case reload
        case reloadNoCache
        case stopLoading
        case newTab
        case loadURL(URL)
    }

    enum DisplayType: Equatable {
        case backForwardList
        case trackingProtectionDetails
        case tabsLongPressActions
        case locationViewLongPressAction
        case menu
        case reloadLongPressAction
        case tabTray
        case share
        case newTabLongPressActions
        case readerModeLongPressAction
        case passwordGenerator
        case translationLanguagePicker(TranslationLanguagePickerData)
        case googleLensPhotoPicker
        case googleLensCamera
    }

    let windowUUID: WindowUUID
    var searchScreenState: SearchScreenState
    var toast: ToastType?
    var showOverlay: Bool? // use default value when re-creating
    var reloadWebView: Bool
    var shouldStartAtHome: Bool
    var shouldShowReaderModeBarSummarizerButton: Bool
    var browserViewType: BrowserViewType
    var navigateTo: NavigationType? // use default value when re-creating
    var displayView: DisplayType? // use default value when re-creating
    var buttonTapped: UIButton?
    var frameContext: PasswordGeneratorFrameContext?
    var microsurveyState: MicrosurveyPromptState
    var autoTranslatePromptState: AutoTranslatePromptState
    var navigationDestination: NavigationDestination?

    init(appState: AppState, uuid: WindowUUID) {
        guard let bvcState = appState.componentState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: bvcState.windowUUID,
                  searchScreenState: bvcState.searchScreenState,
                  toast: bvcState.toast,
                  showOverlay: bvcState.showOverlay,
                  reloadWebView: bvcState.reloadWebView,
                  shouldStartAtHome: bvcState.shouldStartAtHome,
                  shouldShowReaderModeBarSummarizerButton: bvcState.shouldShowReaderModeBarSummarizerButton,
                  browserViewType: bvcState.browserViewType,
                  navigateTo: bvcState.navigateTo,
                  displayView: bvcState.displayView,
                  buttonTapped: bvcState.buttonTapped,
                  frameContext: bvcState.frameContext,
                  microsurveyState: bvcState.microsurveyState,
                  autoTranslatePromptState: bvcState.autoTranslatePromptState,
                  navigationDestination: bvcState.navigationDestination)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            searchScreenState: SearchScreenState(),
            toast: nil,
            showOverlay: nil,
            reloadWebView: false,
            shouldStartAtHome: false,
            shouldShowReaderModeBarSummarizerButton: false,
            browserViewType: .normalHomepage,
            navigateTo: nil,
            displayView: nil,
            buttonTapped: nil,
            frameContext: nil,
            microsurveyState: MicrosurveyPromptState(windowUUID: windowUUID),
            autoTranslatePromptState: AutoTranslatePromptState(windowUUID: windowUUID),
            navigationDestination: nil)
    }

    init(
        windowUUID: WindowUUID,
        searchScreenState: SearchScreenState,
        toast: ToastType?,
        showOverlay: Bool?,
        reloadWebView: Bool,
        shouldStartAtHome: Bool,
        shouldShowReaderModeBarSummarizerButton: Bool,
        browserViewType: BrowserViewType,
        navigateTo: NavigationType?,
        displayView: DisplayType?,
        buttonTapped: UIButton?,
        frameContext: PasswordGeneratorFrameContext?,
        microsurveyState: MicrosurveyPromptState,
        autoTranslatePromptState: AutoTranslatePromptState,
        navigationDestination: NavigationDestination?
    ) {
        self.searchScreenState = searchScreenState
        self.toast = toast
        self.windowUUID = windowUUID
        self.showOverlay = showOverlay
        self.reloadWebView = reloadWebView
        self.shouldShowReaderModeBarSummarizerButton = shouldShowReaderModeBarSummarizerButton
        self.shouldStartAtHome = shouldStartAtHome
        self.browserViewType = browserViewType
        self.navigateTo = navigateTo
        self.displayView = displayView
        self.buttonTapped = buttonTapped
        self.frameContext = frameContext
        self.microsurveyState = microsurveyState
        self.autoTranslatePromptState = autoTranslatePromptState
        self.navigationDestination = navigationDestination
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else {
            return defaultState(from: state)
        }

        if let action = action as? MicrosurveyPromptAction {
            return reduceStateForMicrosurveyAction(action: action, state: state)
        } else if let action = action as? GeneralBrowserAction {
            return reduceStateForGeneralBrowserAction(action: action, state: state)
        } else if let action = action as? NavigationBrowserAction {
            return reduceStateForNavigationBrowserAction(action: action, state: state)
        } else if let action = action as? StartAtHomeAction {
            return reduceStateForStartAtHomeAction(action: action, state: state)
        } else if let action = action as? ToolbarMiddlewareAction {
            return reduceStateForToolbarMiddlewareAction(action: action, state: state)
        } else if let action = action as? ToolbarAction {
            return reduceStateForToolbarAction(action: action, state: state)
        } else if let action = action as? SummarizeAction {
            return reduceStateForSummarizeAction(action: action, state: state)
        } else {
            return passthroughState(from: state, action: action)
        }
    }

    // MARK: - Navigation Browser Action
    @MainActor
    static func reduceStateForNavigationBrowserAction(
        action: NavigationBrowserAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case NavigationBrowserActionType.tapOnTrackingProtection,
            NavigationBrowserActionType.tapOnCell,
            NavigationBrowserActionType.tapOnLink,
            NavigationBrowserActionType.tapOnJumpBackInShowAllButton,
            NavigationBrowserActionType.tapOnBookmarksShowMoreButton,
            NavigationBrowserActionType.longPressOnCell,
            NavigationBrowserActionType.tapOnOpenInNewTab,
            NavigationBrowserActionType.tapOnSettingsSection,
            NavigationBrowserActionType.tapOnShareSheet,
            NavigationBrowserActionType.tapOnHomepageSearchBar,
            NavigationBrowserActionType.tapOnShortcutsShowAllButton,
            NavigationBrowserActionType.tapOnQuickAnswersButton,
            NavigationBrowserActionType.tapOnPrivacyNoticeLink,
            NavigationBrowserActionType.tapOnShowCertificatesFromErrorPage,
            NavigationBrowserActionType.tapOnNativeErrorPageLearnMore,
            NavigationBrowserActionType.tapOnReaderMode:
            return state
                .resetTransientState()
                .copy(navigationDestination: action.navigationDestination)
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        case NavigationBrowserActionType.navigationDestinationHandled:
            return state
                .resetTransientState()
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        default:
            return passthroughState(from: state, action: action)
        }
    }

    // MARK: - Start At Home Action
    @MainActor
    static func reduceStateForStartAtHomeAction(
        action: StartAtHomeAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted:
            return resolveStateForStartAtHome(action: action, state: state)
        default:
            return passthroughState(from: state, action: action)
        }
    }

    // MARK: - Summarize Action
    @MainActor
    static func reduceStateForSummarizeAction(
        action: SummarizeAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case SummarizeMiddlewareActionType.showReaderModeBarSummarizerButton:
            return state
                .resetTransientState()
                .copy(shouldShowReaderModeBarSummarizerButton: true)
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        case SummarizeMiddlewareActionType.summaryNotAvailable:
            return state
                .resetTransientState()
                .copy(shouldShowReaderModeBarSummarizerButton: false)
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        default:
            return passthroughState(from: state, action: action)
        }
    }

    // MARK: - Toolbar Action

    /// Navigate to homepage zero search state, which is a scrim layer / dimming view,
    /// after tapping on search button on navigation toolbar
    @MainActor
    static func reduceStateForToolbarMiddlewareAction(
        action: ToolbarMiddlewareAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case ToolbarMiddlewareActionType.didTapButton:
            let shouldShowSearchBar = store.state.componentState(
                HomepageState.self,
                for: .homepage,
                window: action.windowUUID
            )?.searchBarState.shouldShowSearchBar ?? false

            guard shouldShowSearchBar, action.buttonType == .search else {
                return passthroughState(from: state, action: action)
            }

            return state
                .resetTransientState()
                .copy(navigationDestination: NavigationDestination(.homepageZeroSearch))
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        default:
            return passthroughState(from: state, action: action)
        }
    }

    /// Navigate to zero search that shows trending / recent searches state
    /// after tapping on search button on navigation toolbar
    @MainActor
    static func reduceStateForToolbarAction(
        action: ToolbarAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case ToolbarActionType.didDeleteSearchTerm:
            guard case .webview = state.browserViewType else { return passthroughState(from: state, action: action) }
            return stateForToolbarAction(action, state)
        case ToolbarActionType.didStartEditingUrl:
            return stateForToolbarAction(action, state)
        default:
            return passthroughState(from: state, action: action)
        }
    }

    @MainActor
    private static func stateForToolbarAction(
        _ action: ToolbarAction,
        _ state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigationDestination: NavigationDestination(.zeroSearch))
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    static func reduceStateForMicrosurveyAction(action: MicrosurveyPromptAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    static func reduceStateForGeneralBrowserAction(action: GeneralBrowserAction,
                                                   state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case GeneralBrowserActionType.showToast:
            return handleShowToastAction(state: state, action: action)
        case GeneralBrowserActionType.showOverlay,
            GeneralBrowserActionType.leaveOverlay:
            return handleShowAndLeaveOverlayAction(state: state, action: action)
        case GeneralBrowserActionType.updateSelectedTab:
            return resolveStateForUpdateSelectedTab(action: action, state: state)
        case GeneralBrowserActionType.goToHomepage:
            return handleGoToHomepageAction(state: state, action: action)
        case GeneralBrowserActionType.addNewTab:
            return handleAddNewTabAction(state: state, action: action)
        case GeneralBrowserActionType.showBackForwardList:
            return handleShowBackForwardListAction(state: state, action: action)
        case GeneralBrowserActionType.showTrackingProtectionDetails:
            return handleShowTrackingProtectionDetailsAction(state: state, action: action)
        case GeneralBrowserActionType.showMenu:
            return handleShowMenuAction(state: state, action: action)
        case GeneralBrowserActionType.showTabsLongPressActions:
            return handleShowTabsLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.showReloadLongPressAction:
            return handleShowReloadLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.showLocationViewLongPressActionSheet:
            return handleShowLocationViewLongPressActionSheetAction(state: state, action: action)
        case GeneralBrowserActionType.navigateBack:
            return handleNavigateBackAction(state: state, action: action)
        case GeneralBrowserActionType.navigateForward:
            return handleNavigateForwardAction(state: state, action: action)
        case GeneralBrowserActionType.showTabTray:
            return handleShowTabTrayAction(state: state, action: action)
        case GeneralBrowserActionType.reloadWebsite:
            return handleReloadWebsiteAction(state: state, action: action)
        case GeneralBrowserActionType.reloadWebsiteNoCache:
            return handleReloadWebsiteNoCacheAction(state: state, action: action)
        case GeneralBrowserActionType.loadWaybackURL:
            return handleLoadWaybackURLAction(state: state, action: action)
        case GeneralBrowserActionType.stopLoadingWebsite:
            return handleStopLoadingWebsiteAction(state: state, action: action)
        case GeneralBrowserActionType.showShare:
            return handleShowShareAction(state: state, action: action)
        case GeneralBrowserActionType.showNewTabLongPressActions:
            return handleShowNewTabLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.addToReadingListLongPressAction:
            return handleAddToReadingListLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.showPasswordGenerator:
            return handleShowPasswordGeneratorAction(state: state, action: action)
        case GeneralBrowserActionType.showSummarizer:
            return handleShowSummarizerAction(state: state, action: action)
        case GeneralBrowserActionType.showTranslationLanguagePicker:
            return handleShowTranslationLanguagePickerAction(state: state, action: action)
        case GeneralBrowserActionType.showGoogleLensPhotoPicker:
            return handleShowGoogleLensPhotoPickerAction(state: state, action: action)
        case GeneralBrowserActionType.showGoogleLensCamera:
            return handleShowGoogleLensCameraAction(state: state, action: action)
        default:
            return passthroughState(from: state, action: action)
        }
    }

    @MainActor
    private static func handleShowToastAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        guard let toastType = action.toastType else {
            return defaultState(from: state)
        }
        return state
            .resetTransientState()
            .copy(toast: toastType)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowAndLeaveOverlayAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        let showOverlay = action.showOverlay ?? false
        return state
            .resetTransientState()
            .copy(showOverlay: showOverlay)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleGoToHomepageAction(state: BrowserViewControllerState,
                                                 action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .home)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleAddNewTabAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .newTab)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowBackForwardListAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .backForwardList)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowTrackingProtectionDetailsAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction) -> BrowserViewControllerState {
            return state
                .resetTransientState()
                .copy(displayView: .trackingProtectionDetails)
                .copy(buttonTapped: action.buttonTapped)
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        }

    @MainActor
    private static func handleShowMenuAction(state: BrowserViewControllerState,
                                             action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .menu)
            .copy(buttonTapped: action.buttonTapped)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowTabsLongPressAction(state: BrowserViewControllerState,
                                                      action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .tabsLongPressActions)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowReloadLongPressAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .reloadLongPressAction)
            .copy(buttonTapped: action.buttonTapped)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowLocationViewLongPressActionSheetAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction) -> BrowserViewControllerState {
            return state
                .resetTransientState()
                .copy(displayView: .locationViewLongPressAction)
                .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
                .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                    .legacyReducer(state.autoTranslatePromptState, action))
        }

    @MainActor
    private static func handleNavigateBackAction(state: BrowserViewControllerState,
                                                 action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .back)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleNavigateForwardAction(state: BrowserViewControllerState,
                                                    action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .forward)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowTabTrayAction(state: BrowserViewControllerState,
                                                action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .tabTray)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleReloadWebsiteAction(state: BrowserViewControllerState,
                                                  action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .reload)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleReloadWebsiteNoCacheAction(state: BrowserViewControllerState,
                                                         action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .reloadNoCache)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleLoadWaybackURLAction(state: BrowserViewControllerState,
                                                   action: GeneralBrowserAction) -> BrowserViewControllerState {
        guard let url = action.destinationURL else {
            return passthroughState(from: state, action: action)
        }
        return state
            .resetTransientState()
            .copy(navigateTo: .loadURL(url))
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleStopLoadingWebsiteAction(state: BrowserViewControllerState,
                                                       action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(navigateTo: .stopLoading)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowShareAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .share)
            .copy(buttonTapped: action.buttonTapped)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowNewTabLongPressAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .newTabLongPressActions)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleAddToReadingListLongPressAction(state: BrowserViewControllerState,
                                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .readerModeLongPressAction)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowPasswordGeneratorAction(state: BrowserViewControllerState,
                                                          action: GeneralBrowserAction) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .passwordGenerator)
            .copy(frameContext: action.frameContext)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowSummarizerAction(state: BrowserViewControllerState,
                                                   action: GeneralBrowserAction) -> BrowserViewControllerState {
        guard let summarizerConfig = action.summarizerConfig else {
            return passthroughState(from: state, action: action)
        }
        return state
            .resetTransientState()
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
            .copy(navigationDestination: NavigationDestination(
                .summarizer(
                    config: summarizerConfig,
                    trigger: action.summarizerTrigger
                )
            ))
    }

    @MainActor
    private static func handleShowTranslationLanguagePickerAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .translationLanguagePicker(TranslationLanguagePickerData(
                languages: action.translationLanguages ?? [],
                isTranslated: action.isPageTranslated,
                translatedToLanguage: action.translatedToLanguage
            )))
            .copy(buttonTapped: action.buttonTapped)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowGoogleLensPhotoPickerAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .googleLensPhotoPicker)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func handleShowGoogleLensCameraAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(displayView: .googleLensCamera)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    private static func passthroughState(
        from state: BrowserViewControllerState,
        action: Action
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    static func resolveStateForUpdateSelectedTab(action: GeneralBrowserAction,
                                                 state: BrowserViewControllerState) -> BrowserViewControllerState {
        let isAboutHomeURL = InternalURL(action.selectedTabURL)?.isAboutHomeURL ?? false
        var browserViewType = BrowserViewType.normalHomepage
        let isPrivateBrowsing = action.isPrivateBrowsing ?? false

        if isAboutHomeURL {
            browserViewType = isPrivateBrowsing ? .privateHomepage : .normalHomepage
        } else {
            browserViewType = .webview
        }

        return state
            .resetTransientState()
            .copy(searchScreenState: SearchScreenState(inPrivateMode: isPrivateBrowsing))
            .copy(reloadWebView: true)
            .copy(browserViewType: browserViewType)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    @MainActor
    static func resolveStateForStartAtHome(
        action: StartAtHomeAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        return state
            .resetTransientState()
            .copy(shouldStartAtHome: action.shouldStartAtHome ?? false)
            .copy(microsurveyState: MicrosurveyPromptState.reducer.legacyReducer(state.microsurveyState, action))
            .copy(autoTranslatePromptState: AutoTranslatePromptState.reducer
                .legacyReducer(state.autoTranslatePromptState, action))
    }

    static func defaultState(from state: BrowserViewControllerState) -> BrowserViewControllerState {
        let microsurveyState = MicrosurveyPromptState.defaultState(from: state.microsurveyState)
        return BrowserViewControllerState(
            windowUUID: state.windowUUID,
            searchScreenState: state.searchScreenState,
            toast: nil,
            showOverlay: nil,
            reloadWebView: false,
            shouldStartAtHome: false,
            shouldShowReaderModeBarSummarizerButton: state.shouldShowReaderModeBarSummarizerButton,
            browserViewType: state.browserViewType,
            navigateTo: nil,
            displayView: nil,
            buttonTapped: nil,
            frameContext: nil,
            microsurveyState: microsurveyState,
            autoTranslatePromptState: AutoTranslatePromptState.defaultState(from: state.autoTranslatePromptState),
            navigationDestination: nil
        )
    }
}
