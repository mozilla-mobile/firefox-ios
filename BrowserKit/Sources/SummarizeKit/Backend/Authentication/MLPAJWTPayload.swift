// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JWTKit

/// Constants used for MLPA (Mozilla LLM Proxy Auth)
/// request construction and server contract fields.
enum MLPAConstants {
    static let authorizationHeader = "Authorization"
    static let bearerPrefix = "Bearer "

    static let keyIdParam = "key_id_b64"
    static let challengeParam = "challenge_b64"
    static let bundleIDParam = "bundle_id"

    static let attestationObjParam = "attestation_obj_b64"
    static let assertionObjParam = "assertion_obj_b64"

    static let serviceTypeHeader = "service-type"
    static let serviceTypeValue = "s2s"
    static let useAppAttestHeader = "use-app-attest"

    static let contentTypeHeader = "Content-Type"
    static let contentTypeJSON = "application/json"
    static let POST = "POST"

    static let baseURL = URL(string: "https://mlpa-prod-prod-mozilla.global.ssl.fastly.net")

    static var completionsEndpoint: URL? { baseURL?.appendingPathComponent("v1") }
    static var challengeEndpoint: URL? { baseURL?.appendingPathComponent("verify/challenge") }
    static var attestEndpoint: URL? { baseURL?.appendingPathComponent("verify/attest") }
}

/// The shared fields that every MLPA JWT envelope carries.
///
/// Both attestation (`MLPAAppAttestServer`) and per-request assertion
/// (`AppAttestRequestAuth`) build a JWT with the same structure:
struct MLPAJWTPayload {
    let keyId: String
    let challenge: String
    let objectKey: String
    let objectData: Data
    let bundleIdentifier: String

    /// Encodes this payload as a JWT Bearer token.
    ///
    /// NOTE: The JWT is used purely as a structured serialization format for passing
    /// assertion/attestation metadata in the Authorization header, not for cryptographic security.
    /// The server does this so it can verify signatures without needing to decode the HTTP body first,
    /// which can be expensive for large payloads.
    /// Actual request integrity is guaranteed by the App Attest assertion/attestation itself,
    /// which is signed by the device's Secure Enclave and verified server-side.
    ///
    /// The random HMAC secret is intentional: the server does not verify the
    /// JWT signature (and does not support the `none` algorithm), so a throwaway
    /// secret satisfies the encoder's requirements without implying any security contract.
    func encode() throws -> String {
        guard let challengeData = challenge.data(using: .utf8) else {
            throw AppAttestServiceError.invalidChallenge
        }

        let fields: [String: Any] = [
            MLPAConstants.keyIdParam: keyId,
            MLPAConstants.challengeParam: challengeData.base64EncodedString(),
            objectKey: objectData.base64EncodedString(),
            MLPAConstants.bundleIDParam: bundleIdentifier
        ]

        return try JWTEncoder(algorithm: .hs256(secret: UUID().uuidString)).encode(payload: fields)
    }
}
