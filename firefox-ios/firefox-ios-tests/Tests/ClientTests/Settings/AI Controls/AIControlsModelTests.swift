// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class AIControlsModelTests: XCTestCase {
    var mockPrefs: MockProfilePrefs!

    override func setUp() async throws {
        try await super.setUp()
        let mockProfile = MockProfile(databasePrefix: "test")
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: true
        ], prefix: "")
        mockProfile.prefs = mockPrefs
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
    }

    @MainActor
    func testHeaderLinkInfo() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.headerLinkInfo.label, "Learn more")
        XCTAssertEqual(aiControlsModel.headerLinkInfo.url.absoluteString, "https://www.mozilla.org/en-US/privacy/firefox-privacy-policy/")
    }

    @MainActor
    func testBlockAIEnhancementsLinkInfo() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.blockAIEnhancementsLinkInfo.label, "See what is and isn’t included")
        XCTAssertEqual(aiControlsModel.blockAIEnhancementsLinkInfo.url.absoluteString, "https://www.mozilla.org/en-US/privacy/firefox-privacy-policy/")
    }

    @MainActor
    func testHasVisibleAIFeatures() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: true, isSummariesEnabled: false)
        let aiControlsModel1 = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel1.hasVisibleAIFeatures)

        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel2 = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel2.hasVisibleAIFeatures)

        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: false)
        let aiControlsModel3 = createSubject(prefs: mockPrefs)
        XCTAssertFalse(aiControlsModel3.hasVisibleAIFeatures)
    }

    @MainActor
    func testInitialize() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.killSwitchIsOn)
        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
    }

    @MainActor
    func testInitializeWithTranslationFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.pageSummariesVisible)
        XCTAssertFalse(aiControlsModel.translationsVisible)
    }

    @MainActor
    func testInitializeWithPageSummariesFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: true, isSummariesEnabled: false)
        let aiControlsModel = createSubject(prefs: mockPrefs)
        XCTAssertFalse(aiControlsModel.pageSummariesVisible)
        XCTAssertTrue(aiControlsModel.translationsVisible)
    }

    @MainActor
    func testToggleKillSwitchOn() {
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: false
        ], prefix: "")
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: true)

        XCTAssertFalse(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for ai kill switch feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    @MainActor
    func testToggleKillSwitchOff() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: false)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for ai kill switch feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }

        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertTrue(aiControlsModel.translationEnabled)
    }

    @MainActor
    func testToggleTranslationsFeatureOn() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleTranslationsFeature(to: true)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    @MainActor
    func testToggleTranslationsFeatureOff() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.toggleTranslationsFeature(to: false)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Settings.translationsFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    @MainActor
    func testTogglePageSummariesFeatureOn() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: true)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertTrue(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    @MainActor
    func testTogglePageSummariesFeatureOff() {
        let aiControlsModel = createSubject(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: false)

        if let prefVal = mockPrefs.boolForKey(PrefsKeys.Summarizer.summarizeContentFeature) {
            XCTAssertFalse(prefVal)
        } else {
            XCTFail("No pref value for translations feature")
        }
    }

    private func setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: Bool, isSummariesEnabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: isTranslationsEnabled)
        }

        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isSummariesEnabled)
        }
    }

    @MainActor
    private func createSubject(prefs: Prefs) -> AIControlsModel {
        let subject = AIControlsModel(prefs: prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
