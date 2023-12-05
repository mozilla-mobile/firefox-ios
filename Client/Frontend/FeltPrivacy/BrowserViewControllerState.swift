// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct BrowserViewControllerState: ScreenState, Equatable {
    var feltPrivacyState: FeltPrivacyState
    var fakespotState: FakespotState

    init(_ appState: AppState) {
        guard let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController)
        else {
            self.init()
            return
        }

        self.init(feltPrivacyState: bvcState.feltPrivacyState,
                  fakespotState: bvcState.fakespotState)
    }

    init() {
        self.init(
            feltPrivacyState: FeltPrivacyState(),
            fakespotState: FakespotState())
    }

    init(
        feltPrivacyState: FeltPrivacyState,
        fakespotState: FakespotState
    ) {
        self.feltPrivacyState = feltPrivacyState
        self.fakespotState = fakespotState
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FeltPrivacyAction.privateModeUpdated(let privacyState):
            return BrowserViewControllerState(
                feltPrivacyState: FeltPrivacyState.reducer(state.feltPrivacyState, action),
                fakespotState: state.fakespotState)
        case FakespotAction.pressedShoppingButton,
            FakespotAction.show,
            FakespotAction.dismiss:
            return BrowserViewControllerState(
                feltPrivacyState: state.feltPrivacyState,
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        case FakespotAction.setAppearanceTo(let isEnabled):
            return BrowserViewControllerState(
                feltPrivacyState: state.feltPrivacyState,
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        default:
            return state
        }
    }
}
