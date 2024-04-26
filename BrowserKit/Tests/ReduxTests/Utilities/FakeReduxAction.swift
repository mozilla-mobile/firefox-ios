// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Redux

class FakeReduxAction: Action {
    let counterValue: Int?
    let privateMode: Bool?

    init(counterValue: Int? = nil,
         privateMode: Bool? = nil,
         windowUUID: UUID,
         actionType: ActionType) {
        self.counterValue = counterValue
        self.privateMode = privateMode
        super.init(windowUUID: windowUUID,
                   actionType: actionType)
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
