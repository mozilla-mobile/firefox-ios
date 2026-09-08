// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The Device Session JWT (DSJ) issued by the backend on successful App Attest enrollment.
public struct IPProtectionDeviceSession: Codable, Equatable, Sendable {
    public let deviceSessionJwt: String
    public let expiresAt: TimeInterval
    public let renewAfter: TimeInterval

    public init(deviceSessionJwt: String, expiresAt: TimeInterval, renewAfter: TimeInterval) {
        self.deviceSessionJwt = deviceSessionJwt
        self.expiresAt = expiresAt
        self.renewAfter = renewAfter
    }

    public func isValid(now: Date = Date()) -> Bool {
        return now.timeIntervalSince1970 * 1000 < expiresAt
    }

    /// Past the renewal window: still valid, but a refresh is due.
    public func needsRenewal(now: Date = Date()) -> Bool {
        return now.timeIntervalSince1970 * 1000 >= renewAfter
    }
}
