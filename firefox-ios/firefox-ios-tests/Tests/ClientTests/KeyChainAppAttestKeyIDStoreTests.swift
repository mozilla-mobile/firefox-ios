// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

/// NOTE: This test is intentionally in `ClientTests` instead of `BrowserKit/Tests` since bare SPM packages
/// cannot have keychain entitlement meaning these tests will always fail for the wrong reasons.
final class KeychainAppAttestKeyIDStoreTests: XCTestCase {
    // Use a unique service per test run to avoid polluting real keychain entries.
    private static let testService = "org.mozilla.browserkit.appattest.keyid.test"
    private static let testAccount = "test"

    override func tearDown() {
        // Clean up after each test so keychain state doesn't leak between tests.
        let subject = createSubject()
        try? subject.clearKeyID()
        super.tearDown()
    }

    func test_loadKeyID_returnsNilWhenEmpty() {
        let subject = createSubject()

        XCTAssertNil(
            subject.loadKeyID(),
            "Expected loadKeyID() to return nil when no key has been saved."
        )
    }

    func test_saveKeyID_thenLoad_returnsSavedValue() throws {
        let subject = createSubject()
        let keyID = "test-key-id-abc123"

        try subject.saveKeyID(keyID)

        XCTAssertEqual(
            subject.loadKeyID(),
            keyID,
            "Expected loadKeyID() to return the value that was just saved."
        )
    }

    func test_saveKeyID_overwritesPreviousValue() throws {
        let subject = createSubject()
        try subject.saveKeyID("first-key")
        try subject.saveKeyID("second-key")

        XCTAssertEqual(
            subject.loadKeyID(),
            "second-key",
            "Expected saveKeyID() to overwrite the previously stored value."
        )
    }

    func test_saveKeyID_handlesSpecialCharacters() throws {
        let subject = createSubject()
        // Real keyIds from App Attest can contain base64 characters like +, /, =
        let keyID = "Q0pRLintD6idwWNtNgQQW+2EoWBwCXclP3qQx7PNIRw="
        try subject.saveKeyID(keyID)

        XCTAssertEqual(
            subject.loadKeyID(),
            keyID,
            "Expected loadKeyID() to correctly round-trip a base64-encoded keyId."
        )
    }

    func test_clearKeyID_removesStoredValue() throws {
        let subject = createSubject()

        try subject.saveKeyID("key-to-clear")
        try subject.clearKeyID()

        XCTAssertNil(
            subject.loadKeyID(),
            "Expected loadKeyID() to return nil after clearKeyID()."
        )
    }

    func test_clearKeyID_isIdempotent() {
        let subject = createSubject()

        XCTAssertNoThrow(
            try subject.clearKeyID(),
            "Expected clearKeyID() to not throw when there's nothing to clear."
        )

        XCTAssertNoThrow(
            try subject.clearKeyID(),
            "Expected clearKeyID() to not throw on a second call either."
        )
    }

    func test_separateInstances_withSameServiceAccount_shareState() throws {
        let first = createSubject()
        let second = createSubject()

        try first.saveKeyID("shared-key")

        XCTAssertEqual(
            second.loadKeyID(),
            "shared-key",
            "Expected two instances with the same service/account to share the same keychain entry."
        )
    }

    func test_separateInstances_withDifferentAccount_doNotShareState() throws {
        let subject = createSubject()
        let other = KeychainAppAttestKeyIDStore(
            service: Self.testService,
            account: "other-account"
        )

        try subject.saveKeyID("subject-key")

        XCTAssertNil(
            other.loadKeyID(),
            "Expected a different account to have its own isolated keychain entry."
        )

        // Clean up the other instance too.
        try? other.clearKeyID()
    }

    private func createSubject() -> KeychainAppAttestKeyIDStore {
        return KeychainAppAttestKeyIDStore(
            service: Self.testService,
            account: Self.testAccount
        )
    }
}
