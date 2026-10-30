// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Shared

public protocol VPNProxyTokenFetching: Sendable {
    func fetchProxyPass() async throws -> VPNProxyPass
}

/// Exchanges a Device Session JWT for a short-lived proxy token.
public struct VPNProxyTokenService: VPNProxyTokenFetching {
    private let environmentType: VPNEnvironment
    private let urlSession: URLSessionProtocol
    private let requestAuth: RequestAuthProtocol
    private let authService: VPNAuthenticating

    private struct TokenResponse: Decodable {
        let token: String
    }

    private struct JWTClaims: Decodable {
        let nbf: TimeInterval?
        let exp: TimeInterval
    }

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

    public func fetchProxyPass() async throws -> VPNProxyPass {
        do {
            return try await requestToken()
        } catch VPNAuthError.sessionRejected {
            // Refresh once and retry; a second failure is surfaced to the caller.
            _ = try await authService.refresh()
            return try await requestToken()
        }
    }

    private func requestToken() async throws -> VPNProxyPass {
        guard let endpoint = VPNConstants.tokenEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "tokenEndpoint")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = VPNConstants.GET
        request.cachePolicy = .reloadIgnoringLocalCacheData
        try await requestAuth.authenticate(request: &request)

        let (data, response) = try await urlSession.data(from: request)
        // A rejected session is recoverable by refreshing, so it is separated from other failures.
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            throw VPNAuthError.sessionRejected
        }
        try AppAttestServiceError.validate(response: response, data: data)
        let token = try JSONDecoder().decode(TokenResponse.self, from: data).token
        return try Self.makePass(from: token)
    }

    private static func makePass(from token: String) throws -> VPNProxyPass {
        let claims = try decodeJWTClaims(token)
        return VPNProxyPass(
            bearerToken: token,
            notBefore: claims.nbf.map { Date(timeIntervalSince1970: $0) } ?? Date(),
            expiresAt: Date(timeIntervalSince1970: claims.exp),
            usage: nil
        )
    }

    private static func decodeJWTClaims(_ jwt: String) throws -> JWTClaims {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else {
            throw VPNAuthError.invalidToken
        }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload) else {
            throw VPNAuthError.invalidToken
        }
        do {
            return try JSONDecoder().decode(JWTClaims.self, from: data)
        } catch {
            throw VPNAuthError.invalidToken
        }
    }
}
