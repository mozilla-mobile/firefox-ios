// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import JWTKit
import Common
import Shared

final class JWTEncoderTests: XCTestCase {
    private static let mockSecret = "super-secret"

    nonisolated(unsafe) private static let mockPayload: [String: Any] = [
        "sub": "1234567890",
        "name": "John Doe",
        "admin": true
    ]

    nonisolated(unsafe) private static let invalidPayload: [String: Any] = [
        "invalid": Date()
    ]

    func testEncodeWithHS256ProducesThreePartsAndValidHeaderAndPayload() throws {
        let algorithm: JWTAlgorithm = .hs256(secret: Self.mockSecret)
        let subject = createSubject(algorithm: algorithm)

        let token = try subject.encode(payload: Self.mockPayload)
        let parts = token.split(separator: ".")

        XCTAssertEqual(parts.count, 3, "JWT should have header, payload, signature")

        let headerPart = String(parts[0])
        let payloadPart = String(parts[1])
        let signaturePart = String(parts[2])

        // Decode header and inspect JSON
        let headerData = try XCTUnwrap(Bytes.base64urlSafeDecodedData(headerPart), "Header must be valid base64url")
        let headerJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: headerData) as? [String: Any],
            "Header must be valid JSON"
        )

        XCTAssertEqual(headerJSON["alg"] as? String, algorithm.name)
        XCTAssertEqual(headerJSON["typ"] as? String, "JWT")

        // Decode payload and inspect JSON
        let payloadData = try XCTUnwrap(Bytes.base64urlSafeDecodedData(payloadPart), "Payload must be valid base64url")
        let decodedPayload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            "Payload must be valid JSON"
        )

        XCTAssertEqual(decodedPayload["sub"] as? String, Self.mockPayload["sub"] as? String)
        XCTAssertEqual(decodedPayload["name"] as? String, Self.mockPayload["name"] as? String)
        XCTAssertEqual(decodedPayload["admin"] as? Bool, Self.mockPayload["admin"] as? Bool)

        // Recompute expected signature using the same algorithm
        let signingInput = "\(headerPart).\(payloadPart)"
        let verifier = JWTHS256Algorithm(secret: Self.mockSecret)
        let expectedSignature = try verifier.sign(message: signingInput)

        XCTAssertEqual(signaturePart, expectedSignature)
    }

    func testEncodeWithNoneAlgorithmProducesEmptySignature() throws {
        let algorithm: JWTAlgorithm = .none
        let subject = createSubject(algorithm: algorithm)

        let token = try subject.encode(payload: Self.mockPayload)
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)

        XCTAssertEqual(parts.count, 3, "JWT should have header, payload, signature")

        let headerPart = String(parts[0])
        let payloadPart = String(parts[1])
        let signaturePart = String(parts[2])

        XCTAssertEqual(signaturePart, "", "none algorithm must produce an empty signature")

        let headerData = try XCTUnwrap(Bytes.base64urlSafeDecodedData(headerPart), "Header must be valid base64url")
        let headerJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: headerData) as? [String: Any],
            "Header must be valid JSON"
        )

        XCTAssertEqual(headerJSON["alg"] as? String, algorithm.name)
        XCTAssertEqual(headerJSON["typ"] as? String, "JWT")

        let payloadData = try XCTUnwrap(Bytes.base64urlSafeDecodedData(payloadPart), "Payload must be valid base64url")
        let decodedPayload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            "Payload must be valid JSON"
        )

        XCTAssertEqual(decodedPayload["sub"] as? String, Self.mockPayload["sub"] as? String)
        XCTAssertEqual(decodedPayload["name"] as? String, Self.mockPayload["name"] as? String)
        XCTAssertEqual(decodedPayload["admin"] as? Bool, Self.mockPayload["admin"] as? Bool)
    }

    func testEncodeThrowsOnInvalidJSONPayload() throws {
        let algorithm: JWTAlgorithm = .hs256(secret: Self.mockSecret)
        let subject = createSubject(algorithm: algorithm)

        XCTAssertThrowsError(try subject.encode(payload: Self.invalidPayload)) { error in
            XCTAssertEqual(error as? JWTError, .jsonEncoding)
        }
    }

    private func createSubject(algorithm: JWTAlgorithm) -> JWTEncoder {
        return JWTEncoder(algorithm: algorithm)
    }
}
