// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Environment: Equatable {
    case production
    case staging
}

extension Environment {

    public static var current: Environment {
        #if MOZ_CHANNEL_RELEASE
        return .production
        #else
        return .staging
        #endif
    }
}

extension Environment {

    public var urlProvider: URLProvider {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        }
    }
}
