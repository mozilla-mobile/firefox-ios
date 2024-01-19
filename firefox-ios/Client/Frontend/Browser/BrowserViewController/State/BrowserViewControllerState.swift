// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct BrowserViewControllerState: ScreenState, Equatable {
    var searchScreenState: SearchScreenState
    var usePrivateHomepage: Bool
    var showDataClearanceFlow: Bool
    var fakespotState: FakespotState
    var toast: ToastType?

    init(_ appState: AppState) {
        guard let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController)
        else {
            self.init()
            return
        }

        self.init(searchScreenState: bvcState.searchScreenState,
                  usePrivateHomepage: bvcState.usePrivateHomepage,
                  showDataClearanceFlow: bvcState.showDataClearanceFlow,
                  fakespotState: bvcState.fakespotState,
                  toast: bvcState.toast)
    }

    init() {
        self.init(
            searchScreenState: SearchScreenState(),
            usePrivateHomepage: false,
            showDataClearanceFlow: false,
            fakespotState: FakespotState(),
            toast: nil)
    }

    init(
        searchScreenState: SearchScreenState,
        usePrivateHomepage: Bool,
        showDataClearanceFlow: Bool,
        fakespotState: FakespotState,
        toast: ToastType? = nil
    ) {
        self.searchScreenState = searchScreenState
        self.usePrivateHomepage = usePrivateHomepage
        self.showDataClearanceFlow = showDataClearanceFlow
        self.fakespotState = fakespotState
        self.toast = toast
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case PrivateModeMiddlewareAction.privateModeUpdated(let privacyState):
            return BrowserViewControllerState(
                searchScreenState: SearchScreenState(inPrivateMode: privacyState),
                usePrivateHomepage: privacyState,
                showDataClearanceFlow: privacyState,
                fakespotState: state.fakespotState)
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
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        case GeneralBrowserAction.showToast(let toastType):
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                usePrivateHomepage: state.usePrivateHomepage,
                showDataClearanceFlow: state.showDataClearanceFlow,
                fakespotState: state.fakespotState,
                toast: toastType)
        default:
            return state
        }
    }
}
