// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class TermsOfUseMigrationTests: XCTestCase {
    func testMigrateTermsOfServicePrefs_preservesExistingDateAndVersion() {
        let mockPrefs = MockProfilePrefs()

        // Set all legacy prefs
        mockPrefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        let testTimestamp = Date().toTimestamp()
        mockPrefs.setTimestamp(testTimestamp, forKey: PrefsKeys.TermsOfServiceAcceptedDate)
        mockPrefs.setString("123", forKey: PrefsKeys.TermsOfServiceAcceptedVersion)

        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfService()

        // Verify migration: new prefs are set
        XCTAssertTrue(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
        XCTAssertEqual(mockPrefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate), testTimestamp)
        XCTAssertEqual(mockPrefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion), "123")

        // Verify old prefs are deleted
        XCTAssertNil(mockPrefs.intForKey(PrefsKeys.TermsOfServiceAccepted))
        XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate))
        XCTAssertNil(mockPrefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion))
    }

    func testMigrateTermsOfServicePrefs_migratesFromTermsOfServiceAccepted_withoutDateAndVersion() {
        let mockPrefs = MockProfilePrefs()

        mockPrefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfService()

        // ToU pref should be set
        XCTAssertTrue(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
        // Date and version should be backfilled
        XCTAssertNotNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate))
        XCTAssertEqual(mockPrefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion), "4")

        // Verify old prefs are deleted
        XCTAssertNil(mockPrefs.intForKey(PrefsKeys.TermsOfServiceAccepted))
        XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate))
        XCTAssertNil(mockPrefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion))
    }

    func testMigrateTermsOfServicePrefs_ForUsersWithOnlyTermsOfUseAccepted() {
        let mockPrefs = MockProfilePrefs()

        // User has accepted ToU (no legacy ToS) - no migration needed
        mockPrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfService()

        // ToU prefs should remain unchanged (no date/version created).
        XCTAssertTrue(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
        XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate))
        XCTAssertNil(mockPrefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion))
    }

    func testMigrateTermsOfServicePrefs_doesNothingWhenNoAcceptancePrefs() {
        let mockPrefs = MockProfilePrefs()

        // No ToS/ToU prefs set
        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfService()

        XCTAssertNil(mockPrefs.intForKey(PrefsKeys.TermsOfServiceAccepted))
        XCTAssertNil(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted))
        XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate))
        XCTAssertNil(mockPrefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion))
    }
}
