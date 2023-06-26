// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Sync
import Shared
import Storage
import Common

public enum SyncDisplayState {
    case inProgress
    case good
    case bad(message: String?)
    case warning(message: String)

    func asObject() -> [String: String]? {
        switch self {
        case .bad(let msg):
            guard let message = msg else {
                return ["state": "Error"]
            }
            return ["state": "Error",
                    "message": message]
        case .warning(let message):
            return ["state": "Warning",
                    "message": message]
        default:
            break
        }
        return nil
    }
}

public func == (lhs: SyncDisplayState, rhs: SyncDisplayState) -> Bool {
    switch (lhs, rhs) {
    case (.inProgress, .inProgress):
        return true
    case (.good, .good):
        return true
    case (.bad(let first), .bad(let second)) where first == second:
        return true
    case (.warning(let first), .warning(let second)) where first == second:
        return true
    default:
        return false
    }
}
