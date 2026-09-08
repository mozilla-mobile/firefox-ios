// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import IPProtectionKit

/// NOTE: This test is intentionally in `ClientTests` instead of `BrowserKit/Tests` since bare SPM packages
/// cannot have keychain entitlement meaning these tests will always fail for the wrong reasons.
final class KeychainIPProtectionTokenStoreTests: XCTestCase {
    // Use a unique service per test run to avoid polluting real keychain entries.
    private static let testService = "org.mozilla.browserkit.ipprotection.dsj.test"
    private static let testAccount = "test"

    private let sampleSession = IPProtectionDeviceSession(
        deviceSessionJwt: "header.payload.signature",
        expiresAt: 32503680000000,
        renewAfter: 32503670000000
    )

    override func tearDown() {
        let subject = createSubject()
        try? subject.clear()
        super.tearDown()
    }

    func test_load_returnsNilWhenEmpty() {
        let subject = createSubject()

        XCTAssertNil(subject.load(), "Expected load() to return nil when no session has been saved.")
    }

    func test_save_thenLoad_returnsSavedSession() throws {
        let subject = createSubject()

        try subject.save(sampleSession)

        XCTAssertEqual(subject.load(), sampleSession, "Expected load() to return the saved session.")
    }

    func test_save_overwritesPreviousSession() throws {
        let subject = createSubject()
        let updated = IPProtectionDeviceSession(deviceSessionJwt: "new.jwt", expiresAt: 1, renewAfter: 0)

        try subject.save(sampleSession)
        try subject.save(updated)

        XCTAssertEqual(subject.load(), updated, "Expected save() to overwrite the previous session.")
    }

    func test_clear_removesStoredSession() throws {
        let subject = createSubject()

        try subject.save(sampleSession)
        try subject.clear()

        XCTAssertNil(subject.load(), "Expected load() to return nil after clear().")
    }

    func test_clear_isIdempotent() {
        let subject = createSubject()

        XCTAssertNoThrow(try subject.clear(), "Expected clear() to not throw when there's nothing to clear.")
        XCTAssertNoThrow(try subject.clear(), "Expected clear() to not throw on a second call either.")
    }

    func test_separateInstances_withDifferentAccount_doNotShareState() throws {
        let subject = createSubject()
        let other = KeychainIPProtectionTokenStore(service: Self.testService, account: "other-account")

        try subject.save(sampleSession)

        XCTAssertNil(other.load(), "Expected a different account to have its own isolated keychain entry.")
        try? other.clear()
    }

    private func createSubject() -> KeychainIPProtectionTokenStore {
        return KeychainIPProtectionTokenStore(service: Self.testService, account: Self.testAccount)
    }
}
