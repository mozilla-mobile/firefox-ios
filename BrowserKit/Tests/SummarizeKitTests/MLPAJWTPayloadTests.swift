// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import SummarizeKit

final class MLPAJWTPayloadTests: XCTestCase {
    func test_encode_returnsNonEmptyJWT() throws {
        let subject = createSubject()

        let jwt = try subject.encode()

        XCTAssertFalse(jwt.isEmpty)
    }

    func test_encode_returnsThreePartJWT() throws {
        let subject = createSubject()

        let jwt = try subject.encode()
        let parts = jwt.split(separator: ".")

        XCTAssertEqual(parts.count, 3, "JWT should have header.payload.signature")
    }

    func test_encode_containsExpectedFields() throws {
        let subject = createSubject(objectKey: AppAttestTestData.assertionKey)

        let jwt = try subject.encode()
        let parts = jwt.split(separator: ".")
        let payloadPart = String(parts[1])

        var base64 = payloadPart
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64.append("=") }

        let data = try XCTUnwrap(Data(base64Encoded: base64))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json[MLPAConstants.keyIdParam] as? String, AppAttestTestData.keyID)
        XCTAssertEqual(json[MLPAConstants.bundleIDParam] as? String, AppAttestTestData.bundleID)
        XCTAssertNotNil(json[MLPAConstants.challengeParam])
        XCTAssertNotNil(json[AppAttestTestData.assertionKey])
    }

    func test_encode_usesCorrectObjectKey() throws {
        let attestSubject = createSubject(objectKey: MLPAConstants.attestationObjParam)
        let assertSubject = createSubject(objectKey: MLPAConstants.assertionObjParam)

        let attestJWT = try attestSubject.encode()
        let assertJWT = try assertSubject.encode()

        let attestFields = try decodeJWTPayload(attestJWT)
        let assertFields = try decodeJWTPayload(assertJWT)

        XCTAssertNotNil(attestFields[MLPAConstants.attestationObjParam])
        XCTAssertNil(attestFields[MLPAConstants.assertionObjParam])

        XCTAssertNotNil(assertFields[MLPAConstants.assertionObjParam])
        XCTAssertNil(assertFields[MLPAConstants.attestationObjParam])
    }

    func test_encode_base64EncodesChallenge() throws {
        let subject = createSubject()

        let jwt = try subject.encode()
        let fields = try decodeJWTPayload(jwt)

        let challengeB64 = try XCTUnwrap(fields[MLPAConstants.challengeParam] as? String)
        let decoded = try XCTUnwrap(Data(base64Encoded: challengeB64))
        let original = String(data: decoded, encoding: .utf8)

        XCTAssertEqual(original, AppAttestTestData.challenge)
    }

    func test_encode_base64EncodesObjectData() throws {
        let subject = createSubject(
            objectKey: AppAttestTestData.attestationKey,
            objectData: AppAttestTestData.attestationBlob
        )

        let jwt = try subject.encode()
        let fields = try decodeJWTPayload(jwt)

        let objectB64 = try XCTUnwrap(fields[AppAttestTestData.attestationKey] as? String)
        let decoded = try XCTUnwrap(Data(base64Encoded: objectB64))

        XCTAssertEqual(decoded, AppAttestTestData.attestationBlob)
    }

    private func createSubject(
        keyId: String = AppAttestTestData.keyID,
        challenge: String = AppAttestTestData.challenge,
        objectKey: String = AppAttestTestData.attestationKey,
        objectData: Data = AppAttestTestData.assertionBlob,
        bundleIdentifier: String = AppAttestTestData.bundleID
    ) -> MLPAJWTPayload {
        return MLPAJWTPayload(
            keyId: keyId,
            challenge: challenge,
            objectKey: objectKey,
            objectData: objectData,
            bundleIdentifier: bundleIdentifier
        )
    }

    /// NOTE: This is only used in tests.
    /// If we ever need a proper decoder, it should be added in `JWTKit`.
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
