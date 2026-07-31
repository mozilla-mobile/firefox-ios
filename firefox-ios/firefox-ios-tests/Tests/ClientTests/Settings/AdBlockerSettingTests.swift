// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest

@testable import Client

@MainActor
final class AdBlockerSettingTests: XCTestCase {
    private var profile: MockProfile!
    private var mockDelegate: MockSupportDelegate!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        mockDelegate = MockSupportDelegate()
    }

    override func tearDown() async throws {
        profile = nil
        mockDelegate = nil
        try await super.tearDown()
    }

    func testTitle_matchesAdBlockerString() {
        let subject = createSubject()

        XCTAssertEqual(subject.title?.string, String.Settings.Browsing.AdBlocker.Title)
    }

    func testStatus_matchesDescriptionString() {
        let subject = createSubject()

        XCTAssertEqual(subject.status?.string, String.Settings.Browsing.AdBlocker.Description)
    }

    func testAccessibilityIdentifier_isCorrect() {
        let subject = createSubject()

        XCTAssertEqual(subject.accessibilityIdentifier, AccessibilityIdentifiers.Settings.Browsing.adBlockerTitle)
    }

    func testOnConfigureCell_configuresCellWithCorrectText() {
        let subject = createSubject()
        let cell = ThemedLearnMoreTableViewCell(style: .default, reuseIdentifier: nil)
        let theme = LightTheme()

        subject.onConfigureCell(cell, theme: theme)

        XCTAssertEqual(cell.learnMoreButton.titleLabel?.text, String.Settings.Browsing.AdBlocker.LearnMore)
    }

    func testOnConfigureCell_learnMoreTap_callsDelegateWithURL() {
        let subject = createSubject()
        let cell = ThemedLearnMoreTableViewCell(style: .default, reuseIdentifier: nil)
        let theme = LightTheme()

        subject.onConfigureCell(cell, theme: theme)
        cell.learnMoreDidTap?()

        XCTAssertEqual(mockDelegate.askedToOpenCallCount, 1)
        XCTAssertEqual(
            mockDelegate.askedToOpenURL,
            SupportUtils.URLForTopic(AdBlockerSetting.learnMoreTopic)
        )
    }

    func testSettingDidChange_callsCallback() {
        var callbackValues = [Bool]()
        let subject = AdBlockerSetting(
            prefs: profile.prefs,
            supportDelegate: mockDelegate,
            settingDidChange: { callbackValues.append($0) }
        )

        subject.settingDidChange?(true)
        subject.settingDidChange?(false)

        XCTAssertEqual(callbackValues, [true, false])
    }

    // MARK: - Helpers

    private func createSubject() -> AdBlockerSetting {
        let subject = AdBlockerSetting(
            prefs: profile.prefs,
            supportDelegate: mockDelegate,
            settingDidChange: { _ in }
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockSupportDelegate: SupportSettingsDelegate {
    var askedToOpenCallCount = 0
    var askedToOpenURL: URL?

    func pressedOpenSupportPage(url: URL) {}

    func askedToOpen(url: URL?, withTitle title: NSAttributedString?) {
        askedToOpenCallCount += 1
        askedToOpenURL = url
    }
}
