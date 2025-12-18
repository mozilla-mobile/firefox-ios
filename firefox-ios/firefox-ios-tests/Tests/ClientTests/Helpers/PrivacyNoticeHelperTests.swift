// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

final class PrivacyNoticeHelperTests: XCTestCase {
    var prefs: MockProfilePrefs!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    func test_shouldShowPrivacyNotice_whenNoAcceptanceDate_returnsFalse() {
        let subject = createSubject()

        let result = subject.shouldShowPrivacyNotice()

        XCTAssertFalse(result)
    }

    func test_shouldShowPrivacyNotice_whenAcceptanceAfterUpdate_returnsFalse() {
        let subject = createSubject()
        let now = subject.privacyNoticeUpdateInMilliseconds + 1000
        prefs.setTimestamp(now, forKey: PrefsKeys.TermsOfServiceAcceptedDate)

        let result = subject.shouldShowPrivacyNotice()

        XCTAssertFalse(result)
    }

    func test_shouldShowPrivacyNotice_whenAcceptedBeforeUpdate_butAlreadyNotified_returnsFalse() {
        let subject = createSubject()

        // Acceptance was before the update
        let acceptance = subject.privacyNoticeUpdateInMilliseconds - 10000
        prefs.setTimestamp(acceptance, forKey: PrefsKeys.TermsOfServiceAcceptedDate)

        // Notified after the update
        let notified = subject.privacyNoticeUpdateInMilliseconds + 10000
        prefs.setTimestamp(notified, forKey: PrefsKeys.PrivacyNotice.notifiedDate)

        let result = subject.shouldShowPrivacyNotice()

        XCTAssertFalse(result)
    }

    func test_shouldShowPrivacyNotice_whenAcceptedBeforeUpdate_andNotNotified_returnsTrueAndSetsNotifiedDate() {
        let subject = createSubject()

        // Acceptance before update
        let acceptance = subject.privacyNoticeUpdateInMilliseconds - 10000
        prefs.setTimestamp(acceptance, forKey: PrefsKeys.TermsOfServiceAcceptedDate)

        // No prior notification
        XCTAssertNil(prefs.timestampForKey(PrefsKeys.PrivacyNotice.notifiedDate))

        let result = subject.shouldShowPrivacyNotice()

        XCTAssertTrue(result)

        // Should set notified date in prefs
        let newNotifiedDate = prefs.timestampForKey(PrefsKeys.PrivacyNotice.notifiedDate)
        XCTAssertNotNil(newNotifiedDate)
    }

    func test_shouldShowPrivacyNotice_whenAcceptedBeforeUpdate_andNotifiedBeforeUpdate_returnsTrueAndUpdatesTimestamp() {
        let subject = createSubject()

        let acceptance = subject.privacyNoticeUpdateInMilliseconds - 100000
        let oldNotified = subject.privacyNoticeUpdateInMilliseconds - 200000

        prefs.setTimestamp(acceptance, forKey: PrefsKeys.TermsOfServiceAcceptedDate)
        prefs.setTimestamp(oldNotified, forKey: PrefsKeys.PrivacyNotice.notifiedDate)

        let result = subject.shouldShowPrivacyNotice()

        XCTAssertTrue(result)

        // Should set notified date in prefs
        let newNotifiedDate = prefs.timestampForKey(PrefsKeys.PrivacyNotice.notifiedDate)
        XCTAssertNotNil(newNotifiedDate)
    }

    // MARK: - Helper Methods

    private func createSubject() -> PrivacyNoticeHelper {
        return PrivacyNoticeHelper(prefs: prefs)
    }
}
