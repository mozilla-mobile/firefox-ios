// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

class ProfilePrefsReaderTests: XCTestCase {
    private var mockUserDefaults: MockUserDefaults!
    private var prefsReader: ProfilePrefsReader!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        prefsReader = ProfilePrefsReader(userDefaults: mockUserDefaults)
    }

    override func tearDown() {
        super.tearDown()
        mockUserDefaults = nil
        prefsReader = nil
    }

    func testIsBottomToolbarUser_returnsTrue_whenPositionIsBottom() {
        let key = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SearchBarPosition
        mockUserDefaults.set("bottom", forKey: key)

        XCTAssertTrue(prefsReader.isBottomToolbarUser())
    }

    func testIsBottomToolbarUser_returnsFalse_whenPositionIsTop() {
        let key = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SearchBarPosition
        mockUserDefaults.set("top", forKey: key)

        XCTAssertFalse(prefsReader.isBottomToolbarUser())
    }

    func testIsBottomToolbarUser_returnsFalse_whenNoValueIsSet() {
        XCTAssertFalse(prefsReader.isBottomToolbarUser())
    }

    func testIsBottomToolbarUser_savesIntoProfile_thenRetrievesThePrefs() {
        let profile = BrowserProfile(localName: "profile").makePrefs()
        profile.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        let prefs = ProfilePrefsReader()
        XCTAssertTrue(prefs.isBottomToolbarUser())
    }

    func testHasEnabledTipsNotifications_returnsTrue_whenFlagIsTrue() {
        let key = ProfilePrefsReader.prefix + PrefsKeys.Notifications.TipsAndFeaturesNotifications
        mockUserDefaults.set(true, forKey: key)

        XCTAssertTrue(prefsReader.hasEnabledTipsNotifications())
    }

    func testHasEnabledTipsNotifications_returnsFalse_whenFlagIsFalse() {
        let key = ProfilePrefsReader.prefix + PrefsKeys.Notifications.TipsAndFeaturesNotifications
        mockUserDefaults.set(false, forKey: key)

        XCTAssertFalse(prefsReader.hasEnabledTipsNotifications())
    }

    func testHasEnabledTipsNotifications_returnsFalse_whenNoFlagIsSet() {
        XCTAssertFalse(prefsReader.hasEnabledTipsNotifications())
    }

    func testHasEnabledTipsNotifications_savesIntoProfile_thenRetrievesThePrefs() {
        let profile = BrowserProfile(localName: "profile").makePrefs()
        profile.setBool(true, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)

        let prefs = ProfilePrefsReader()
        XCTAssertTrue(prefs.hasEnabledTipsNotifications())
    }
}
