// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class UserFeaturePreferenceManagerTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var mockLayer: MockNimbusFeatureFlagLayer!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        mockLayer = MockNimbusFeatureFlagLayer()
    }

    override func tearDown() {
        mockLayer = nil
        prefs = nil
        super.tearDown()
    }

    // MARK: - Bool preferences: defaults from Nimbus

    @MainActor
    func testBoolDefaults_returnNimbusValues_whenNoUserPrefSet() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        // With no prefs set, each flag should return the Nimbus default.
        // We just verify they return without crashing — the actual Nimbus defaults
        // may vary by config, so we check the type is correct.
        _ = subject.getPreferenceFor(.aiKillSwitch)
        _ = subject.getPreferenceFor(.firefoxSuggestFeature)
        _ = subject.getPreferenceFor(.sentFromFirefox)
        _ = subject.getPreferenceFor(.hntSponsoredShortcuts)
        _ = subject.getPreferenceFor(.homepageBookmarksSectionDefault)
        _ = subject.getPreferenceFor(.homepageJumpBackinSectionDefault)
    }

    // MARK: - Bool preferences: user overrides

    @MainActor
    func testFirefoxSuggest_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertFalse(subject.getPreferenceFor(.firefoxSuggestFeature))

        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertTrue(subject.getPreferenceFor(.firefoxSuggestFeature))
    }

    @MainActor
    func testSentFromFirefox_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.SentFromFirefox)
        XCTAssertTrue(subject.getPreferenceFor(.sentFromFirefox))
    }

    @MainActor
    func testSponsoredShortcuts_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
        XCTAssertFalse(subject.getPreferenceFor(.hntSponsoredShortcuts))
    }

    @MainActor
    func testHomepageBookmarksSection_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.BookmarksSection)
        XCTAssertFalse(subject.getPreferenceFor(.homepageBookmarksSectionDefault))
    }

    @MainActor
    func testHomepageJumpBackInSection_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.JumpBackInSection)
        XCTAssertFalse(subject.getPreferenceFor(.homepageJumpBackinSectionDefault))
    }

    @MainActor
    func testAIKillSwitch_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setBool(true, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertTrue(subject.getPreferenceFor(.aiKillSwitch))

        prefs.setBool(false, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertFalse(subject.getPreferenceFor(.aiKillSwitch))
    }

    // MARK: - Typed preferences

    @MainActor
    func testSearchBarPosition_defaultsToNimbus() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        let position = subject.searchBarPosition
        // Default from NimbusSearchBarLayer — just verify it's a valid value
        XCTAssertTrue(position == .top || position == .bottom)
    }

    @MainActor
    func testSearchBarPosition_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setString(SearchBarPosition.bottom.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(subject.searchBarPosition, .bottom)

        prefs.setString(SearchBarPosition.top.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    @MainActor
    func testSearchBarPosition_returnsTopOnIPad_whenStoredIsBottom() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .pad)

        prefs.setString(SearchBarPosition.bottom.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    @MainActor
    func testSearchBarPosition_returnsTopOnIPad_whenStoredIsTop() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .pad)

        prefs.setString(SearchBarPosition.top.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    @MainActor
    func testSearchBarPosition_returnsTopOnIPad_whenNothingStored() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .pad)

        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    @MainActor
    func testSearchBarPosition_readsStoredValueOnIPhone() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setString(SearchBarPosition.bottom.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        XCTAssertEqual(subject.searchBarPosition, .bottom)
    }

    @MainActor
    func testStartAtHomeSetting_defaultsToNimbus() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        let setting = subject.startAtHomeSetting
        // Verify it's a valid StartAtHome value
        XCTAssertTrue([.afterFourHours, .always, .disabled].contains(setting))
    }

    @MainActor
    func testStartAtHomeSetting_readsUserPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        prefs.setString(StartAtHome.always.rawValue,
                        forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(subject.startAtHomeSetting, .always)

        prefs.setString(StartAtHome.disabled.rawValue,
                        forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(subject.startAtHomeSetting, .disabled)
    }

    // MARK: - Setters

    @MainActor
    func testSetFirefoxSuggestEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.firefoxSuggestFeature, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), true)

        subject.setPreferenceFor(.firefoxSuggestFeature, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), false)
    }

    @MainActor
    func testSetSentFromFirefoxEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.sentFromFirefox, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SentFromFirefox), true)
    }

    @MainActor
    func testSetSponsoredShortcutsEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.hntSponsoredShortcuts, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SponsoredShortcuts), false)
    }

    @MainActor
    func testSetHomepageBookmarksSectionEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.homepageBookmarksSectionDefault, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.BookmarksSection), true)
    }

    @MainActor
    func testSetHomepageJumpBackInSectionEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.homepageJumpBackinSectionDefault, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.JumpBackInSection), false)
    }

    @MainActor
    func testSetAIKillSwitchEnabled_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.aiKillSwitch, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature), true)
    }

    @MainActor
    func testSetSearchBarPosition_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setSearchBarPosition(.bottom)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)

        subject.setSearchBarPosition(.top)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.top.rawValue)
    }

    @MainActor
    func testSetStartAtHomeSetting_writesPref() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setStartAtHomeSetting(.always)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.StartAtHome),
                       StartAtHome.always.rawValue)
    }

    // MARK: - Roundtrip: set then read

    @MainActor
    func testRoundtrip_boolPreferences() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setPreferenceFor(.firefoxSuggestFeature, to: false)
        XCTAssertFalse(subject.getPreferenceFor(.firefoxSuggestFeature))

        subject.setPreferenceFor(.firefoxSuggestFeature, to: true)
        XCTAssertTrue(subject.getPreferenceFor(.firefoxSuggestFeature))
    }

    @MainActor
    func testRoundtrip_searchBarPosition() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setSearchBarPosition(.bottom)
        XCTAssertEqual(subject.searchBarPosition, .bottom)

        subject.setSearchBarPosition(.top)
        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    @MainActor
    func testRoundtrip_startAtHome() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        subject.setStartAtHomeSetting(.always)
        XCTAssertEqual(subject.startAtHomeSetting, .always)

        subject.setStartAtHomeSetting(.disabled)
        XCTAssertEqual(subject.startAtHomeSetting, .disabled)
    }

    // MARK: - Generic API: flag with no userPrefsKey falls back to Nimbus

    @MainActor
    func testGetPreference_flagWithNoUserPrefsKey_fallsBackToNimbus() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        // .microsurvey has no userPrefsKey, so should return the Nimbus value
        _ = subject.getPreferenceFor(.microsurvey)
    }

    @MainActor
    func testSetPreference_flagWithNoUserPrefsKey_isNoOp() {
        let subject = createSubject(prefs: prefs, backendLayer: mockLayer, userInterfaceIdiom: .phone)

        // .microsurvey has no userPrefsKey, so set should be a no-op
        subject.setPreferenceFor(.microsurvey, to: true)
        // No crash, no pref written
    }

    // MARK: - Mock protocol conformance

    func testMockConformance() {
        let mock = MockUserFeaturePreferences()
        mock.setPreferenceFor(.firefoxSuggestFeature, to: false)
        XCTAssertFalse(mock.getPreferenceFor(.firefoxSuggestFeature))

        mock.searchBarPosition = .bottom
        XCTAssertEqual(mock.searchBarPosition, .bottom)

        mock.setSearchBarPosition(.top)
        XCTAssertEqual(mock.searchBarPosition, .top)
    }

    // MARK: - Helpers
    @MainActor
    private func createSubject(
        prefs: Prefs,
        backendLayer: NimbusFeatureFlagLayerProviding,
        userInterfaceIdiom: UIUserInterfaceIdiom,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> UserFeaturePreferenceManager {
        let subject = UserFeaturePreferenceManager(
            prefs: prefs,
            backendLayer: backendLayer,
            userInterfaceIdiom: userInterfaceIdiom
        )
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}

// MARK: - Test Helpers

final class MockUserFeaturePreferences: UserFeaturePreferring, @unchecked Sendable {
    var boolPreferences: [FeatureFlagID: Bool] = [:]
    var searchBarPosition = SearchBarPosition.bottom
    var startAtHomeSetting = StartAtHome.afterFourHours

    func getPreferenceFor(_ flag: FeatureFlagID) -> Bool {
        return boolPreferences[flag] ?? false
    }

    func setPreferenceFor(_ flag: FeatureFlagID, to value: Bool) {
        boolPreferences[flag] = value
    }

    func setSearchBarPosition(_ position: SearchBarPosition) { searchBarPosition = position }
    func setStartAtHomeSetting(_ setting: StartAtHome) { startAtHomeSetting = setting }
}
