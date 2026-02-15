// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JWTKit
import Shared

public struct MLPAAppAttestServer: AppAttestRemoteServerProtocol {
    private struct ChallengeResponse: Decodable {
        let challenge: String
    }

    private enum Constants {
        static let baseURL = URL(string: "https://mlpa-dev.llm-proxy.nonprod.dataservices.mozgcp.net")!
        static let challengeEndpoint = baseURL.appendingPathComponent("/verify/challenge")
        static let attestEndpoint = baseURL.appendingPathComponent("/verify/attest")
        static let contentTypeHeader = "Content-Type"
        static let authorizationHeader = "authorization"
        static let contentTypeJSON = "application/json"
        static let bearerPrefix = "Bearer "
        static let keyIdParam = "key_id_b64"
        static let challengeParam = "challenge_b64"
        static let attestationParam = "attestation_obj_b64"
        static let jwtSecret = UUID().uuidString
    }

    private let urlSession: URLSessionProtocol

    public init(urlSession: URLSessionProtocol = URLSession.shared) {
        self.urlSession = urlSession
    }

    /// Fetches a random server-generated challenge for the given `keyId`.
    /// The challenge is used exactly once to prevent replay attacks.
    ///
    /// The `keyId` is passed as a query parameter and must be percent-encoded
    /// because Base64 values can contain `+`, `/`, and `=` characters that
    /// would otherwise break the URL.
    public func fetchChallenge(for keyId: String) async throws -> String {
        guard let encodedKeyId = keyId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "\(Constants.challengeEndpoint.absoluteString)?\(Constants.keyIdParam)=\(encodedKeyId)") else {
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
        let jwtPayload: [String: Any] = [
            Constants.keyIdParam: keyId,
            Constants.challengeParam: challenge.data(using: .utf8)!.base64EncodedString(),
            Constants.attestationParam: attestationObject.base64EncodedString()
        ]

        let jwt = try JWTEncoder(algorithm: .hs256(secret: Constants.jwtSecret)).encode(payload: jwtPayload)

        var request = URLRequest(url: Constants.attestEndpoint)
        request.httpMethod = "POST"
        request.setValue(Constants.contentTypeJSON, forHTTPHeaderField: Constants.contentTypeHeader)
        request.setValue(Constants.bearerPrefix + jwt, forHTTPHeaderField: Constants.authorizationHeader)
        /// TODO(FXIOS-xxx): Since signing happens at the hardware level we don't have access to the signing certificates.
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
