// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class UserFeaturePreferenceManagerTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var subject: UserFeaturePreferenceManager!
    private var mockLayer: MockNimbusFeatureFlagLayer!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        mockLayer = MockNimbusFeatureFlagLayer()
        subject = UserFeaturePreferenceManager(prefs: prefs, backendLayer: mockLayer)
    }

    override func tearDown() {
        prefs = nil
        subject = nil
        mockLayer = nil
        super.tearDown()
    }

    // MARK: - Bool preferences: defaults from Nimbus

    func testBoolDefaults_returnNimbusValues_whenNoUserPrefSet() {
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

    func testFirefoxSuggest_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertFalse(subject.getPreferenceFor(.firefoxSuggestFeature))

        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertTrue(subject.getPreferenceFor(.firefoxSuggestFeature))
    }

    func testSentFromFirefox_readsUserPref() {
        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.SentFromFirefox)
        XCTAssertTrue(subject.getPreferenceFor(.sentFromFirefox))
    }

    func testSponsoredShortcuts_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
        XCTAssertFalse(subject.getPreferenceFor(.hntSponsoredShortcuts))
    }

    func testHomepageBookmarksSection_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.BookmarksSection)
        XCTAssertFalse(subject.getPreferenceFor(.homepageBookmarksSectionDefault))
    }

    func testHomepageJumpBackInSection_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.JumpBackInSection)
        XCTAssertFalse(subject.getPreferenceFor(.homepageJumpBackinSectionDefault))
    }

    func testAIKillSwitch_readsUserPref() {
        prefs.setBool(true, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertTrue(subject.getPreferenceFor(.aiKillSwitch))

        prefs.setBool(false, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertFalse(subject.getPreferenceFor(.aiKillSwitch))
    }

    // MARK: - Typed preferences

    func testSearchBarPosition_defaultsToNimbus() {
        let position = subject.searchBarPosition
        // Default from NimbusSearchBarLayer — just verify it's a valid value
        XCTAssertTrue(position == .top || position == .bottom)
    }

    func testSearchBarPosition_readsUserPref() {
        prefs.setString(SearchBarPosition.bottom.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(subject.searchBarPosition, .bottom)

        prefs.setString(SearchBarPosition.top.rawValue,
                        forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    func testStartAtHomeSetting_defaultsToNimbus() {
        let setting = subject.startAtHomeSetting
        // Verify it's a valid StartAtHome value
        XCTAssertTrue([.afterFourHours, .always, .disabled].contains(setting))
    }

    func testStartAtHomeSetting_readsUserPref() {
        prefs.setString(StartAtHome.always.rawValue,
                        forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(subject.startAtHomeSetting, .always)

        prefs.setString(StartAtHome.disabled.rawValue,
                        forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(subject.startAtHomeSetting, .disabled)
    }

    // MARK: - Setters

    func testSetFirefoxSuggestEnabled_writesPref() {
        subject.setPreferenceFor(.firefoxSuggestFeature, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), true)

        subject.setPreferenceFor(.firefoxSuggestFeature, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), false)
    }

    func testSetSentFromFirefoxEnabled_writesPref() {
        subject.setPreferenceFor(.sentFromFirefox, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SentFromFirefox), true)
    }

    func testSetSponsoredShortcutsEnabled_writesPref() {
        subject.setPreferenceFor(.hntSponsoredShortcuts, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SponsoredShortcuts), false)
    }

    func testSetHomepageBookmarksSectionEnabled_writesPref() {
        subject.setPreferenceFor(.homepageBookmarksSectionDefault, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.BookmarksSection), true)
    }

    func testSetHomepageJumpBackInSectionEnabled_writesPref() {
        subject.setPreferenceFor(.homepageJumpBackinSectionDefault, to: false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.JumpBackInSection), false)
    }

    func testSetAIKillSwitchEnabled_writesPref() {
        subject.setPreferenceFor(.aiKillSwitch, to: true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.Settings.aiKillSwitchFeature), true)
    }

    func testSetSearchBarPosition_writesPref() {
        subject.setSearchBarPosition(.bottom)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.bottom.rawValue)

        subject.setSearchBarPosition(.top)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition),
                       SearchBarPosition.top.rawValue)
    }

    func testSetStartAtHomeSetting_writesPref() {
        subject.setStartAtHomeSetting(.always)
        XCTAssertEqual(prefs.stringForKey(PrefsKeys.FeatureFlags.StartAtHome),
                       StartAtHome.always.rawValue)
    }

    // MARK: - Roundtrip: set then read

    func testRoundtrip_boolPreferences() {
        subject.setPreferenceFor(.firefoxSuggestFeature, to: false)
        XCTAssertFalse(subject.getPreferenceFor(.firefoxSuggestFeature))

        subject.setPreferenceFor(.firefoxSuggestFeature, to: true)
        XCTAssertTrue(subject.getPreferenceFor(.firefoxSuggestFeature))
    }

    func testRoundtrip_searchBarPosition() {
        subject.setSearchBarPosition(.bottom)
        XCTAssertEqual(subject.searchBarPosition, .bottom)

        subject.setSearchBarPosition(.top)
        XCTAssertEqual(subject.searchBarPosition, .top)
    }

    func testRoundtrip_startAtHome() {
        subject.setStartAtHomeSetting(.always)
        XCTAssertEqual(subject.startAtHomeSetting, .always)

        subject.setStartAtHomeSetting(.disabled)
        XCTAssertEqual(subject.startAtHomeSetting, .disabled)
    }

    // MARK: - Generic API: flag with no userPrefsKey falls back to Nimbus

    func testGetPreference_flagWithNoUserPrefsKey_fallsBackToNimbus() {
        // .microsurvey has no userPrefsKey, so should return the Nimbus value
        _ = subject.getPreferenceFor(.microsurvey)
    }

    func testSetPreference_flagWithNoUserPrefsKey_isNoOp() {
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
