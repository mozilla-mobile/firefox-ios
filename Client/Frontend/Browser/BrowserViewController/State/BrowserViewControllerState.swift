// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

struct BVCPrivacyState: Equatable {
    private let isInPrivateMode: Bool

    var shouldHideSearchSuggestionsview: Bool {
        return isInPrivateMode
    }

    var shouldShowPrivateHomepage: Bool {
        return isInPrivateMode
    }

    init(inPrivatemode: Bool = false) {
        self.isInPrivateMode = inPrivatemode
    }
}

struct BrowserViewControllerState: ScreenState, Equatable {
    var privateMode: BVCPrivacyState
    var fakespotState: FakespotState

    init(_ appState: AppState) {
        guard let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController)
        else {
            self.init()
            return
        }

        self.init(privateMode: bvcState.privateMode,
                  fakespotState: bvcState.fakespotState)
    }

    init() {
        self.init(
            privateMode: BVCPrivacyState(),
            fakespotState: FakespotState())
    }

    init(
        privateMode: BVCPrivacyState,
        fakespotState: FakespotState
    ) {
        self.privateMode = privateMode
        self.fakespotState = fakespotState
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case PrivateModeMiddlewareAction.privateModeUpdated(let privacyState):
            return BrowserViewControllerState(
                privateMode: BVCPrivacyState(inPrivatemode: privacyState),
                fakespotState: state.fakespotState)
        case FakespotAction.pressedShoppingButton,
            FakespotAction.show,
            FakespotAction.dismiss:
            return BrowserViewControllerState(
                privateMode: state.privateMode,
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        case FakespotAction.setAppearanceTo(let isEnabled):
            return BrowserViewControllerState(
                privateMode: state.privateMode,
                fakespotState: FakespotState.reducer(state.fakespotState, action))
        default:
            return state
        }
    }
}
