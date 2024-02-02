// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Redux
enum FakeReduxAction: Action {
    // User action
    case requestInitialValue
    case increaseCounter
    case decreaseCounter

    // Middleware actions
    case initialValueLoaded(Int)
    case counterIncreased(Int)
    case counterDecreased(Int)
    case setPrivateModeTo(Bool)

    var windowUUID: UUID {
        // TODO: [8188] Currently these unit tests do not make use of UUIDs. This will be updated soon.
        // For now, we can just return UUID().
        return UUID()
    }
}
