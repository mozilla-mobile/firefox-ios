// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum Environment: Equatable {
    case production
    case staging
    case debug
}

extension Environment {

    public static var current: Environment {
        /*
         * Why not xcconfig compilation flags?
         * - Project configs had SWIFT_ACTIVE_COMPILATION_CONDITIONS = ""; blocking xcconfig inheritance
         * - Multiple BetaDebug configs with same name, Xcode uses wrong one
         * - EcosiaTesting.xcconfig works because it sets explicit value, not empty string
         * 
         * Solution: Bundle ID detection is more reliable than build config inheritance
         */
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return .production
        }

        switch bundleId {
        case "com.ecosia.ecosiaapp":
            return .production
        case "com.ecosia.ecosiaapp.firefox":
            return .staging
        default:
            return .debug
        }
    }
}

extension Environment {

    public var urlProvider: URLProvider {
        switch self {
        case .production:
            return .production
        case .staging:
            return .staging
        case .debug:
            return .debug
        }
    }
}
