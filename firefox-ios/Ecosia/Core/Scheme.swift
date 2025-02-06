// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Scheme: String {
    case
    http,
    https,
    gmsg,
    other

    public enum Policy {
        case
        allow,
        cancel
    }

    var policy: Policy {
        switch self {
        case .gmsg:
            return .cancel
        default:
            return .allow
        }
    }

    var isBrowser: Bool {
        switch self {
        case .http, .https:
            return true
        default:
            return false
        }
    }
}
