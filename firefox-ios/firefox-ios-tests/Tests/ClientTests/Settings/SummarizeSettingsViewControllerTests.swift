// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Shared
import XCTest

@testable import Client

@MainActor
final class SummarizeSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        gleanWrapper = nil
        try await super.tearDown()
    }

    func test_generateSettings_withShakeFeature_hasExpectedSections() {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = true
        mockSummarizeNimbusUtils.isLanguageExpansionEnabled = false

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(mockSummarizeNimbusUtils.isShakeGestureFeatureFlagEnabledCallCount, 1)
        XCTAssertEqual(sections.count, 2)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertEqual(sections.last?.title?.string, "Gestures")
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    func test_generateSettings_withoutShakeFeature_hasExpectedSections() {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = false
        mockSummarizeNimbusUtils.isLanguageExpansionEnabled = false

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(mockSummarizeNimbusUtils.isShakeGestureFeatureFlagEnabledCallCount, 1)
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertNil(sections.last?.title?.string)
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    func test_generateSettings_withLanguageExpansion_hasExpectedSections() {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = false
        mockSummarizeNimbusUtils.isLanguageExpansionEnabled = true

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(sections.count, 2)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertEqual(sections.last?.title?.string, "Language")
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    func test_generateSettings_withBothShakeAndLanguageExpansion_hasExpectedSections() {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = true
        mockSummarizeNimbusUtils.isLanguageExpansionEnabled = true

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(sections.count, 3)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertEqual(sections[1].title?.string, "Gestures")
        XCTAssertEqual(sections[1].children.count, 1)
        XCTAssertEqual(sections.last?.title?.string, "Language")
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    @available(iOS 17.4, *)
    func test_languageSection_whenOptionSelected_recordsTelemetry() throws {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = false
        mockSummarizeNimbusUtils.isLanguageExpansionEnabled = true
        mockSummarizeNimbusUtils.languageExpansionConfiguration = SummarizerLanguageExpansionConfiguration(
            supportedLocales: [Locale(identifier: "de")]
        )

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let languageSetting = try XCTUnwrap(subject.generateSettings().last?.children.first)
        let cell = UITableViewCell()
        languageSetting.onConfigureCell(cell, theme: LightTheme())

        let pickerButton = try XCTUnwrap(cell.accessoryView as? UIButton)
        let customLocaleAction = try XCTUnwrap(pickerButton.menu?.children.last as? UIAction)
        customLocaleAction.performWithSender(nil, target: nil)

        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras.first as? GleanMetrics.AiSummarize.LanguageSettingChangedExtra
        )
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.language, "de")
        XCTAssertEqual(profile.prefs.stringForKey(PrefsKeys.Summarizer.selectedLanguage), "de")
    }

    // MARK: - Helper
    private func createSubject(with summarizeNimbusUtils: MockSummarizerNimbusUtils) -> SummarizeSettingsViewController {
        let subject = SummarizeSettingsViewController(
            prefs: profile.prefs,
            summarizeNimbusUtils: summarizeNimbusUtils,
            telemetry: SummarizerTelemetry(gleanWrapper: gleanWrapper),
            windowUUID: .XCTestDefaultUUID
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
