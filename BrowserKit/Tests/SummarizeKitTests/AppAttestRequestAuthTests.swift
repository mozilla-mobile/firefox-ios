// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import SummarizeKit

final class AppAttestRequestAuthTests: XCTestCase {
    func test_authenticate_setsAuthorizationHeader() async throws {
        let subject = try createSubject()
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        let auth = request.value(forHTTPHeaderField: MLPAConstants.authorizationHeader)
        XCTAssertNotNil(auth)
        XCTAssertTrue(auth?.hasPrefix(MLPAConstants.bearerPrefix) == true)
    }

    func test_authenticate_setsServiceTypeHeader() async throws {
        let subject = try createSubject()
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        XCTAssertEqual(
            request.value(forHTTPHeaderField: MLPAConstants.serviceTypeHeader),
            MLPAConstants.serviceTypeValue
        )
    }

    func test_authenticate_setsAppAttestHeader() async throws {
        let subject = try createSubject()
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        XCTAssertEqual(
            request.value(forHTTPHeaderField: MLPAConstants.useAppAttestHeader),
            "true"
        )
    }

    func test_authenticate_setsPayloadAsBody() async throws {
        let subject = try createSubject()
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        XCTAssertNotNil(request.httpBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any])
        XCTAssertEqual(json["prompt"] as? String, "summarize this")
    }

    func test_authenticate_succeeds_whenNoStoredKey_byPerformingAttestation() async throws {
        let subject = try createSubject(storedKeyID: nil)
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        let auth = request.value(forHTTPHeaderField: MLPAConstants.authorizationHeader)
        XCTAssertNotNil(auth)
        XCTAssertTrue(auth?.hasPrefix(MLPAConstants.bearerPrefix) == true)
    }

    func test_authenticate_jwtContainsAssertionKey() async throws {
        let subject = try createSubject()
        var request = try makeRequest()

        try await subject.authenticate(request: &request)

        let auth = try XCTUnwrap(request.value(forHTTPHeaderField: MLPAConstants.authorizationHeader))
        let jwt = String(auth.dropFirst(MLPAConstants.bearerPrefix.count))
        let fields = try decodeJWTPayload(jwt)

        XCTAssertNotNil(fields[MLPAConstants.assertionObjParam])
        XCTAssertEqual(fields[MLPAConstants.keyIdParam] as? String, AppAttestTestData.keyID)
        XCTAssertNotNil(fields[MLPAConstants.challengeParam])
        XCTAssertNotNil(fields[MLPAConstants.bundleIDParam])
    }

    // MARK: - Helpers

    private func createSubject(
        storedKeyID: String? = AppAttestTestData.keyID,
        challenge: String = AppAttestTestData.challenge,
        assertionBlob: Data = AppAttestTestData.assertionBlob,
        bundleIdentifier: String = AppAttestTestData.bundleID
    ) throws -> AppAttestRequestAuth {
        let keyStore = MockAppAttestKeyIDStore(initial: storedKeyID)
        let server = MockAppAttestRemoteServer()
        server.challengeToReturn = challenge
        let service = MockAppAttestService(isSupported: true)
        service.assertionToReturn = assertionBlob

        let client = try AppAttestClient(
            appAttestService: service,
            remoteServer: server,
            keyStore: keyStore
        )

        return AppAttestRequestAuth(
            appAttestClient: client,
            bundleIdentifier: bundleIdentifier
        )
    }

    private func makeRequest() throws -> URLRequest {
        var request = URLRequest(url: AppAttestTestData.requestURL)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: AppAttestTestData.requestBody)
        return request
    }

    private func decodeJWTPayload(_ jwt: String) throws -> [String: Any] {
        let parts = jwt.split(separator: ".")
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }
        let data = try XCTUnwrap(Data(base64Encoded: base64))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
