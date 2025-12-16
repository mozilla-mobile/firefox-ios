// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Redux

struct MockState: StateType, Equatable {
    let counter: Int

    nonisolated(unsafe) static var actionsReduced = [ActionType]()
    nonisolated(unsafe) static var runMidReducerActions = false
    nonisolated(unsafe) static var midReducerActions: (() -> Void)?

    init(midReducerActions: (() -> Void)? = nil) {
        counter = 0
        MockState.actionsReduced = [ActionType]()
        MockState.runMidReducerActions = false
    }

    static let reducer: Reducer<Self> = { state, action in
        MockState.actionsReduced.append(action.actionType)

        if MockState.runMidReducerActions {
            MockState.midReducerActions?()
        }

        return defaultState(from: state)
    }

    static func defaultState(from state: MockState) -> MockState {
        return state
    }
}
