// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class AIControlsModelTests: XCTest {
    var mockPrefs: MockProfilePrefs!

    override func setUp() {
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: true
        ], prefix: "")
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    func testHeaderLinkInfo() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.headerLinkInfo.label, "")
        XCTAssertEqual(aiControlsModel.headerLinkInfo.url.absoluteString, "")
    }

    func testBlockAIEnhancementsLinkInfo() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertEqual(aiControlsModel.blockAIEnhancementsLinkInfo.label, "")
        XCTAssertEqual(aiControlsModel.blockAIEnhancementsLinkInfo.url.absoluteString, "")
    }

    func testInitialize() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.killSwitchIsOn)
        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
    }

    func testInitializeWithTranslationFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertTrue(aiControlsModel.pageSummariesVisible)
        XCTAssertFalse(aiControlsModel.translationsVisible)
    }

    func testInitializeWithPageSummariesFeatureFlagDisabled() {
        setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: false, isSummariesEnabled: true)
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        XCTAssertFalse(aiControlsModel.pageSummariesVisible)
        XCTAssertTrue(aiControlsModel.translationsVisible)
    }

    func testToggleKillSwitchOn() {
        mockPrefs = MockProfilePrefs(things: [
            PrefsKeys.Summarizer.summarizeContentFeature: true,
            PrefsKeys.Settings.translationsFeature: false,
            PrefsKeys.Settings.aiKillSwitchFeature: false
        ], prefix: "")
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: true)

        XCTAssertTrue(aiControlsModel.killSwitchToggledOn)
        XCTAssertFalse(aiControlsModel.pageSummariesEnabled)
        XCTAssertFalse(aiControlsModel.translationEnabled)
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

    func testToggleKillSwitchOff() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleKillSwitch(to: false)
        XCTAssertFalse(aiControlsModel.killSwitchIsOn)
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

    func testToggleTranslationsFeatureOn() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleTranslationsFeature(to: true)
        XCTAssertTrue(aiControlsModel.translationEnabled)
    }

    func testToggleTranslationsFeatureOff() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.toggleTranslationsFeature(to: false)
        XCTAssertFalse(aiControlsModel.translationEnabled)
    }

    func testTogglePageSummariesFeatureOn() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: true)
        XCTAssertTrue(aiControlsModel.pageSummariesEnabled)
    }

    func testTogglePageSummariesFeatureOff() {
        let aiControlsModel = AIControlsModel(prefs: mockPrefs)
        aiControlsModel.togglePageSummariesFeature(to: false)
        XCTAssertFalse(aiControlsModel.pageSummariesEnabled)
    }

    private func setupNimbusSentFromFirefoxTesting(isTranslationsEnabled: Bool, isSummariesEnabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: isTranslationsEnabled)
        }

        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isSummariesEnabled)
        }
    }
}
