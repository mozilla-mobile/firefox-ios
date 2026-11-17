// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Shared

public protocol VPNProxyTokenFetching: Sendable {
    func fetchProxyPass() async throws -> VPNProxyPass
    /// Current bandwidth usage; works even when the quota is exhausted.
    func fetchEntitlement() async throws -> VPNProxyUsage
}

/// Exchanges a Device Session JWT for a short-lived proxy token or the device's bandwidth usage.
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
        let (data, response) = try await get(
            VPNConstants.tokenEndpoint(with: environmentType),
            name: "tokenEndpoint"
        )
        return try Self.makePass(from: data, response: response)
    }

    public func fetchEntitlement() async throws -> VPNProxyUsage {
        let (data, _) = try await get(
            VPNConstants.entitlementEndpoint(with: environmentType),
            name: "entitlementEndpoint"
        )
        return try VPNProxyUsage(entitlementData: data)
    }

    private func get(_ endpoint: URL?, name: String) async throws -> (Data, URLResponse) {
        guard let endpoint else {
            throw AppAttestServiceError.invalidURL(description: name)
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = VPNConstants.GET
        request.cachePolicy = .reloadIgnoringLocalCacheData
        try await requestAuth.authenticate(request: &request)

        var (data, response) = try await urlSession.data(from: request)
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            // Refresh once and retry; a second failure is surfaced to the caller.
            _ = try await authService.refresh()
            try await requestAuth.authenticate(request: &request)
            (data, response) = try await urlSession.data(from: request)
        }

        switch (response as? HTTPURLResponse)?.statusCode {
        case 401:
            throw VPNAuthError.sessionRejected
        case 429:
            throw VPNAuthError.quotaExceeded
        default:
            try AppAttestServiceError.validate(response: response, data: data)
            return (data, response)
        }
    }

    private static func makePass(from data: Data, response: URLResponse) throws -> VPNProxyPass {
        let token = try JSONDecoder().decode(TokenResponse.self, from: data).token
        let claims = try decodeJWTClaims(token)
        return VPNProxyPass(
            bearerToken: token,
            notBefore: claims.nbf.map { Date(timeIntervalSince1970: $0) } ?? Date(),
            expiresAt: Date(timeIntervalSince1970: claims.exp),
            usage: VPNProxyUsage(response: response)
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
