// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation

/// Attaches the stored session credential as a `Bearer` token, without a full attestation
/// so we don't create a new device record and increase risk metric
public struct VPNSessionRequestAuth: RequestAuthProtocol {
    private let authService: VPNAuthenticating

    public init(authService: VPNAuthenticating) {
        self.authService = authService
    }

    public func authenticate(request: inout URLRequest) async throws {
        guard let session = authService.currentSession() else {
            throw VPNAuthError.noStoredSession
        }
        request.setValue(
            VPNConstants.bearerPrefix + session.deviceSessionJwt,
            forHTTPHeaderField: VPNConstants.authorizationHeader
        )
    }
}
