// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

enum PrivateModeMiddlewareAction: Action {
    case privateModeUpdated(BoolValueContext)

    var windowUUID: UUID {
        switch self {
        case .privateModeUpdated(let context as ActionContext):
            return context.windowUUID
        }
    }
}

enum PrivateModeUserAction: Action {
    case setPrivateModeTo(BoolValueContext)

    var windowUUID: UUID {
        switch self {
        case .setPrivateModeTo(let context as ActionContext):
            return context.windowUUID
        }
    }
}
