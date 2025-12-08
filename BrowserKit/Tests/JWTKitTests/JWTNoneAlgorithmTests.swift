// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import JWTKit

final class JWTNoneAlgorithmTests: XCTestCase {
    func test_sign_producesEmptySignature() throws {
        let subject = createSubject()
        let signature = try subject.sign(message: "anything at all")
        XCTAssertEqual(signature, "", "none algorithm must produce an empty signature")
    }

    func test_verify_acceptsEmptySignature() throws {
        let subject = createSubject()
        XCTAssertNoThrow(try subject.verify(message: "msg", hasSignature: ""))
    }

    func test_verify_rejectsNonEmptySignature() throws {
        let subject = createSubject()
        XCTAssertThrowsError(try subject.verify(message: "msg", hasSignature: "not-empty")) { error in
            XCTAssertEqual(error as? JWTError, .invalidSignature)
        }
    }

    private func createSubject() -> JWTNoneAlgorithm {
        return JWTNoneAlgorithm()
    }
}
