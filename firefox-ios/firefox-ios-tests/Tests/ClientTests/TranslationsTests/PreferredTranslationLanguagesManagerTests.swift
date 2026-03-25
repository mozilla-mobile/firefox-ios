// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import TestKit
import XCTest
@testable import Client

@MainActor
final class PreferredTranslationLanguagesManagerTests: XCTestCase {
    private var prefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() async throws {
        prefs = nil
        try await super.tearDown()
    }

    // MARK: - preferredLanguages

    func test_preferredLanguages_whenPrefsEmpty_savesAndReturnsDerivedLanguages() {
        let subject = createSubject()
        let supported = ["en", "fr", "de", "es"]

        let result = subject.preferredLanguages(supportedTargetLanguages: supported)

        // Result must be a subset of supported languages.
        XCTAssertTrue(
            result.allSatisfy { supported.contains($0) },
            "Expected all returned languages to be in the supported list."
        )

        // Prefs must now be populated so a second call doesn't rebuild.
        let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages)
        XCTAssertNotNil(stored, "Expected prefs to be populated after first access.")
    }

    func test_preferredLanguages_whenPrefsEmpty_noSupportedLanguages_returnsEmpty() {
        let subject = createSubject()

        let result = subject.preferredLanguages(supportedTargetLanguages: [])

        XCTAssertTrue(result.isEmpty, "Expected empty result when no languages are supported.")
    }

    func test_preferredLanguages_whenPrefsEmpty_noOverlapWithSupported_returnsEmpty() {
        let subject = createSubject()
        // Use codes that will never appear in any real iOS preferred languages list.
        let supported = ["zz", "qq"]

        let result = subject.preferredLanguages(supportedTargetLanguages: supported)

        XCTAssertTrue(result.isEmpty, "Expected empty result when device languages don't overlap with supported list.")
    }

    func test_preferredLanguages_whenPrefsAlreadyStored_returnsStoredValue() {
        let subject = createSubject()
        let stored = ["fr", "de"]
        subject.save(languages: stored)

        let result = subject.preferredLanguages(supportedTargetLanguages: ["en", "fr", "de"])

        XCTAssertEqual(result, stored, "Expected stored languages to be returned without rebuilding.")
    }

    func test_preferredLanguages_secondCall_returnsSameResultWithoutRebuild() {
        let subject = createSubject()
        let supported = ["en", "fr"]

        let first = subject.preferredLanguages(supportedTargetLanguages: supported)
        let second = subject.preferredLanguages(supportedTargetLanguages: supported)

        XCTAssertEqual(first, second, "Expected second call to return same result as first.")
    }

    // MARK: - save

    func test_save_persistsLanguagesToPrefs() {
        let subject = createSubject()
        let languages = ["en", "fr", "de"]

        subject.save(languages: languages)

        let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages)
        XCTAssertEqual(stored, "en,fr,de", "Expected prefs to contain comma-separated languages.")
    }

    func test_save_emptyList_persistsEmptyString() {
        let subject = createSubject()

        subject.save(languages: [])

        let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages)
        XCTAssertEqual(stored, "", "Expected prefs to contain an empty string for an empty list.")
    }

    func test_save_overwritesPreviousValue() {
        let subject = createSubject()
        subject.save(languages: ["en", "fr"])
        subject.save(languages: ["de"])

        let stored = prefs.stringForKey(PrefsKeys.Settings.translationPreferredLanguages)
        XCTAssertEqual(stored, "de", "Expected second save to overwrite the first.")
    }

    // MARK: - Helpers

    private func createSubject() -> PreferredTranslationLanguagesManager {
        let subject = PreferredTranslationLanguagesManager(prefs: prefs, logger: MockLogger())
        trackForMemoryLeaks(subject)
        return subject
    }
}
