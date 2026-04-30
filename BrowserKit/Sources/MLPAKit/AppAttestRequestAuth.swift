// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Bridges App Attest authentication into the `RequestAuthProtocol` pipeline.
///
/// For each outgoing request, this authenticator:
/// 1. Extracts the JSON body as the assertion payload.
/// 2. Asks `AppAttestClient` to generate a signed assertion.
/// 3. Wraps the assertion metadata in a JWT and attaches it as a Bearer token.
public struct AppAttestRequestAuth: RequestAuthProtocol {
    private let appAttestClient: AppAttestClient
    private let bundleIdentifier: String
    private let serviceType: MLPAServiceType

    public init(
        appAttestClient: AppAttestClient,
        bundleIdentifier: String = AppInfo.bundleIdentifier,
        serviceType: MLPAServiceType
    ) {
        self.appAttestClient = appAttestClient
        self.bundleIdentifier = bundleIdentifier
        self.serviceType = serviceType
    }

    public func authenticate(request: inout URLRequest) async throws {
        // Make sure the server trust is established before sending any requests.
        // This should only be needed for the first request, subsequent requests will reuse the same attestation.
        _ = try await appAttestClient.performAttestation()

        let body = request.httpBody ?? Data()
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any] ?? [:]

        let result = try await appAttestClient.generateAssertion(payload: payload)

        let jwt = try MLPAJWTPayload(
            keyId: result.keyId,
            challenge: result.challenge,
            objectKey: MLPAConstants.assertionObjParam,
            objectData: result.assertion,
            bundleIdentifier: bundleIdentifier
        ).encode()

        request.setValue(MLPAConstants.bearerPrefix + jwt, forHTTPHeaderField: MLPAConstants.authorizationHeader)
        request.setValue(serviceType.rawValue, forHTTPHeaderField: MLPAConstants.serviceTypeHeader)
        request.setValue("true", forHTTPHeaderField: MLPAConstants.useAppAttestHeader)
        request.httpBody = result.payload
    }
}
