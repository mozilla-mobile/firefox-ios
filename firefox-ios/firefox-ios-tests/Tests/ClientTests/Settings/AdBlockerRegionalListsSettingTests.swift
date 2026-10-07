// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

@MainActor
final class AdBlockerRegionalListsSettingTests: XCTestCase {
    private var mockDelegate: MockRegionalBrowsingSettingsDelegate!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockDelegate = MockRegionalBrowsingSettingsDelegate()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        mockDelegate = nil
        profile = nil
        try await super.tearDown()
    }

    func testTitle_matchesRegionalListsString() {
        let subject = createSubject()

        XCTAssertEqual(subject.title?.string, String.Settings.Browsing.RegionalLists.Title)
    }

    func testAccessibilityIdentifier_isCorrect() {
        let subject = createSubject()

        XCTAssertEqual(
            subject.accessibilityIdentifier,
            AccessibilityIdentifiers.Settings.Browsing.AdBlockerRegionalLists.settingRow
        )
    }

    func testStatus_showsZeroWhenNoneEnabled() {
        let subject = createSubject()

        XCTAssertEqual(subject.status?.string, "0")
    }

    func testStatus_showsCountOfEnabled() {
        profile.prefs.setObject(
            ["ad-block-regional-de", "ad-block-regional-fr"],
            forKey: PrefsKeys.EnabledRegionalAdBlockLists
        )
        let subject = createSubject()

        XCTAssertEqual(subject.status?.string, "2")
    }

    func testOnClick_callsDelegate() {
        let subject = createSubject()

        subject.onClick(nil)

        XCTAssertTrue(mockDelegate.pressedRegionalAdBlockListsCalled)
    }

    func testStyle_isValue1() {
        let subject = createSubject()

        XCTAssertEqual(subject.style, .value1)
    }

    // MARK: - Helpers

    private func createSubject() -> AdBlockerRegionalListsSetting {
        let theme = LightTheme()
        let subject = AdBlockerRegionalListsSetting(
            theme: theme,
            prefs: profile.prefs,
            settingsDelegate: mockDelegate
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockRegionalBrowsingSettingsDelegate: BrowsingSettingsDelegate {
    var pressedRegionalAdBlockListsCalled = false

    func pressedMailApp() {}
    func pressedAutoPlay() {}
    func pressedAdBlockerExceptions() {}

    func pressedRegionalAdBlockLists() {
        pressedRegionalAdBlockListsCalled = true
    }
}
