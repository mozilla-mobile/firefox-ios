// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum PrivateModeMiddlewareAction: Action {
    case privateModeUpdated(Bool)

    var windowUUID: UUID? {
        // TODO: [8188] Update to be non-optional and return windowUUID. Forthcoming.
        switch self {
        default: return nil
        }
    }
}

enum PrivateModeUserAction: Action {
    case setPrivateModeTo(Bool)

    var windowUUID: UUID? {
        // TODO: [8188] Update to be non-optional and return windowUUID. Forthcoming.
        switch self {
        default: return nil
        }
    }
}
