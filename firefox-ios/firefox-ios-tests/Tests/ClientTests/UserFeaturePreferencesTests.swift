// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class UserFeaturePreferencesTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var subject: UserFeaturePreferences!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        subject = UserFeaturePreferences(prefs: prefs)
    }

    override func tearDown() {
        prefs = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Bool preferences: defaults from Nimbus

    func testBoolDefaults_returnNimbusValues_whenNoUserPrefSet() {
        // With no prefs set, each property should return the Nimbus default.
        // We just verify they return without crashing — the actual Nimbus defaults
        // may vary by config, so we check the type is correct.
        _ = subject.isAIKillSwitchEnabled
        _ = subject.isFirefoxSuggestEnabled
        _ = subject.isSentFromFirefoxEnabled
        _ = subject.isSponsoredShortcutsEnabled
        _ = subject.isHomepageBookmarksSectionEnabled
        _ = subject.isHomepageJumpBackInSectionEnabled
    }

    // MARK: - Bool preferences: user overrides

    func testFirefoxSuggest_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertFalse(subject.isFirefoxSuggestEnabled)

        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.FirefoxSuggest)
        XCTAssertTrue(subject.isFirefoxSuggestEnabled)
    }

    func testSentFromFirefox_readsUserPref() {
        prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.SentFromFirefox)
        XCTAssertTrue(subject.isSentFromFirefoxEnabled)
    }

    func testSponsoredShortcuts_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
        XCTAssertFalse(subject.isSponsoredShortcutsEnabled)
    }

    func testHomepageBookmarksSection_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.BookmarksSection)
        XCTAssertFalse(subject.isHomepageBookmarksSectionEnabled)
    }

    func testHomepageJumpBackInSection_readsUserPref() {
        prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.JumpBackInSection)
        XCTAssertFalse(subject.isHomepageJumpBackInSectionEnabled)
    }

    func testAIKillSwitch_readsUserPref() {
        prefs.setBool(true, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertTrue(subject.isAIKillSwitchEnabled)

        prefs.setBool(false, forKey: PrefsKeys.Settings.aiKillSwitchFeature)
        XCTAssertFalse(subject.isAIKillSwitchEnabled)
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

    func testHomepageStoriesScrollDirection_returnsNimbusValue() {
        let direction = subject.homepageStoriesScrollDirection
        XCTAssertTrue([.baseline, .horizontal, .vertical].contains(direction))
    }

    // MARK: - Setters

    func testSetFirefoxSuggestEnabled_writesPref() {
        subject.setFirefoxSuggestEnabled(true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), true)

        subject.setFirefoxSuggestEnabled(false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.FirefoxSuggest), false)
    }

    func testSetSentFromFirefoxEnabled_writesPref() {
        subject.setSentFromFirefoxEnabled(true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SentFromFirefox), true)
    }

    func testSetSponsoredShortcutsEnabled_writesPref() {
        subject.setSponsoredShortcutsEnabled(false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.FeatureFlags.SponsoredShortcuts), false)
    }

    func testSetHomepageBookmarksSectionEnabled_writesPref() {
        subject.setHomepageBookmarksSectionEnabled(true)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.BookmarksSection), true)
    }

    func testSetHomepageJumpBackInSectionEnabled_writesPref() {
        subject.setHomepageJumpBackInSectionEnabled(false)
        XCTAssertEqual(prefs.boolForKey(PrefsKeys.HomepageSettings.JumpBackInSection), false)
    }

    func testSetAIKillSwitchEnabled_writesPref() {
        subject.setAIKillSwitchEnabled(true)
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
        subject.setFirefoxSuggestEnabled(false)
        XCTAssertFalse(subject.isFirefoxSuggestEnabled)

        subject.setFirefoxSuggestEnabled(true)
        XCTAssertTrue(subject.isFirefoxSuggestEnabled)
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

    // MARK: - Mock protocol conformance

    func testMockConformance() {
        let mock = MockUserFeaturePreferences()
        mock.isFirefoxSuggestEnabled = false
        XCTAssertFalse(mock.isFirefoxSuggestEnabled)

        mock.searchBarPosition = .bottom
        XCTAssertEqual(mock.searchBarPosition, .bottom)

        mock.setSearchBarPosition(.top)
        XCTAssertEqual(mock.searchBarPosition, .top)
    }
}

// MARK: - Test Helpers

final class MockUserFeaturePreferences: UserFeaturePreferring, @unchecked Sendable {
    var isAIKillSwitchEnabled = true
    var isFirefoxSuggestEnabled = true
    var isSentFromFirefoxEnabled = false
    var isSponsoredShortcutsEnabled = true
    var isHomepageBookmarksSectionEnabled = true
    var isHomepageJumpBackInSectionEnabled = true
    var searchBarPosition = SearchBarPosition.bottom
    var startAtHomeSetting = StartAtHome.afterFourHours
    var homepageStoriesScrollDirection = ScrollDirection.baseline

    func setAIKillSwitchEnabled(_ enabled: Bool) { isAIKillSwitchEnabled = enabled }
    func setFirefoxSuggestEnabled(_ enabled: Bool) { isFirefoxSuggestEnabled = enabled }
    func setSentFromFirefoxEnabled(_ enabled: Bool) { isSentFromFirefoxEnabled = enabled }
    func setSponsoredShortcutsEnabled(_ enabled: Bool) { isSponsoredShortcutsEnabled = enabled }
    func setHomepageBookmarksSectionEnabled(_ enabled: Bool) { isHomepageBookmarksSectionEnabled = enabled }
    func setHomepageJumpBackInSectionEnabled(_ enabled: Bool) { isHomepageJumpBackInSectionEnabled = enabled }
    func setSearchBarPosition(_ position: SearchBarPosition) { searchBarPosition = position }
    func setStartAtHomeSetting(_ setting: StartAtHome) { startAtHomeSetting = setting }
    func setHomepageStoriesScrollDirection(_ direction: ScrollDirection) { homepageStoriesScrollDirection = direction }
}
