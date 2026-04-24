// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class FeatureFlagManagerTests: XCTestCase, LegacyFeatureFlaggable {
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        let mockProfile = MockProfile(databasePrefix: "FeatureFlagsManagerTests_")
        mockProfile.prefs.clearAll()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    // MARK: - Tests
    func testExpectedCoreFeatures() {
        let adjustSetting = CoreBuildFlags.isAdjustEnvironmentProd
        let mockDataSetting = CoreBuildFlags.isUsingMockData
        let unifiedAdsAPISetting = CoreBuildFlags.isUsingStagingUnifiedAdsAPI

        XCTAssertFalse(adjustSetting)
        XCTAssertTrue(mockDataSetting)
        XCTAssertTrue(unifiedAdsAPISetting)
    }

    func testDefaultNimbusBoolFlags() {
        // Tests for default settings should be performed on both build and user
        // prefs separately to ensure that we are getting the expected results on both.
        // Technically, at this stage, these should be the same.
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly))
        XCTAssertTrue(featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .userOnly))
    }
}
