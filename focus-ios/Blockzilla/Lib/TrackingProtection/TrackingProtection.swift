/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum TrackingProtectionStatus {
    case on(TPPageStats)
    case off

    var trackingInformation: TPPageStats? {
        get {
            guard case let .on(value) = self else { return nil }
            return value
        }
        set {
            guard case .on = self, let newValue = newValue else { return }
            self = .on(newValue)
        }
    }
}

extension TrackingProtectionStatus: Equatable {
    static func == (lhs: TrackingProtectionStatus, rhs: TrackingProtectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.on, .on), (.off, .off):
            return true
        default:
            return false
        }
    }
}

enum BlocklistName: String {
    case advertising = "disconnect-advertising"
    case analytics = "disconnect-analytics"
    case content = "disconnect-content"
    case social = "disconnect-social"

    var filename: String { return self.rawValue }

    static var all: [BlocklistName] { return [.advertising, .analytics, .content, .social] }
    static var basic: [BlocklistName] { return [.advertising, .analytics, .social] }
    static var strict: [BlocklistName] { return [.content] }

    static func forStrictMode(isOn: Bool) -> [BlocklistName] {
        return BlocklistName.basic + (isOn ? BlocklistName.strict : [])
    }
}
