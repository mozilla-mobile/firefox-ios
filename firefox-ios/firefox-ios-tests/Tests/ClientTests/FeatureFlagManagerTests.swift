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
        UserDefaults.standard.set(false, forKey: PrefsKeys.NimbusFeatureTestsOverride)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusFeatureTestsOverride)
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
        XCTAssertFalse(featureFlags.isFeatureEnabled(.historyHighlights, checking: .buildOnly))
        XCTAssertFalse(featureFlags.isFeatureEnabled(.historyHighlights, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.inactiveTabs, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.jumpBackIn, checking: .userOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .userOnly))
    }

    func testDefaultNimbusCustomFlags() {
        XCTAssertEqual(featureFlags.getCustomState(for: .searchBarPosition), SearchBarPosition.top)
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
    }
}
