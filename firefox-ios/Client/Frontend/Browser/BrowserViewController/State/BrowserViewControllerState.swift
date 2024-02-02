// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct BrowserViewControllerState: ScreenState, Equatable {
    let windowUUID: WindowUUID
    var searchScreenState: SearchScreenState
    var usePrivateHomepage: Bool
    var showDataClearanceFlow: Bool
    var fakespotState: FakespotState
    var toast: ToastType?

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
                  usePrivateHomepage: bvcState.usePrivateHomepage,
                  showDataClearanceFlow: bvcState.showDataClearanceFlow,
                  fakespotState: bvcState.fakespotState,
                  toast: bvcState.toast,
                  windowUUID: bvcState.windowUUID)
    }

    init(windowUUID: WindowUUID) {
        self.init(
            searchScreenState: SearchScreenState(),
            usePrivateHomepage: false,
            showDataClearanceFlow: false,
            fakespotState: FakespotState(windowUUID: windowUUID),
            toast: nil,
            windowUUID: windowUUID)
    }

    init(
        searchScreenState: SearchScreenState,
        usePrivateHomepage: Bool,
        showDataClearanceFlow: Bool,
        fakespotState: FakespotState,
        toast: ToastType? = nil,
        windowUUID: WindowUUID
    ) {
        self.searchScreenState = searchScreenState
        self.usePrivateHomepage = usePrivateHomepage
        self.showDataClearanceFlow = showDataClearanceFlow
        self.fakespotState = fakespotState
        self.toast = toast
        self.windowUUID = windowUUID
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action {
        case PrivateModeMiddlewareAction.privateModeUpdated(let privacyState):
            return BrowserViewControllerState(
                searchScreenState: SearchScreenState(inPrivateMode: privacyState),
                usePrivateHomepage: privacyState,
                showDataClearanceFlow: privacyState,
                fakespotState: state.fakespotState,
                windowUUID: state.windowUUID)
        case FakespotAction.pressedShoppingButton,
            FakespotAction.show,
            FakespotAction.dismiss,
            FakespotAction.setAppearanceTo,
            FakespotAction.settingsStateDidChange,
            FakespotAction.reviewQualityDidChange,
            FakespotAction.tabDidChange,
            FakespotAction.tabDidReload,
            FakespotAction.surfaceDisplayedEventSend,
            FakespotAction.adsImpressionEventSendFor,
            FakespotAction.adsExposureEventSendFor:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                usePrivateHomepage: state.usePrivateHomepage,
                showDataClearanceFlow: state.showDataClearanceFlow,
                fakespotState: FakespotState.reducer(state.fakespotState, action),
                windowUUID: state.windowUUID)
        case GeneralBrowserAction.showToast(let context):
            let toastType = context.toastType
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                usePrivateHomepage: state.usePrivateHomepage,
                showDataClearanceFlow: state.showDataClearanceFlow,
                fakespotState: state.fakespotState,
                toast: toastType,
                windowUUID: state.windowUUID)
        default:
            return state
        }
    }
}
