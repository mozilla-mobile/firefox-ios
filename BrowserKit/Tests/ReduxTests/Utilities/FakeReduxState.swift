// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux

struct FakeReduxState: StateType, Equatable {
    var counter: Int = 0
    var isInPrivateMode = false

    static let reducer: Reducer<Self> = { state, action in
        guard let action = action as? FakeReduxAction else { return defaultState(from: state) }

        switch action.actionType {
        case FakeReduxActionType.initialValueLoaded,
            FakeReduxActionType.counterIncreased,
            FakeReduxActionType.counterDecreased:
            return FakeReduxState(counter: action.counterValue ?? state.counter,
                                  isInPrivateMode: state.isInPrivateMode)
        case FakeReduxActionType.setPrivateModeTo:
            return FakeReduxState(counter: state.counter,
                                  isInPrivateMode: action.privateMode ?? state.isInPrivateMode)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: FakeReduxState) -> FakeReduxState {
        return state
    }
}
