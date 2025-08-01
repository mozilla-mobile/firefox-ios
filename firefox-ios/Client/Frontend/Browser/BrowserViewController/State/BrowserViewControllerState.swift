// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common
import WebKit

struct BrowserViewControllerState: ScreenState, Equatable {
    enum NavigationType {
        case home
        case back
        case forward
        case reload
        case reloadNoCache
        case stopLoading
        case newTab
    }

    enum DisplayType: Equatable {
        case qrCodeReader
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
    var frame: WKFrameInfo?
    var microsurveyState: MicrosurveyPromptState
    var navigationDestination: NavigationDestination?

    init(appState: AppState, uuid: WindowUUID) {
        guard let bvcState = store.state.screenState(
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
                  frame: bvcState.frame,
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
        frame: WKFrameInfo? = nil,
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
        self.frame = frame
        self.microsurveyState = microsurveyState
        self.navigationDestination = navigationDestination
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        if let action = action as? MicrosurveyPromptAction {
            return reduceStateForMicrosurveyAction(action: action, state: state)
        } else if let action = action as? GeneralBrowserAction {
            return reduceStateForGeneralBrowserAction(action: action, state: state)
        } else if let action = action as? NavigationBrowserAction {
            return reduceStateForNavigationBrowserAction(action: action, state: state)
        } else if let action = action as? StartAtHomeAction {
            return reduceStateForStartAtHomeAction(action: action, state: state)
        } else if let action = action as? ToolbarMiddlewareAction {
            return reduceStateForToolbarAction(action: action, state: state)
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
    static func reduceStateForNavigationBrowserAction(
        action: NavigationBrowserAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case NavigationBrowserActionType.tapOnCustomizeHomepageButton,
            NavigationBrowserActionType.tapOnTrackingProtection,
            NavigationBrowserActionType.tapOnCell,
            NavigationBrowserActionType.tapOnLink,
            NavigationBrowserActionType.tapOnJumpBackInShowAllButton,
            NavigationBrowserActionType.tapOnBookmarksShowMoreButton,
            NavigationBrowserActionType.longPressOnCell,
            NavigationBrowserActionType.tapOnOpenInNewTab,
            NavigationBrowserActionType.tapOnSettingsSection,
            NavigationBrowserActionType.tapOnShareSheet,
            NavigationBrowserActionType.tapOnHomepageSearchBar:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: action.navigationDestination
            )
        default:
            return defaultState(from: state, action: action)
        }
    }

    // MARK: - Start At Home Action
    static func reduceStateForStartAtHomeAction(
        action: StartAtHomeAction,
        state: BrowserViewControllerState
    ) -> BrowserViewControllerState {
        switch action.actionType {
        case StartAtHomeMiddlewareActionType.startAtHomeCheckCompleted:
            return resolveStateForStartAtHome(action: action, state: state)
        default:
            return defaultState(from: state, action: action)
        }
    }

    // MARK: - Toolbar Action

    /// Navigate to zero search state after tapping on search button on navigation toolbar
    static func reduceStateForToolbarAction(
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
                return defaultState(from: state, action: action)
            }

            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action),
                navigationDestination: NavigationDestination(.zeroSearch)
            )
        default:
            return defaultState(from: state, action: action)
        }
    }

    static func reduceStateForMicrosurveyAction(action: MicrosurveyPromptAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    static func reduceStateForGeneralBrowserAction(action: GeneralBrowserAction,
                                                   state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case GeneralBrowserActionType.showToast:
            guard let toastType = action.toastType else { return state }
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: toastType,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showOverlay,
            GeneralBrowserActionType.leaveOverlay:
            let showOverlay = action.showOverlay ?? false
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showOverlay: showOverlay,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.updateSelectedTab:
            return resolveStateForUpdateSelectedTab(action: action, state: state)

        case GeneralBrowserActionType.goToHomepage:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .home,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.addNewTab:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .newTab,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showQRcodeReader:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .qrCodeReader,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showBackForwardList:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .backForwardList,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showTrackingProtectionDetails:
            return BrowserViewControllerState(
                    searchScreenState: state.searchScreenState,
                    toast: state.toast,
                    windowUUID: state.windowUUID,
                    browserViewType: state.browserViewType,
                    displayView: .trackingProtectionDetails,
                    buttonTapped: action.buttonTapped,
                    microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showMenu:
            return BrowserViewControllerState(
                    searchScreenState: state.searchScreenState,
                    toast: state.toast,
                    windowUUID: state.windowUUID,
                    browserViewType: state.browserViewType,
                    displayView: .menu,
                    buttonTapped: action.buttonTapped,
                    microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showTabsLongPressActions:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .tabsLongPressActions,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showReloadLongPressAction:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .reloadLongPressAction,
                buttonTapped: action.buttonTapped,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showLocationViewLongPressActionSheet:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .locationViewLongPressAction,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.navigateBack:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .back,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.navigateForward:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .forward,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showTabTray:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .tabTray,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.reloadWebsite:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .reload,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.reloadWebsiteNoCache:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .reloadNoCache,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.stopLoadingWebsite:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .stopLoading,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showShare:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .share,
                buttonTapped: action.buttonTapped,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showReaderMode:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .readerMode,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.showNewTabLongPressActions:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .newTabLongPressActions,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.addToReadingListLongPressAction:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .readerModeLongPressAction,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))

        case GeneralBrowserActionType.clearData:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .dataClearance,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showPasswordGenerator:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                displayView: .passwordGenerator,
                frame: action.frame,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action)
                )
        default:
            return defaultState(from: state, action: action)
        }
    }

    private static func defaultState(from state: BrowserViewControllerState,
                                     action: Action?) -> BrowserViewControllerState {
        var microsurveyState = state.microsurveyState
        if let action {
            microsurveyState = MicrosurveyPromptState.reducer(state.microsurveyState, action)
        }

        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            microsurveyState: microsurveyState
        )
    }

    static func defaultState(from state: BrowserViewControllerState) -> BrowserViewControllerState {
        return defaultState(from: state, action: nil)
    }

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
