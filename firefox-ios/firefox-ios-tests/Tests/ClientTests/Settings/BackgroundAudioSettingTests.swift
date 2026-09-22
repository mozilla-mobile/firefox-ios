// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class BackgroundAudioSettingTests: XCTestCase {
    private var prefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        prefs = MockProfilePrefs()
    }

    override func tearDown() async throws {
        prefs = nil
        try await super.tearDown()
    }

    func testTitle_matchesBackgroundAudioString() {
        let subject = createSubject()

        XCTAssertEqual(subject.title?.string, String.Settings.Browsing.BackgroundAudio)
    }

    func testAccessibilityIdentifier_isCorrect() {
        let subject = createSubject()

        XCTAssertEqual(subject.accessibilityIdentifier, AccessibilityIdentifiers.Settings.Browsing.backgroundAudio)
    }

    func testDefaultValue_isFalse() {
        let subject = createSubject()

        XCTAssertEqual(subject.prefKey, PrefsKeys.BackgroundAudio)
        XCTAssertNil(prefs.boolForKey(PrefsKeys.BackgroundAudio))
    }

    private func createSubject() -> BackgroundAudioSetting {
        let subject = BackgroundAudioSetting(prefs: prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
