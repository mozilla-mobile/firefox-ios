// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import XCTest

@testable import Client

@MainActor
final class AppAuthenticatorTests: XCTestCase {
    // MARK: - getAuthenticationState

    func test_getAuthenticationState_whenCanEvaluate_setsIsAuthenticatingTrue_thenFalse() {
        let subject = createSubject(canEvaluate: true, shouldSucceed: true)
        XCTAssertFalse(subject.isAuthenticating)

        // TODO: @dicarobinho
    }

    func test_getAuthenticationState_whenCannotEvaluate_setsIsAuthenticatingTrue_thenFalse() {
        let subject = createSubject(canEvaluate: false, shouldSucceed: false)
        XCTAssertFalse(subject.isAuthenticating)

        // TODO: @dicarobinho
    }

    // MARK: - authenticateWithDeviceOwnerAuthentication

    func test_authenticate_whenCanEvaluateAndContextSucceeds_setsIsAuthenticatingTrue_thenFalse() {
        let subject = createSubject(canEvaluate: true, shouldSucceed: true)
        let expectation = expectation(description: "Authentication should be completed")

        XCTAssertFalse(subject.isAuthenticating)

        subject.authenticateWithDeviceOwnerAuthentication { result in
            XCTAssertFalse(subject.isAuthenticating)
            expectation.fulfill()
        }

        XCTAssertTrue(subject.isAuthenticating)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticate_whenCanEvaluateButContextFails_setsIsAuthenticatingTrue_thenFalse() {
        let subject = createSubject(canEvaluate: true, shouldSucceed: false)
        XCTAssertFalse(subject.isAuthenticating)

        // TODO: @dicarobinho
    }

    func test_authenticate_whenCannotEvaluate_setsIsAuthenticatingTrue_thenFalse() {
        let subject = createSubject(canEvaluate: false, shouldSucceed: false)
        XCTAssertFalse(subject.isAuthenticating)

        // TODO: @dicarobinho
    }

    // MARK: - Helper

    func createSubject(
        canEvaluate: Bool,
        shouldSucceed: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AppAuthenticator {
        let context = MockLAContext()
        context.canEvaluate = canEvaluate
        context.shouldSucceed = shouldSucceed

        let subject = AppAuthenticator(context: context)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
