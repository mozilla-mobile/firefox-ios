// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import JWTKit
import Common

final class JWTHeaderTests: XCTestCase {
    func test_init_setsAlgAndTypCorrectly() throws {
        let algorithm: JWTAlgorithm = .hs256(secret: "irrelevant")
        let subject = createSubject(algorithm: algorithm)

        XCTAssertEqual(subject.alg, algorithm.name)
        XCTAssertEqual(subject.typ, "JWT")
    }

    func test_encoded_producesValidBase64URLAndJSON() throws {
        let algorithm: JWTAlgorithm = .none
        let subject = createSubject(algorithm: algorithm)

        let encoded = try subject.encoded()

        let data = try XCTUnwrap(Bytes.base64urlSafeDecodedData(encoded))
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )

        XCTAssertEqual(json["alg"] as? String, algorithm.name)
        XCTAssertEqual(json["typ"] as? String, "JWT")
    }

    private func createSubject(algorithm: JWTAlgorithm) -> JWTHeader {
        return JWTHeader(algorithm: algorithm)
    }
}
