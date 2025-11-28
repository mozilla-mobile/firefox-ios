// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import JWTKit

final class JWTHS256AlgorithmTests: XCTestCase {
    private static let mockSecret = "super-secret"
    private static let mockMessage = "header.payload"

    func test_signAndVerify_roundTrip() throws {
        let subject = createSubject(secret: Self.mockSecret)
        let signature = try subject.sign(message: Self.mockMessage)
        XCTAssertNoThrow(
            try subject.verify(message: Self.mockMessage, hasSignature: signature),
            "expected verify to not throw"
        )
    }

    func test_verify_failsForTamperedMessage() throws {
        let subject = createSubject(secret: Self.mockSecret)
        let tamperedMessage = "header.payload-tampered"

        let signature = try subject.sign(message: Self.mockMessage)

        XCTAssertThrowsError(try subject.verify(message: tamperedMessage, hasSignature: signature)) { error in
            XCTAssertEqual(error as? JWTError, .invalidSignature, "expected signature to be invalid")
        }
    }

    func test_verify_failsForMalformedBase64Signature() {
        let subject = createSubject(secret: Self.mockSecret)
        let malformedSignature = "!!!!"

        XCTAssertThrowsError(try subject.verify(message: Self.mockMessage, hasSignature: malformedSignature)) { error in
            XCTAssertEqual(error as? JWTError, .base64Decoding, "expected a decoding error")
        }
    }

    func test_verify_failsForModifiedSignature() throws {
        let subject = createSubject(secret: Self.mockSecret)
        let signature = try subject.sign(message: Self.mockMessage)

        // Flip the last character (just to ensure it actually changes)
        var chars = Array(signature)
        if let last = chars.last {
            chars[chars.count - 1] = last == "A" ? "B" : "A"
        }
        let modifiedSignature = String(chars)

        XCTAssertNotEqual(signature, modifiedSignature)

        XCTAssertThrowsError(try subject.verify(message: Self.mockMessage, hasSignature: modifiedSignature)) { error in
            XCTAssertEqual(error as? JWTError, .invalidSignature, "expected signature to be invalid")
        }
    }

    private func createSubject(secret: String) -> JWTHS256Algorithm {
        return JWTHS256Algorithm(secret: secret)
    }
}
