// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Device Session JWT (DSJ) issued by the backend on successful App Attest enrollment.
public struct IPProtectionDeviceSession: Codable, Equatable, Sendable {
    public let deviceSessionJwt: String
    public let expiresAtMilliseconds: Int64
    public let renewAfterMilliseconds: Int64

    private enum CodingKeys: String, CodingKey {
        case deviceSessionJwt
        case expiresAtMilliseconds = "expiresAt"
        case renewAfterMilliseconds = "renewAfter"
    }

    public init(deviceSessionJwt: String, expiresAtMilliseconds: Int64, renewAfterMilliseconds: Int64) {
        self.deviceSessionJwt = deviceSessionJwt
        self.expiresAtMilliseconds = expiresAtMilliseconds
        self.renewAfterMilliseconds = renewAfterMilliseconds
    }

    public func isValid(now: Date = Date()) -> Bool {
        return now.millisecondsSince1970 < expiresAtMilliseconds
    }

    /// Past the renewal window: still valid, but a refresh is due.
    public func needsRenewal(now: Date = Date()) -> Bool {
        return now.millisecondsSince1970 >= renewAfterMilliseconds
    }
}

private extension Date {
    var millisecondsSince1970: Int64 {
        return Int64(timeIntervalSince1970 * 1000)
    }
}
