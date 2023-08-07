// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

class FeatureFlagManagerTests: XCTestCase, FeatureFlaggable {
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testExpectedCoreFeatures() {
        let adjustSetting = featureFlags.isCoreFeatureEnabled(.adjustEnvironmentProd)
        let mockDataSetting = featureFlags.isCoreFeatureEnabled(.useMockData)
        let contileAPISetting = featureFlags.isCoreFeatureEnabled(.useStagingContileAPI)

        XCTAssertFalse(adjustSetting)
        XCTAssertTrue(mockDataSetting)
        XCTAssertTrue(contileAPISetting)
    }

    func testDefaultNimbusBoolFlags() {
        // Tests for default settings should be performed on both build and user
        // prefs separately to ensure that we are getting the expected results on both.
        // Technically, at this stage, these should be the same.
        XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pocket, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pocket, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly))
    }

    func testDefaultNimbusCustomFlags() {
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        XCTAssertEqual(featureFlags.getCustomState(for: .wallpaperVersion), WallpaperVersion.v1)
    }

    // Changing the prefs manually, to make sure settings are respected through
    // the FFMs interface
    func testManagerRespectsProfileChangesForBoolSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        // Changing the prefs manually, to make sure settings are respected through
        // the FFMs interface
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.JumpBackInSection)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
    }

    // Changing the prefs manually, to make sure settings are respected through
    // the FFMs interface
    func testManagerRespectsProfileChangesForCustomSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        // Search Bar position
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)
        mockProfile.prefs.setString(SearchBarPosition.bottom.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)

        // StartAtHome
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        mockProfile.prefs.setString(StartAtHomeSetting.always.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.always)
    }

    func testManagerInterfaceForUpdatingBoolFlags() {
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        featureFlags.set(feature: .jumpBackIn, to: false)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
    }

    func testManagerInterfaceForUpdatingCustomFlags() {
        // Search Bar
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)
        featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.bottom)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)

        // StartAtHome
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.always)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.always)
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.disabled)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.disabled)
    }

    func testStartAtHomeBoolean() {
        // Ensure defaults are operating correctly
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
        XCTAssertEqual(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly), featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        // Now simulate user toggling to different settings
        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.always)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.disabled)
        XCTAssertFalse(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))

        featureFlags.set(feature: .startAtHome, to: StartAtHomeSetting.afterFourHours)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
    }
}
