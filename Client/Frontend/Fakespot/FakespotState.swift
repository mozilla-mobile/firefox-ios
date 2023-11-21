// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct FakespotState: ScreenState, Equatable {
    var isOpenOnProductPage: Bool

    init(_ appState: AppState) {
        guard let fakespotState = store.state.screenState(FakespotState.self, for: .fakespot) else {
            self.init()
            return
        }

        self.init(isOpenOnProductPage: fakespotState.isOpenOnProductPage)
    }

    init() {
        self.init(isOpenOnProductPage: false)
    }

    init(isOpenOnProductPage: Bool) {
        self.isOpenOnProductPage = isOpenOnProductPage
    }

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakespotAction.toggleAppearance(let isEnabled):
            return FakespotState(isOpenOnProductPage: isEnabled)
        default:
            return state
        }
    }

    static func == (lhs: FakespotState, rhs: FakespotState) -> Bool {
        return lhs.isOpenOnProductPage == rhs.isOpenOnProductPage
    }
}
