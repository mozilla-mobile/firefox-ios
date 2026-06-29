// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Redux

enum FakeReduxModernAction: ModernAction, Equatable {
    // User action
    case requestInitialValue
    case increaseCounter
    case decreaseCounter

    // Middleware actions
    case initialValueLoaded(initialValue: Int)
    case counterIncreased(counterValue: Int)
    case counterDecreased(counterValue: Int)
    case setPrivateModeTo(isPrivate: Bool)

    // Testing action descriptions in tests
    case complicatedActionLabelledPayload(labelled: FakeComplicatedPayload)
    case complicatedActionUnlabelledPayload(FakeComplicatedPayload)

    case mixedLabelsPayload1(isPrivate: Bool, FakeComplicatedPayload)
    case mixedLabelsPayload2(Bool, complicatedPayload: FakeComplicatedPayload)
    case mixedLabelsPayload3(Bool, FakeComplicatedPayload)
    case mixedLabelsPayload4(isPrivate: Bool, complicatedPayload: FakeComplicatedPayload)

    case nestedObjectPayload(nestedObject: FakeNestedComplicatedPayload)
}

struct FakeComplicatedPayload: Equatable {
    let someBool: Bool
    let someCount: Int
    let someOptionalCount: Int?
}

struct FakeNestedComplicatedPayload: Equatable {
    let someString: String
    let nestedComponent: FakeComplicatedPayload
    let optionalNestedComponent: FakeComplicatedPayload?
}
