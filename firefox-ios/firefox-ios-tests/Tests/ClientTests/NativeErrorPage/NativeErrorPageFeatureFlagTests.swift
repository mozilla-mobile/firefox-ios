// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class NativeErrorPageFeatureFlagTests: XCTestCase {
    var subject: NativeErrorPageFeatureFlag!

    override func setUp() {
        super.setUp()
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        subject = NativeErrorPageFeatureFlag()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    func testFeatureFlag_WhenNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true)
        XCTAssertTrue(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: false,
                                          noInternetConnectionErrorIsEnabled: false)
        XCTAssertFalse(subject.isNativeErrorPageEnabled)
    }

    // Helper
    private func setupNimbusNativeErrorPageTesting(isEnabled: Bool,
                                                   noInternetConnectionErrorIsEnabled: Bool) {
        FxNimbus.shared.features.nativeErrorPageFeature.with { _, _ in
                return NativeErrorPageFeature(enabled: isEnabled,
                                              noInternetConnectionError: noInternetConnectionErrorIsEnabled)
        }
    }
}
