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
                  fakespotState: bvcState.fakespotState)
    }

    init() {
        self.init(
            searchScreenState: SearchScreenState(),
            usePrivateHomepage: false,
            showDataClearanceFlow: false,
            fakespotState: FakespotState())
    }

    init(
        searchScreenState: SearchScreenState,
        usePrivateHomepage: Bool,
        showDataClearanceFlow: Bool,
        fakespotState: FakespotState
    ) {
        self.searchScreenState = searchScreenState
        self.usePrivateHomepage = usePrivateHomepage
        self.showDataClearanceFlow = showDataClearanceFlow
        self.fakespotState = fakespotState
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
            FakespotAction.tabDidChange:
            return BrowserViewControllerState(
                searchScreenState: state.searchScreenState,
                usePrivateHomepage: state.usePrivateHomepage,
                showDataClearanceFlow: state.showDataClearanceFlow,
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        default:
            return state
        }
    }
}
