// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Shared

public struct IPProtectionProxyToken: Decodable, Equatable, Sendable {
    public let token: String
    public let expiresIn: Int
}

public protocol IPProtectionProxyTokenFetching: Sendable {
    func fetchProxyToken() async throws -> IPProtectionProxyToken
}

/// Exchanges a Device Session JWT for a short-lived proxy token.
public struct IPProtectionProxyTokenService: IPProtectionProxyTokenFetching {
    private let environmentType: IPProtectionEnvironment
    private let urlSession: URLSessionProtocol
    private let requestAuth: RequestAuthProtocol
    private let authService: IPProtectionAuthenticating

    public init(
        with type: IPProtectionEnvironment = .prod,
        urlSession: URLSessionProtocol = URLSession.shared,
        authService: IPProtectionAuthenticating
    ) {
        self.environmentType = type
        self.urlSession = urlSession
        self.authService = authService
        self.requestAuth = IPProtectionSessionRequestAuth(authService: authService)
    }

    public func fetchProxyToken() async throws -> IPProtectionProxyToken {
        do {
            return try await requestToken()
        } catch IPProtectionError.sessionRejected {
            // Refresh once and retry; a second failure is surfaced to the caller.
            _ = try await authService.refresh()
            return try await requestToken()
        }
    }

    private func requestToken() async throws -> IPProtectionProxyToken {
        guard let endpoint = IPProtectionConstants.tokenEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "tokenEndpoint")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = IPProtectionConstants.GET
        try await requestAuth.authenticate(request: &request)

        let (data, response) = try await urlSession.data(from: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 {
                throw IPProtectionError.sessionRejected
            }
            guard (200..<300).contains(http.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
                throw AppAttestServiceError.serverError(description: "\(http.statusCode): \(message)")
            }
        }
        return try JSONDecoder().decode(IPProtectionProxyToken.self, from: data)
    }
}
