// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class AppAuthenticatorTests: XCTestCase {
    func test_authenticate_setsIsAuthenticatingTrue_thenFalse_onSuccess() {
        let mock = MockLAContext()
        mock.canEvaluate = true
        mock.shouldSucceed = true

        let subject = AppAuthenticator(context: mock)
        let expectation = expectation(description: "Authentication should be completed")

        XCTAssertFalse(subject.isAuthenticating)

        subject.authenticateWithDeviceOwnerAuthentication { result in
            XCTAssertFalse(subject.isAuthenticating)
            expectation.fulfill()
        }

        XCTAssertTrue(subject.isAuthenticating)

        wait(for: [expectation], timeout: 1.0)
    }
}
