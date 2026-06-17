// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class QuickAnswersSettingsViewControllerTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        profile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Init
    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title, "Quick Answers")
    }

    // MARK: - generateSettings
    func test_generateSettings_returnsOneSection() {
        let subject = createSubject()
        let sections = subject.generateSettings()
        XCTAssertEqual(sections.count, 1)
    }

    func test_generateSettings_sectionHasOneSetting() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        XCTAssertEqual(section.children.count, 1)
    }

    func test_generateSettings_settingIsBoolSetting() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        XCTAssertTrue(section.children.first is BoolSetting)
    }

    func test_generateSettings_boolSettingUsesQuickAnswersFeaturePrefKey() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        let boolSetting = try XCTUnwrap(section.children.first as? BoolSetting)
        XCTAssertEqual(boolSetting.prefKey, PrefsKeys.Settings.quickAnswersFeature)
    }

    func test_generateSettings_boolSettingDefaultValueIsTrue() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        let boolSetting = try XCTUnwrap(section.children.first as? BoolSetting)
        XCTAssertTrue(try XCTUnwrap(boolSetting.getDefaultValue()))
    }

    func test_generateSettings_sectionHasNoTitle() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        XCTAssertNil(section.title)
    }

    func test_generateSettings_sectionHasNoFooter() throws {
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        XCTAssertNil(section.footerTitle)
    }

    // MARK: - Preference Integration
    func test_boolSetting_readsPreferenceValue_whenEnabled() throws {
        profile.prefs.setBool(true, forKey: PrefsKeys.Settings.quickAnswersFeature)
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        let boolSetting = try XCTUnwrap(section.children.first as? BoolSetting)

        let displayValue = profile.prefs.boolForKey(boolSetting.prefKey ?? "") ?? false
        XCTAssertTrue(displayValue)
    }

    func test_boolSetting_readsPreferenceValue_whenDisabled() throws {
        profile.prefs.setBool(false, forKey: PrefsKeys.Settings.quickAnswersFeature)
        let subject = createSubject()
        let section = try XCTUnwrap(subject.generateSettings().first)
        let boolSetting = try XCTUnwrap(section.children.first as? BoolSetting)

        let displayValue = profile.prefs.boolForKey(boolSetting.prefKey ?? "")
        XCTAssertEqual(displayValue, false)
    }

    // MARK: - Helpers
    private func createSubject() -> QuickAnswersSettingsViewController {
        let subject = QuickAnswersSettingsViewController(
            prefs: profile.prefs,
            windowUUID: .XCTestDefaultUUID
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
