// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

struct OnboardingViewControllerState: ScreenState, Equatable {
    let windowUUID: WindowUUID

    init(appState: AppState, uuid: WindowUUID) {
        guard let introState = store.state.screenState(
            OnboardingViewControllerState.self,
            for: .onboardingViewController,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: introState.windowUUID)
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action {
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: OnboardingViewControllerState) -> OnboardingViewControllerState {
        return OnboardingViewControllerState(windowUUID: state.windowUUID)
    }
}
