// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import JWTKit

struct AppAttestRequestAuth: RequestAuthProtocol {
    private enum Constants {
        static let authorizationHeader = "Authorization"
        static let bearerPrefix = "Bearer "
        static let keyIdParam = "key_id_b64"
        static let challengeParam = "challenge_b64"
        static let attestationParam = "assertion_obj_b64"
        static let bundleIDParam = "bundle_id"
        static let serviceTypeHeader = "service-type"
        static let useAppAttestHeader = "use-app-attest"
        static let serviceTypeValue = "s2s"
        static let jwtSecret = UUID().uuidString
    }

    private let appAttestClient: AppAttestClient

    public init(appAttestClient: AppAttestClient) {
        self.appAttestClient = appAttestClient
    }

    public func authenticate(request: inout URLRequest) async throws {
        let body = request.httpBody ?? Data()
        let payload = try JSONSerialization.jsonObject(with: body) as? [String: Any] ?? [:]

        let result = try await appAttestClient.generateAssertion(payload: payload)

        let jwtPayload: [String: Any] = [
            Constants.keyIdParam: result.keyId,
            Constants.challengeParam: result.challenge.data(using: .utf8)!.base64EncodedString(),
            Constants.attestationParam: result.assertion.base64EncodedString(),
            Constants.bundleIDParam: AppInfo.bundleIdentifier
        ]
        let jwt = try JWTEncoder(algorithm: .hs256(secret: Constants.jwtSecret)).encode(payload: jwtPayload)

        request.setValue(Constants.bearerPrefix + jwt, forHTTPHeaderField: Constants.authorizationHeader)
        request.setValue(Constants.serviceTypeValue, forHTTPHeaderField: Constants.serviceTypeHeader)
        request.setValue("true", forHTTPHeaderField: Constants.useAppAttestHeader)
        request.httpBody = result.payload
    }
}
