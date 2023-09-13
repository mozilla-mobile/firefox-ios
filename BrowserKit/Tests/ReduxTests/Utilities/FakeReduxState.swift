// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux
struct FakeReduxState: StateType, Equatable {
    var counter: Int = 0

    static let reducer: Reducer<Self> = { state, action in
        switch action {
        case FakeReduxAction.initialValueLoaded(let value),
            FakeReduxAction.counterIncreased(let value),
            FakeReduxAction.counterDecreased(let value):
            return FakeReduxState(counter: value)
        default:
            return state
        }
    }
}
