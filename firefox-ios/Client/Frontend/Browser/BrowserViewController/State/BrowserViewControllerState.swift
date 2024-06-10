// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

struct BrowserViewControllerState: ScreenState, Equatable {
    enum NavigationType {
        case home
        case back
        case forward
        case tabTray
    }

    let windowUUID: WindowUUID
    var searchScreenState: SearchScreenState
    var showDataClearanceFlow: Bool
    var toolbarState: ToolbarState
    var fakespotState: FakespotState
    var toast: ToastType?
    var showOverlay: Bool
    var reloadWebView: Bool
    var browserViewType: BrowserViewType
    var navigateTo: NavigationType?
    var showQRcodeReader: Bool
    var showBackForwardList: Bool
    var showTrackingProtectionDetails: Bool
    var showTabsLongPressActions: Bool
    var microsurveyState: MicrosurveyPromptState

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
                  showDataClearanceFlow: bvcState.showDataClearanceFlow,
                  toolbarState: bvcState.toolbarState,
                  fakespotState: bvcState.fakespotState,
                  toast: bvcState.toast,
                  showOverlay: bvcState.showOverlay,
                  windowUUID: bvcState.windowUUID,
                  reloadWebView: bvcState.reloadWebView,
                  browserViewType: bvcState.browserViewType,
                  navigateTo: bvcState.navigateTo,
                  showQRcodeReader: bvcState.showQRcodeReader,
                  showBackForwardList: bvcState.showBackForwardList,
                  showTrackingProtectionDetails: bvcState.showTrackingProtectionDetails,
                  showTabsLongPressActions: bvcState.showTabsLongPressActions,
                  microsurveyState: bvcState.microsurveyState)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            searchScreenState: SearchScreenState(),
            showDataClearanceFlow: false,
            toolbarState: ToolbarState(windowUUID: windowUUID),
            fakespotState: FakespotState(windowUUID: windowUUID),
            toast: nil,
            showOverlay: false,
            windowUUID: windowUUID,
            browserViewType: .normalHomepage,
            navigateTo: nil,
            showQRcodeReader: false,
            showBackForwardList: false,
            showTrackingProtectionDetails: false,
            showTabsLongPressActions: false,
            microsurveyState: MicrosurveyPromptState(windowUUID: windowUUID))
    }

    init(
        searchScreenState: SearchScreenState,
        showDataClearanceFlow: Bool,
        toolbarState: ToolbarState,
        fakespotState: FakespotState,
        toast: ToastType? = nil,
        showOverlay: Bool = false,
        windowUUID: WindowUUID,
        reloadWebView: Bool = false,
        browserViewType: BrowserViewType,
        navigateTo: NavigationType? = nil,
        showQRcodeReader: Bool = false,
        showBackForwardList: Bool = false,
        showTrackingProtectionDetails: Bool = false,
        showTabsLongPressActions: Bool = false,
        microsurveyState: MicrosurveyPromptState
    ) {
        self.searchScreenState = searchScreenState
        self.showDataClearanceFlow = showDataClearanceFlow
        self.toolbarState = toolbarState
        self.fakespotState = fakespotState
        self.toast = toast
        self.windowUUID = windowUUID
        self.showOverlay = showOverlay
        self.reloadWebView = reloadWebView
        self.browserViewType = browserViewType
        self.navigateTo = navigateTo
        self.showQRcodeReader = showQRcodeReader
        self.showBackForwardList = showBackForwardList
        self.showTrackingProtectionDetails = showTrackingProtectionDetails
        self.showTabsLongPressActions = showTabsLongPressActions
        self.microsurveyState = microsurveyState
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        if let action = action as? FakespotAction {
            return BrowserViewControllerState.reduceStateForFakeSpotAction(action: action, state: state)
        } else if let action = action as? MicrosurveyPromptAction {
            return BrowserViewControllerState.reduceStateForMicrosurveyAction(action: action, state: state)
        } else if let action = action as? PrivateModeAction {
            return BrowserViewControllerState.reduceStateForPrivateModeAction(action: action, state: state)
        } else if let action = action as? GeneralBrowserAction {
            return BrowserViewControllerState.reduceStateForGeneralBrowserAction(action: action, state: state)
        } else if let action = action as? ToolbarAction {
            return BrowserViewControllerState.reduceStateForToolbarAction(action: action, state: state)
        } else {
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                showOverlay: state.showOverlay,
                windowUUID: state.windowUUID,
                reloadWebView: false,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        }
    }

    static func reduceStateForFakeSpotAction(action: FakespotAction,
                                             state: BrowserViewControllerState) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            showDataClearanceFlow: state.showDataClearanceFlow,
            toolbarState: state.toolbarState,
            fakespotState: FakespotState.reducer(state.fakespotState, action),
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: nil,
            showQRcodeReader: false,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    static func reduceStateForMicrosurveyAction(action: MicrosurveyPromptAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        return BrowserViewControllerState(
            searchScreenState: state.searchScreenState,
            showDataClearanceFlow: state.showDataClearanceFlow,
            toolbarState: state.toolbarState,
            fakespotState: state.fakespotState,
            windowUUID: state.windowUUID,
            browserViewType: state.browserViewType,
            navigateTo: nil,
            showQRcodeReader: false,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }

    static func reduceStateForPrivateModeAction(action: PrivateModeAction,
                                                state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case PrivateModeActionType.privateModeUpdated:
            let privacyState = action.isPrivate ?? false
            var browserViewType = state.browserViewType
            if browserViewType != .webview {
                browserViewType = privacyState ? .privateHomepage : .normalHomepage
            }
            return BrowserViewControllerState(
                searchScreenState: SearchScreenState(inPrivateMode: privacyState),
                showDataClearanceFlow: privacyState,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                windowUUID: state.windowUUID,
                reloadWebView: true,
                browserViewType: browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        default:
            return state
        }
    }

    static func reduceStateForGeneralBrowserAction(action: GeneralBrowserAction,
                                                   state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case GeneralBrowserActionType.showToast:
            guard let toastType = action.toastType else { return state }
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: toastType,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showOverlay:
            let showOverlay = action.showOverlay ?? false
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                showOverlay: showOverlay,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.updateSelectedTab:
            return BrowserViewControllerState.resolveStateForUpdateSelectedTab(action: action, state: state)
        case GeneralBrowserActionType.goToHomepage:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .home,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showQRcodeReader:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: true,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showBackForwardList:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                showBackForwardList: true,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showTrackingProtectionDetails:
            return BrowserViewControllerState(
                    searchScreenState: state.searchScreenState,
                    showDataClearanceFlow: state.showDataClearanceFlow,
                    toolbarState: state.toolbarState,
                    fakespotState: state.fakespotState,
                    toast: state.toast,
                    windowUUID: state.windowUUID,
                    browserViewType: state.browserViewType,
                    showTrackingProtectionDetails: true,
                    microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showTabsLongPressActions:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                showTabsLongPressActions: true,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.navigateBack:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .back,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.navigateForward:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .forward,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        case GeneralBrowserActionType.showTabTray:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: state.toolbarState,
                fakespotState: state.fakespotState,
                toast: state.toast,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: .tabTray,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        default:
            return state
        }
    }

    static func reduceStateForToolbarAction(action: ToolbarAction,
                                            state: BrowserViewControllerState) -> BrowserViewControllerState {
        switch action.actionType {
        case ToolbarActionType.didLoadToolbars,
            ToolbarActionType.numberOfTabsChanged,
            ToolbarActionType.urlDidChange,
            ToolbarActionType.backButtonStateChanged,
            ToolbarActionType.forwardButtonStateChanged:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                showDataClearanceFlow: state.showDataClearanceFlow,
                toolbarState: ToolbarState.reducer(state.toolbarState, action),
                fakespotState: state.fakespotState,
                showOverlay: state.showOverlay,
                windowUUID: state.windowUUID,
                browserViewType: state.browserViewType,
                navigateTo: nil,
                showQRcodeReader: false,
                microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
        default:
            return state
        }
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
            searchScreenState: state.searchScreenState,
            showDataClearanceFlow: state.showDataClearanceFlow,
            toolbarState: state.toolbarState,
            fakespotState: state.fakespotState,
            showOverlay: state.showOverlay,
            windowUUID: state.windowUUID,
            reloadWebView: true,
            browserViewType: browserViewType,
            navigateTo: nil,
            showQRcodeReader: false,
            microsurveyState: MicrosurveyPromptState.reducer(state.microsurveyState, action))
    }
}
