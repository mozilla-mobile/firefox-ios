// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

public struct MLPAAppAttestServer: AppAttestRemoteServerProtocol {
    private struct ChallengeResponse: Decodable {
        let challenge: String
    }

    private let bundleIdentifier: String
    private let urlSession: URLSessionProtocol

    public init(urlSession: URLSessionProtocol = URLSession.shared, bundleIdentifier: String = AppInfo.bundleIdentifier) {
        self.urlSession = urlSession
        self.bundleIdentifier = bundleIdentifier
    }

    /// Fetches a random server-generated challenge for the given `keyId`.
    /// The challenge is used exactly once to prevent replay attacks.
    ///
    /// The `keyId` is passed as a query parameter and must be percent-encoded
    /// because Base64 values can contain `+`, `/`, and `=` characters that
    /// would otherwise break the URL.
    public func fetchChallenge(for keyId: String) async throws -> String {
        guard let challengeEndpoint = MLPAConstants.challengeEndpoint else {
            throw AppAttestServiceError.invalidURL(description: "challengeEndpoint")
        }

        var components = URLComponents(url: challengeEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: MLPAConstants.keyIdParam, value: keyId)
        ]

        guard let url = components?.url else {
            throw AppAttestServiceError.invalidKeyID
        }

        let (data, response) = try await urlSession.data(from: url)
        try Self.validate(response: response, data: data)
        return try JSONDecoder().decode(ChallengeResponse.self, from: data).challenge
    }

    /// Sends the attestation object to the server for one-time trust establishment.
    ///
    /// The server validates Apple's certificate chain and persists the public key
    /// keyed by the `keyId`.
    public func sendAttestation(
        keyId: String,
        attestationObject: Data,
        challenge: String
    ) async throws {
        guard let attestEndpoint = MLPAConstants.attestEndpoint else {
            throw AppAttestServiceError.invalidURL(description: "attestEndpoint")
        }

        let jwt = try MLPAJWTPayload(
            keyId: keyId,
            challenge: challenge,
            objectKey: MLPAConstants.attestationObjParam,
            objectData: attestationObject,
            bundleIdentifier: bundleIdentifier
        ).encode()

        var request = URLRequest(url: attestEndpoint)
        request.httpMethod = MLPAConstants.POST
        request.setValue(MLPAConstants.contentTypeJSON, forHTTPHeaderField: MLPAConstants.contentTypeHeader)
        request.setValue(MLPAConstants.bearerPrefix + jwt, forHTTPHeaderField: MLPAConstants.authorizationHeader)
        /// TODO(FXIOS-14902): Since signing happens at the hardware level we don't have access to the signing certificates.
        /// This means app attest attestation and assertions can only be generated on real devices, not simulators.
        /// To enable testing on simulators, we can use a special header to tell the server to accept test certificates.
        /// request.setValue("true", forHTTPHeaderField: "use-qa-certificates")

        let (data, response) = try await urlSession.data(from: request)
        try Self.validate(response: response, data: data)
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AppAttestServiceError.serverError(description: "\(http.statusCode): \(message)")
        }
    }
}
