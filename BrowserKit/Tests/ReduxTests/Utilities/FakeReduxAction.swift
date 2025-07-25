// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Redux

struct FakeReduxAction: Action {
    let windowUUID: WindowUUID
    let actionType: ActionType
    let counterValue: Int?
    let privateMode: Bool?

    init(counterValue: Int? = nil,
         privateMode: Bool? = nil,
         windowUUID: UUID,
         actionType: ActionType) {
        self.windowUUID = windowUUID
        self.actionType = actionType
        self.counterValue = counterValue
        self.privateMode = privateMode
    }
}

enum FakeReduxActionType: ActionType {
    // User action
    case requestInitialValue
    case increaseCounter
    case decreaseCounter

    // Middleware actions
    case initialValueLoaded
    case counterIncreased
    case counterDecreased
    case setPrivateModeTo
}
