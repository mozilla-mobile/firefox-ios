// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

public enum VPNAuthError: Error, Equatable {
    /// The backend refused the Device Session JWT; recoverable by refreshing and retrying once
    case sessionRejected
    case noStoredSession
    case notEnrolled
    case sessionNotPersisted
}

extension VPNAuthError {
    /// Whether the backend no longer recognizes this device's key, making enrollment the only recovery.
    /// Retryable failures are excluded, since re-enrolling would discard a working key for nothing.
    static func indicatesLostEnrollment(_ error: Error) -> Bool {
        switch error {
        case VPNAuthError.notEnrolled:
            return true
        case AppAttestServiceError.missingKeyID, AppAttestServiceError.invalidKeyID:
            return true
        case AppAttestServiceError.serverError(let statusCode, _):
            return statusCode == 401
        default:
            return false
        }
    }
}
