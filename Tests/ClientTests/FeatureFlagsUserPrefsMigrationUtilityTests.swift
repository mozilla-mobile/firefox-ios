// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class FeatureFlagsUserPrefsMigrationUtilityTests: XCTestCase {

    // MARK: - Properties
    typealias legacyFlags = PrefsKeys.LegacyFeatureFlags
    typealias newFlags = PrefsKeys.FeatureFlags

    private let userPrefsSuffix = "UserPreferences"
    private let keyDictionary = [
        legacyFlags.ASPocketStories: newFlags.ASPocketStories,
        legacyFlags.CustomWallpaper: newFlags.CustomWallpaper,
        legacyFlags.HistoryHighlightsSection: newFlags.HistoryHighlightsSection,
        legacyFlags.HistoryGroups: newFlags.HistoryGroups,
        legacyFlags.InactiveTabs: newFlags.InactiveTabs,
        legacyFlags.JumpBackInSection: newFlags.JumpBackInSection,
        legacyFlags.PullToRefresh: newFlags.PullToRefresh,
        legacyFlags.RecentlySavedSection: newFlags.RecentlySavedSection,
        legacyFlags.SponsoredShortcuts: newFlags.SponsoredShortcuts,
        legacyFlags.StartAtHome: newFlags.StartAtHome,
        legacyFlags.TabTrayGroups: newFlags.TabTrayGroups,
        legacyFlags.TopSiteSection: newFlags.TopSiteSection]

    private var profile: MockProfile!

    // MARK: - Set-up and tear down
    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "migrationUtility_tests")
        profile._reopen()
        verifyNilStateForKeys()
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
    }

    // MARK: - Tests

    func testVerifyEmptyProfiles() {
        verifyNilStateForKeys()
    }

    func testSetAllKeysToTrue() {
        keyDictionary.forEach { oldKey, _ in
            let oldKey = oldKey + userPrefsSuffix
            profile.prefs.setString(UserFeaturePreference.enabled.rawValue, forKey: oldKey)
        }

        keyDictionary.forEach { oldKey, newKey in
            let oldKey = oldKey + userPrefsSuffix
            let newKey = newKey
            guard let string = profile.prefs.stringForKey(oldKey) else {
                XCTFail("There is no string saved for \(oldKey)")
                return
            }

            XCTAssertEqual(string, UserFeaturePreference.enabled.rawValue)
            XCTAssertNil(profile.prefs.boolForKey(newKey))
        }
    }

    func testMigrateSearchBarPreferences() {

        let position = SearchBarPosition.bottom.rawValue
        // Save position to the old key
        profile.prefs.setString(position,
                                forKey: PrefsKeys.LegacyFeatureFlags.KeySearchBarPosition)

        FeatureFlagUserPrefsMigrationUtility(with: profile).attemptMigration()

        guard let prefsSetting = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition) else {
            XCTFail("There is no string saved for previous Search Bar Position")
            return
        }

        // Ensure migration was successful
        XCTAssertEqual(prefsSetting, position)
    }

    func testSettingKeysToAVarietyOfSettings() {
        let randomSettingOptions = [true, false, nil]

        keyDictionary.forEach { oldKey, newKey in
            let oldKey = oldKey + userPrefsSuffix
            let newKey = newKey

            let randomSetting = randomSettingOptions.randomElement()

            if let temp = randomSetting, let currentSetting = temp {

                if currentSetting {
                    profile.prefs.setString(UserFeaturePreference.enabled.rawValue, forKey: oldKey)
                } else {
                    profile.prefs.setString(UserFeaturePreference.disabled.rawValue, forKey: oldKey)
                }

                guard let string = profile.prefs.stringForKey(oldKey) else {
                    XCTFail("There is no string saved for \(oldKey)")
                    return
                }

                if currentSetting {
                    XCTAssertEqual(string, UserFeaturePreference.enabled.rawValue)
                } else {
                    XCTAssertEqual(string, UserFeaturePreference.disabled.rawValue)
                }
                XCTAssertNil(profile.prefs.boolForKey(newKey))

            } else {
                XCTAssertNil(profile.prefs.boolForKey(oldKey))
                XCTAssertNil(profile.prefs.boolForKey(newKey))
            }
        }
    }

    func testMigrationOfOneSetting() {
        XCTAssertNil(profile.prefs.boolForKey(legacyFlags.MigrationCheck))

        let oldKey = legacyFlags.ASPocketStories + userPrefsSuffix
        let newKey = newFlags.ASPocketStories

        profile.prefs.setString(UserFeaturePreference.disabled.rawValue, forKey: oldKey)

        FeatureFlagUserPrefsMigrationUtility(with: profile).attemptMigration()

        guard let settingAsString = profile.prefs.stringForKey(oldKey),
              let settingAsBool = profile.prefs.boolForKey(newKey),
              let migrationCheckFlag = profile.prefs.boolForKey(legacyFlags.MigrationCheck)
        else {
            XCTFail("Something went wrong finding a value after migration.")
            return
        }

        XCTAssertEqual(settingAsString, UserFeaturePreference.disabled.rawValue)
        XCTAssertFalse(settingAsBool)
        XCTAssertTrue(migrationCheckFlag)
    }

    func testMigrationOfMultipleSettings() {
        XCTAssertNil(profile.prefs.boolForKey(legacyFlags.MigrationCheck))

        // User sets some preferences
        profile.prefs.setString(UserFeaturePreference.disabled.rawValue,
                                forKey: legacyFlags.ASPocketStories + userPrefsSuffix)
        profile.prefs.setString(UserFeaturePreference.disabled.rawValue,
                                forKey: legacyFlags.RecentlySavedSection + userPrefsSuffix)
        profile.prefs.setString(UserFeaturePreference.disabled.rawValue,
                                forKey: legacyFlags.CustomWallpaper + userPrefsSuffix)

        profile.prefs.setString(UserFeaturePreference.enabled.rawValue,
                                forKey: legacyFlags.ASPocketStories + userPrefsSuffix)
        profile.prefs.setString(UserFeaturePreference.enabled.rawValue,
                                forKey: legacyFlags.HistoryHighlightsSection + userPrefsSuffix)
        profile.prefs.setString(UserFeaturePreference.enabled.rawValue,
                                forKey: legacyFlags.TopSiteSection + userPrefsSuffix)

        profile.prefs.setString(StartAtHomeSetting.always.rawValue,
                                forKey: legacyFlags.StartAtHome + userPrefsSuffix)

        // Migrate
        FeatureFlagUserPrefsMigrationUtility(with: profile).attemptMigration()

        // Verify that the expected settings have the expected settings.
        guard let pocketSetting = profile.prefs.boolForKey(newFlags.ASPocketStories),
              let recentlySavedSetting = profile.prefs.boolForKey(newFlags.RecentlySavedSection),
              let customWallpaperSetting = profile.prefs.boolForKey(newFlags.CustomWallpaper),
              let historyHighlightsSetting = profile.prefs.boolForKey(newFlags.HistoryHighlightsSection),
              let topSiteSetting = profile.prefs.boolForKey(newFlags.TopSiteSection),
              let startAtHomeSetting = profile.prefs.stringForKey(newFlags.StartAtHome),
              let migrationCheckFlag = profile.prefs.boolForKey(legacyFlags.MigrationCheck)
        else {
            XCTFail("Something went wrong finding a value after migration.")
            return
        }

        XCTAssertEqual(startAtHomeSetting, StartAtHomeSetting.always.rawValue)
        XCTAssertFalse(recentlySavedSetting)
        XCTAssertFalse(customWallpaperSetting)
        XCTAssertTrue(historyHighlightsSetting)
        XCTAssertTrue(topSiteSetting)
        XCTAssertTrue(pocketSetting)
        XCTAssertNil(profile.prefs.boolForKey(newFlags.SponsoredShortcuts))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.PullToRefresh))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.JumpBackInSection))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.InactiveTabs))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.SponsoredShortcuts))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.TabTrayGroups))
        XCTAssertNil(profile.prefs.boolForKey(newFlags.HistoryGroups))
        XCTAssertTrue(migrationCheckFlag)
    }

    // MARK: - Helper methods
    private func verifyNilStateForKeys(file: StaticString = #filePath, line: UInt = #line) {
        keyDictionary.forEach { oldKey, newKey in
            let oldKey = oldKey + "UserPreferences"
            let newKey = newKey
            XCTAssertNil(profile.prefs.stringForKey(oldKey), "Failing in \(file) on line \(line)")
            XCTAssertNil(profile.prefs.boolForKey(newKey), "Failing in \(file) on line \(line)")
        }
    }
}
