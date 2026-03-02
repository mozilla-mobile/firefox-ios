// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common
import WebKit
import SummarizeKit

struct BrowserViewControllerState: ScreenState {
    enum NavigationType: Equatable {
        case home
        case back
        case forward
        case reload
        case reloadNoCache
        case stopLoading
        case newTab
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
        case readerMode
        case newTabLongPressActions
        case readerModeLongPressAction
        case dataClearance
        case passwordGenerator
        // TODO: FXIOS-13118 Clean up and remove as we should have one navigation entry point
        case summarizer(config: SummarizerConfig?)
    }

    let windowUUID: WindowUUID
    var searchScreenState: SearchScreenState
    var toast: ToastType?
    var showOverlay: Bool? // use default value when re-creating
    var reloadWebView: Bool
    var shouldStartAtHome: Bool
    var browserViewType: BrowserViewType
    var navigateTo: NavigationType? // use default value when re-creating
    var displayView: DisplayType? // use default value when re-creating
    var buttonTapped: UIButton?
    var frameContext: PasswordGeneratorFrameContext?
    var microsurveyState: MicrosurveyPromptState
    var navigationDestination: NavigationDestination?

    init(appState: AppState, uuid: WindowUUID) {
        guard let bvcState = appState.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(searchScreenState: bvcState.searchScreenState,
                  toast: bvcState.toast,
                  showOverlay: bvcState.showOverlay,
                  windowUUID: bvcState.windowUUID,
                  reloadWebView: bvcState.reloadWebView,
                  shouldStartAtHome: bvcState.shouldStartAtHome,
                  browserViewType: bvcState.browserViewType,
                  navigateTo: bvcState.navigateTo,
                  displayView: bvcState.displayView,
                  buttonTapped: bvcState.buttonTapped,
                  frameContext: bvcState.frameContext,
                  microsurveyState: bvcState.microsurveyState,
                  navigationDestination: bvcState.navigationDestination)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            searchScreenState: SearchScreenState(),
            toast: nil,
            showOverlay: nil,
            windowUUID: windowUUID,
            browserViewType: .normalHomepage,
            navigateTo: nil,
            displayView: nil,
            buttonTapped: nil,
            microsurveyState: MicrosurveyPromptState(windowUUID: windowUUID),
            navigationDestination: nil)
    }

    init(
        searchScreenState: SearchScreenState,
        toast: ToastType? = nil,
        showOverlay: Bool? = nil,
        windowUUID: WindowUUID,
        reloadWebView: Bool = false,
        shouldStartAtHome: Bool = false,
        browserViewType: BrowserViewType,
        navigateTo: NavigationType? = nil,
        displayView: DisplayType? = nil,
        buttonTapped: UIButton? = nil,
        frameContext: PasswordGeneratorFrameContext? = nil,
        microsurveyState: MicrosurveyPromptState,
        navigationDestination: NavigationDestination? = nil
    ) {
        self.searchScreenState = searchScreenState
        self.toast = toast
        self.windowUUID = windowUUID
        self.showOverlay = showOverlay
        self.reloadWebView = reloadWebView
        self.shouldStartAtHome = shouldStartAtHome
        self.browserViewType = browserViewType
        self.navigateTo = navigateTo
        self.displayView = displayView
        self.buttonTapped = buttonTapped
        self.frameContext = frameContext
        self.microsurveyState = microsurveyState
        self.navigationDestination = navigationDestination
    }

    static let reducer: Reducer<Self> = { state, action in
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
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                reloadWebView: false,
                shouldStartAtHome: false,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: nil)
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
            NavigationBrowserActionType.tapOnAllStoriesButton,
            NavigationBrowserActionType.tapOnPrivacyNoticeLink,
            NavigationBrowserActionType.tapOnShowCertificatesFromErrorPage,
            NavigationBrowserActionType.tapOnNativeErrorPageLearnMore:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: action.navigationDestination
            )
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
        case SummarizeMiddlewareActionType.configuredSummarizer:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: NavigationDestination(.summarizer(config: action.summarizerConfig))
            )
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
            let shouldShowSearchBar = store.state.screenState(
                HomepageState.self,
                for: .homepage,
                window: action.windowUUID
            )?.searchState.shouldShowSearchBar ?? false

            guard shouldShowSearchBar, action.buttonType == .search else {
                return passthroughState(from: state, action: action)
            }

            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: NavigationDestination(.homepageZeroSearch)
            )
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
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
            navigationDestination: NavigationDestination(.zeroSearch)
        )
    }

    @MainActor
    static func reduceStateForMicrosurveyAction(action: MicrosurveyPromptAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
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
        case GeneralBrowserActionType.stopLoadingWebsite:
            return handleStopLoadingWebsiteAction(state: state, action: action)
        case GeneralBrowserActionType.showShare:
            return handleShowShareAction(state: state, action: action)
        case GeneralBrowserActionType.showReaderMode:
            return handleShowReaderModeAction(state: state, action: action)
        case GeneralBrowserActionType.showNewTabLongPressActions:
            return handleShowNewTabLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.addToReadingListLongPressAction:
            return handleAddToReadingListLongPressAction(state: state, action: action)
        case GeneralBrowserActionType.clearData:
            return handleClearDataAction(state: state, action: action)
        case GeneralBrowserActionType.showPasswordGenerator:
            return handleShowPasswordGeneratorAction(state: state, action: action)
        case GeneralBrowserActionType.showSummarizer:
            return handleShowSummarizerAction(state: state, action: action)
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
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: toastType,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowAndLeaveOverlayAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        let showOverlay = action.showOverlay ?? false
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            showOverlay: showOverlay,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleGoToHomepageAction(state: BrowserViewControllerState,
                                                 action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .home,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleAddNewTabAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .newTab,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowBackForwardListAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .backForwardList,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowTrackingProtectionDetailsAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction) -> BrowserViewControllerState {
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .trackingProtectionDetails,
                buttonTapped: action.buttonTapped,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        }

    @MainActor
    private static func handleShowMenuAction(state: BrowserViewControllerState,
                                             action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .menu,
            buttonTapped: action.buttonTapped,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowTabsLongPressAction(state: BrowserViewControllerState,
                                                      action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .tabsLongPressActions,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowReloadLongPressAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .reloadLongPressAction,
            buttonTapped: action.buttonTapped,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowLocationViewLongPressActionSheetAction(
        state: BrowserViewControllerState,
        action: GeneralBrowserAction) -> BrowserViewControllerState {
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .locationViewLongPressAction,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        }

    @MainActor
    private static func handleNavigateBackAction(state: BrowserViewControllerState,
                                                 action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .back,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleNavigateForwardAction(state: BrowserViewControllerState,
                                                    action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .forward,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowTabTrayAction(state: BrowserViewControllerState,
                                                action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .tabTray,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleReloadWebsiteAction(state: BrowserViewControllerState,
                                                  action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .reload,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleReloadWebsiteNoCacheAction(state: BrowserViewControllerState,
                                                         action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .reloadNoCache,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleStopLoadingWebsiteAction(state: BrowserViewControllerState,
                                                       action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: .stopLoading,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowShareAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .share,
            buttonTapped: action.buttonTapped,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowReaderModeAction(state: BrowserViewControllerState,
                                                   action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .readerMode,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowNewTabLongPressAction(state: BrowserViewControllerState,
                                                        action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .newTabLongPressActions,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleAddToReadingListLongPressAction(state: BrowserViewControllerState,
                                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            toast: state.toast,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .readerModeLongPressAction,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleClearDataAction(state: BrowserViewControllerState,
                                              action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .dataClearance,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowPasswordGeneratorAction(state: BrowserViewControllerState,
                                                          action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .passwordGenerator,
            frameContext: action.frameContext,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func handleShowSummarizerAction(state: BrowserViewControllerState,
                                                   action: GeneralBrowserAction) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            displayView: .summarizer(config: action.summarizerConfig),
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    private static func passthroughState(
        from state: BrowserViewControllerState,
        action: Action
    ) -> BrowserViewControllerState {
        let microsurveyState = MicrosurveyPromptState.reducer(state.microsurveyState, action)

        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: microsurveyState
        )
    }

    static func defaultState(from state: BrowserViewControllerState) -> BrowserViewControllerState {
        let microsurveyState = MicrosurveyPromptState.defaultState(from: state.microsurveyState)
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: microsurveyState
        )
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

        return BrowserViewControllerState(
            searchScreenState: SearchScreenState(inPrivateMode: isPrivateBrowsing),
            windowUUID: state.windowUUID,
            reloadWebView: true,
            browserViewType: browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    @MainActor
    static func resolveStateForStartAtHome(
        action: StartAtHomeAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            shouldStartAtHome: action.shouldStartAtHome ?? false,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }
}
