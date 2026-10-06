// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Shared

public struct VPNProxyToken: Decodable, Equatable, Sendable {
    public let token: String
    public let expiresIn: Int
}

public protocol VPNProxyTokenFetching: Sendable {
    func fetchProxyToken() async throws -> VPNProxyToken
}

/// Exchanges a Device Session JWT for a short-lived proxy token.
public struct VPNProxyTokenService: VPNProxyTokenFetching {
    private let environmentType: VPNEnvironment
    private let urlSession: URLSessionProtocol
    private let requestAuth: RequestAuthProtocol
    private let authService: VPNAuthenticating

    public init(
        with type: VPNEnvironment = .prod,
        urlSession: URLSessionProtocol = URLSession.shared,
        authService: VPNAuthenticating
    ) {
        self.environmentType = type
        self.urlSession = urlSession
        self.authService = authService
        self.requestAuth = VPNSessionRequestAuth(authService: authService)
    }

    public func fetchProxyToken() async throws -> VPNProxyToken {
        do {
            return try await requestToken()
        } catch VPNAuthError.sessionRejected {
            // Refresh once and retry; a second failure is surfaced to the caller.
            _ = try await authService.refresh()
            return try await requestToken()
        }
    }

    private func requestToken() async throws -> VPNProxyToken {
        guard let endpoint = VPNConstants.tokenEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "tokenEndpoint")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = VPNConstants.GET
        try await requestAuth.authenticate(request: &request)

        let (data, response) = try await urlSession.data(from: request)
        // A rejected session is recoverable by refreshing, so it is separated from other failures.
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            throw VPNAuthError.sessionRejected
        }
        try AppAttestServiceError.validate(response: response, data: data)
        return try JSONDecoder().decode(VPNProxyToken.self, from: data)
    }
}
