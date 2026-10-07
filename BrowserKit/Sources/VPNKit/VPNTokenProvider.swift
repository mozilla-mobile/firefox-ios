// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public protocol VPNTokenProviding: Sendable {
    /// A valid proxy token, will re-attest as needed.
    func proxyToken() async throws -> VPNProxyToken
}

/// The single entry point for callers that just need a proxy credential.
public struct VPNTokenProvider: VPNTokenProviding {
    private let authService: VPNAuthenticating
    private let tokenService: VPNProxyTokenFetching

    public init(authService: VPNAuthenticating, tokenService: VPNProxyTokenFetching) {
        self.authService = authService
        self.tokenService = tokenService
    }

    public func proxyToken() async throws -> VPNProxyToken {
        // Establishing the session first is what makes this work on a fresh install, where there is
        // nothing to exchange yet.
        _ = try await authService.authenticate()

        // `fetchProxyToken()` already refreshes and retries once on a rejected session; retrying
        // here as well would square that.
        return try await tokenService.fetchProxyToken()
    }
}
