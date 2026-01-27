// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class TermsOfUseMigrationTests: XCTestCase {

    func testMigrateTermsOfServicePrefs_migratesFromTermsOfServiceAccepted() {
        let mockPrefs = MockProfilePrefs()

        // Set all legacy prefs
        mockPrefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)
        let testTimestamp = Date().toTimestamp()
        mockPrefs.setTimestamp(testTimestamp, forKey: PrefsKeys.TermsOfServiceAcceptedDate)
        mockPrefs.setString("4", forKey: PrefsKeys.TermsOfServiceAcceptedVersion)

        // Trigger migration explicitly
        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfServicePrefs()

        // Verify migration: new prefs are set
        XCTAssertTrue(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
        XCTAssertNotNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate))
        XCTAssertEqual(mockPrefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion), "4")

        // Verify old prefs are deleted
        XCTAssertNil(mockPrefs.intForKey(PrefsKeys.TermsOfServiceAccepted))
        XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.TermsOfServiceAcceptedDate))
        XCTAssertNil(mockPrefs.stringForKey(PrefsKeys.TermsOfServiceAcceptedVersion))
    }

    func testMigrateTermsOfServicePrefs_doesNotMigrateWhenTermsOfUseAcceptedExists() {
        let mockPrefs = MockProfilePrefs()

        mockPrefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        mockPrefs.setInt(1, forKey: PrefsKeys.TermsOfServiceAccepted)

        // Trigger migration - should not migrate since TermsOfUseAccepted already exists
        TermsOfUseMigration(prefs: mockPrefs).migrateTermsOfServicePrefs()

        XCTAssertTrue(mockPrefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false)
        // Old pref should still exist since migration didn't run
        XCTAssertNotNil(mockPrefs.intForKey(PrefsKeys.TermsOfServiceAccepted))
    }
}
