// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest
@testable import Client

@MainActor
final class QuickAnswersSettingTests: XCTestCase {
    private var profile: MockProfile!
    private var delegate: MockGeneralSettingsDelegate!
    private var settings: SettingsTableViewController!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        delegate = MockGeneralSettingsDelegate()
        settings = SettingsTableViewController(
            style: .plain,
            windowUUID: .XCTestDefaultUUID,
            themeManager: MockThemeManager()
        )
        settings.profile = profile
    }

    override func tearDown() async throws {
        profile = nil
        delegate = nil
        settings = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Init

    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title?.string, "Quick Answers")
    }

    func test_init_setsAccessibilityIdentifier() {
        let subject = createSubject()
        XCTAssertEqual(subject.accessibilityIdentifier, AccessibilityIdentifiers.Settings.QuickAnswers.title)
    }

    func test_init_setsStyleToValue1() {
        let subject = createSubject()
        XCTAssertEqual(subject.style, .value1)
    }

    // MARK: - Status

    func test_status_showsOnWhenFeatureEnabled() {
        profile.prefs.setBool(true, forKey: PrefsKeys.Settings.quickAnswersFeature)
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, "On")
    }

    func test_status_showsOffWhenFeatureDisabled() {
        profile.prefs.setBool(false, forKey: PrefsKeys.Settings.quickAnswersFeature)
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, "Off")
    }

    func test_status_showsOnByDefault() {
        let subject = createSubject()
        XCTAssertEqual(subject.status?.string, "On")
    }

    // MARK: - onClick

    func test_onClick_callsDelegateMethod() {
        let subject = createSubject()
        subject.onClick(nil)
        XCTAssertTrue(delegate.pressedQuickAnswersCalled)
    }

    func test_onClick_callsDelegateMethodMultipleTimes() {
        let subject = createSubject()
        subject.onClick(nil)
        XCTAssertTrue(delegate.pressedQuickAnswersCalled)

        delegate.pressedQuickAnswersCalled = false
        subject.onClick(nil)
        XCTAssertTrue(delegate.pressedQuickAnswersCalled)
    }

    func test_onClick_withNavigationController() {
        let subject = createSubject()
        let navigationController = UINavigationController()
        subject.onClick(navigationController)
        XCTAssertTrue(delegate.pressedQuickAnswersCalled)
    }

    // MARK: - Title Attributes

    func test_title_hasCorrectTextColor() {
        let subject = createSubject()
        let titleAttributes = subject.title?.attributes(at: 0, effectiveRange: nil)
        let foregroundColor = titleAttributes?[.foregroundColor] as? UIColor
        XCTAssertNotNil(foregroundColor)
    }

    // MARK: - Status Updates

    func test_status_updatesWhenPreferenceChanges() {
        let subject = createSubject()

        profile.prefs.setBool(true, forKey: PrefsKeys.Settings.quickAnswersFeature)
        XCTAssertEqual(subject.status?.string, "On")

        profile.prefs.setBool(false, forKey: PrefsKeys.Settings.quickAnswersFeature)
        XCTAssertEqual(subject.status?.string, "Off")
    }

    // MARK: - Helpers

    private func createSubject() -> QuickAnswersSetting {
        let subject = QuickAnswersSetting(
            settings: settings,
            settingsDelegate: delegate
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
