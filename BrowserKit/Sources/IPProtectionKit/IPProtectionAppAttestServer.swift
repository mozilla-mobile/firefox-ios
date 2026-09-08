// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AppAttestKit
import Foundation
import Shared

public protocol IPProtectionSessionRefreshing: Sendable {
    func refreshSession(assertion: AssertionResult) async throws
}

public struct IPProtectionAppAttestServer: AppAttestRemoteServerProtocol, IPProtectionSessionRefreshing {
    private struct ChallengeRequest: Encodable {
        let keyId: String
    }

    private struct ChallengeResponse: Decodable {
        let challenge: String
    }

    private struct EnrollmentRequest: Encodable {
        let keyId: String
        let attestationObject: String
        let challenge: String
    }

    private struct AssertionRequest: Encodable {
        let keyId: String
        let assertion: String
        let challenge: String
    }

    private let environmentType: IPProtectionEnvironment
    private let urlSession: URLSessionProtocol
    private let tokenStore: IPProtectionTokenStore

    public init(
        with type: IPProtectionEnvironment = .prod,
        urlSession: URLSessionProtocol = URLSession.shared,
        tokenStore: IPProtectionTokenStore
    ) {
        self.environmentType = type
        self.urlSession = urlSession
        self.tokenStore = tokenStore
    }

    /// Fetches a random, single-use server-generated challenge for the given `keyId`.
    public func fetchChallenge(for keyId: String) async throws -> String {
        guard let endpoint = IPProtectionConstants.challengeEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "challengeEndpoint")
        }

        let request = try Self.jsonRequest(url: endpoint, body: ChallengeRequest(keyId: keyId))
        let (data, response) = try await urlSession.data(from: request)
        try Self.validate(response: response, data: data)
        return try JSONDecoder().decode(ChallengeResponse.self, from: data).challenge
    }

    /// Sends the attestation object to the backend and persists the returned Device Session JWT
    /// to the token store on success.
    public func sendAttestation(
        keyId: String,
        attestationObject: Data,
        challenge: String
    ) async throws {
        guard let endpoint = IPProtectionConstants.enrollmentEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "enrollmentEndpoint")
        }

        let body = EnrollmentRequest(
            keyId: keyId,
            attestationObject: attestationObject.base64EncodedString(),
            challenge: challenge
        )
        let request = try Self.jsonRequest(url: endpoint, body: body)
        let (data, response) = try await urlSession.data(from: request)
        try Self.validate(response: response, data: data)

        let session = try JSONDecoder().decode(IPProtectionDeviceSession.self, from: data)
        try tokenStore.save(session)
    }

    /// Exchanges assertion for a fresh Device Session JWT. Persists the new session on success.
    public func refreshSession(assertion: AssertionResult) async throws {
        guard let endpoint = IPProtectionConstants.refreshEndpoint(with: environmentType) else {
            throw AppAttestServiceError.invalidURL(description: "refreshEndpoint")
        }

        let body = AssertionRequest(
            keyId: assertion.keyId,
            assertion: assertion.assertion.base64EncodedString(),
            challenge: assertion.challenge
        )
        let request = try Self.jsonRequest(url: endpoint, body: body)
        let (data, response) = try await urlSession.data(from: request)
        try Self.validate(response: response, data: data)

        let session = try JSONDecoder().decode(IPProtectionDeviceSession.self, from: data)
        try tokenStore.save(session)
    }

    private static func jsonRequest<Body: Encodable>(url: URL, body: Body) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = IPProtectionConstants.POST
        request.setValue(
            IPProtectionConstants.contentTypeJSON,
            forHTTPHeaderField: IPProtectionConstants.contentTypeHeader
        )
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AppAttestServiceError.serverError(description: "\(http.statusCode): \(message)")
        }
    }
}
