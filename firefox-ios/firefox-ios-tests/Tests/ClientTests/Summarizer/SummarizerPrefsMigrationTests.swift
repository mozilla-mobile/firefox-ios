// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class SummarizerPrefsMigrationTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private let itTestLanguage = "it-IT"
    private let deTestLanguage = "de-DE"

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() {
        prefs = nil
        super.tearDown()
    }

    // MARK: - migrateSelectedLanguage
    func test_migrateSelectedLanguage_whenLegacyKeyIsSet_movesValueAndRemovesLegacyKey() {
        let subject = createSubject()
        prefs.setString(itTestLanguage, forKey: PrefsKeys.Summarizer.legacySelectedLanguage)

        subject.migrateSelectedLanguage()

        XCTAssertEqual(prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage), itTestLanguage)
        XCTAssertNil(prefs.stringForKey(PrefsKeys.Summarizer.legacySelectedLanguage))
    }

    func test_migrateSelectedLanguage_whenLegacyKeyIsMissing_writesNothing() {
        let subject = createSubject()

        subject.migrateSelectedLanguage()

        XCTAssertNil(prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage))
        XCTAssertNil(prefs.stringForKey(PrefsKeys.Summarizer.legacySelectedLanguage))
    }

    func test_migrateSelectedLanguage_whenRunTwice_keepsMigratedValue() {
        let subject = createSubject()
        prefs.setString(itTestLanguage, forKey: PrefsKeys.Summarizer.legacySelectedLanguage)

        subject.migrateSelectedLanguage()
        subject.migrateSelectedLanguage()

        XCTAssertEqual(prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage), itTestLanguage)
        XCTAssertNil(prefs.stringForKey(PrefsKeys.Summarizer.legacySelectedLanguage))
    }

    func test_migrateSelectedLanguage_whenNamespacedKeyIsAlreadySet_doesNotOverwriteIt() {
        let subject = createSubject()
        prefs.setString(itTestLanguage, forKey: PrefsKeys.Summarizer.legacySelectedLanguage)
        prefs.setString(deTestLanguage, forKey: PrefsKeys.Summarizer.selectedLanguage)

        subject.migrateSelectedLanguage()

        XCTAssertEqual(prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage), deTestLanguage)
        XCTAssertNil(prefs.stringForKey(PrefsKeys.Summarizer.legacySelectedLanguage))
    }

    // MARK: - Helpers
    private func createSubject() -> SummarizerPrefsMigration {
        return SummarizerPrefsMigration(prefs: prefs)
    }
}
