// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class FeatureFlagsUserPrefsMigrationUtilityTests: XCTestCase {

    typealias legacyFlags = PrefsKeys.LegacyFeatureFlags
    typealias newFlags = PrefsKeys.NewFeatureFlags

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

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "migrationUtility_tests")
        profile._reopen()
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
    }

    func testVerifyEmptyProfiles() {
    }

    private func verifyEmptyProfile() {
        keyDictionary.forEach { oldKey, newKey in
            let oldKey = oldKey + "UserPreferences"
            let newKey = newKey + "UserPreferences"
            //
        }
    }
}
