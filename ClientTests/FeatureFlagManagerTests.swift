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
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests
    func testExpectedCoreFeatures() {
        let adjustSetting = featureFlags.isCoreFeatureEnabled(.adjustEnvironmentProd)
        let mockDataSetting = featureFlags.isCoreFeatureEnabled(.useMockData)
        let contileAPISetting = featureFlags.isCoreFeatureEnabled(.useStagingContileAPI)

        #if MOZ_CHANNEL_RELEASE
            XCTAssertTrue(adjustSetting)
            XCTAssertFalse(mockDataSetting)
            XCTAssertFalse(contileAPISetting)
        #elseif MOZ_CHANNEL_BETA
            XCTAssertTrue(adjustSetting)
            XCTAssertFalse(mockDataSetting)
            XCTAssertTrue(contileAPISetting)
        #elseif MOZ_CHANNEL_FENNEC
            XCTAssertFalse(adjustSetting)
            XCTAssertTrue(mockDataSetting)
            XCTAssertTrue(contileAPISetting)
        #else
            XCTFail("We are in an unknown build type. WHat's happening!? How did we get here?!")
        #endif
    }

    func testDefaultNimbusBoolFlags() {
        // Tests for default settings should be performed on both build and user
        // prefs separately to ensure that we are getting the expected results on both.
        // Technically, at this stage, these should be the same.
        #if MOZ_CHANNEL_RELEASE
            XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.bottomSearchBar, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.historyHighlights, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.historyGroups, checking: .userOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.pocket, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.pocket, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.pullToRefresh, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.recentlySaved, checking: .userOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .userOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .buildOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .userOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .buildOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly))
            XCTAssertFalse(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.wallpapers, checking: .userOnly))

        #elseif MOZ_CHANNEL_BETA
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
            XCTAssertTrue(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly))

        #elseif MOZ_CHANNEL_FENNEC
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
            XCTAssertTrue(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.shakeToRestore, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.sponsoredTiles, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.startAtHome, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.tabTrayGroups, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .buildOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.topSites, checking: .userOnly))
            XCTAssertTrue(featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly))

        #else
            XCTFail("We are in an unknown build type. What's happening!? How did things go so wrong!!")
        #endif
    }

    func testDefaultNimbusCustomFlags() {
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
    }

    // Changing the prefs manually, to make sure settings are respected through
    // the FFMs interface
    func testFFMRespectsProfileChangesForBoolSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

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
    func testFFMRespectsProfileChangesForCustomSettings() {
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)

        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        mockProfile.prefs.setString(SearchBarPosition.top.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)

        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.afterFourHours)
        mockProfile.prefs.setString(StartAtHomeSetting.always.rawValue,
                                    forKey: PrefsKeys.FeatureFlags.StartAtHome)
        XCTAssertEqual(featureFlags.getCustomState(for: .startAtHome), StartAtHomeSetting.always)
    }

    func testFFMInterfaceForUpdatingBoolFlags() {
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        featureFlags.set(feature: .jumpBackIn, to: false)
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
    }

    func testFFMInterfaceForUpdatingCustomFlags() {
        // Search Bar
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.bottom)
        featureFlags.set(feature: .searchBarPosition, to: SearchBarPosition.top)
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)

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
