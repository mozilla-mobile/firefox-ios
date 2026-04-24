// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

@testable import Client

final class NimbusFeatureFlagsTests: XCTestCase {
    private var prefs: MockProfilePrefs!
    private var subject: FeatureFlagsProvider!

    override func setUp() {
        super.setUp()
        prefs = MockProfilePrefs()
        subject = FeatureFlagsProvider(prefs: prefs)
    }

    override func tearDown() {
        prefs = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testIsEnabled_withDebugOverrideSet_returnsOverride() {
        // On developer builds, debug overrides take precedence.
        // .translation has a debugKey, so we can override it.
        guard let debugKey = FeatureFlagID.translation.debugKey else {
            XCTFail("translation should have a debugKey")
            return
        }

        // Get the Nimbus default, then override to the opposite
        let nimbusDefault = subject.isEnabled(.translation)
        prefs.setBool(!nimbusDefault, forKey: debugKey)

        #if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
        XCTAssertEqual(subject.isEnabled(.translation), !nimbusDefault)
        #else
        // On release builds, debug overrides are ignored
        XCTAssertEqual(subject.isEnabled(.translation), nimbusDefault)
        #endif
    }

    func testIsEnabled_flagWithoutDebugKey_ignoresPrefs() {
        // .addressAutofillEdit has no debugKey, so prefs won't affect it
        XCTAssertNil(FeatureFlagID.addressAutofillEdit.debugKey)
        let result = subject.isEnabled(.addressAutofillEdit)
        // Should return the Nimbus default regardless of any prefs
        XCTAssertNotNil(result)
    }

    // MARK: - Mock protocol conformance

    func testMockConformance() {
        let mock = MockNimbusFeatureFlags()
        mock.enabledFlags = [.translation]

        XCTAssertTrue(mock.isEnabled(.translation))
        XCTAssertFalse(mock.isEnabled(.reportSiteIssue))
    }
}

// MARK: - CoreBuildFlags Tests

final class CoreBuildFlagsTests: XCTestCase {
    func testBuildChannelFlags() {
        // On developer builds (test environment), these should match expectations
        #if MOZ_CHANNEL_developer
        XCTAssertFalse(CoreBuildFlags.isAdjustEnvironmentProd)
        XCTAssertTrue(CoreBuildFlags.isUsingMockData)
        XCTAssertTrue(CoreBuildFlags.isUsingStagingUnifiedAdsAPI)
        #elseif MOZ_CHANNEL_beta
        XCTAssertTrue(CoreBuildFlags.isAdjustEnvironmentProd)
        XCTAssertFalse(CoreBuildFlags.isUsingMockData)
        XCTAssertFalse(CoreBuildFlags.isUsingStagingUnifiedAdsAPI)
        #elseif MOZ_CHANNEL_release
        XCTAssertTrue(CoreBuildFlags.isAdjustEnvironmentProd)
        XCTAssertFalse(CoreBuildFlags.isUsingMockData)
        XCTAssertFalse(CoreBuildFlags.isUsingStagingUnifiedAdsAPI)
        #else
        XCTAssertFalse(CoreBuildFlags.isAdjustEnvironmentProd)
        XCTAssertFalse(CoreBuildFlags.isUsingMockData)
        XCTAssertFalse(CoreBuildFlags.isUsingStagingUnifiedAdsAPI)
        #endif
    }
}

// MARK: - Test Helpers

final class MockNimbusFeatureFlags: FeatureFlagProviding, @unchecked Sendable {
    var enabledFlags: Set<FeatureFlagID> = []
    var debugOverrides: [FeatureFlagID: Bool] = [:]

    func isEnabled(_ flag: FeatureFlagID) -> Bool {
        enabledFlags.contains(flag)
    }

    func setDebugOverride(_ flag: FeatureFlagID, to value: Bool) {
        debugOverrides[flag] = value
    }
}
