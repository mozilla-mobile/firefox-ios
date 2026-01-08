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
        subject = nil
        super.tearDown()
    }

    func testFeatureFlag_WhenNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          otherErrorPagesIsEnabled: false)
        XCTAssertTrue(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: false,
                                          noInternetConnectionErrorIsEnabled: false,
                                          otherErrorPagesIsEnabled: false)
        XCTAssertFalse(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenOtherErrorPagesEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          otherErrorPagesIsEnabled: true)
        XCTAssertTrue(subject.isOtherErrorPagesEnabled)
    }

    func testFeatureFlag_WhenOtherErrorPagesDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          otherErrorPagesIsEnabled: false)
        XCTAssertFalse(subject.isOtherErrorPagesEnabled)
    }

    // Helper
    private func setupNimbusNativeErrorPageTesting(isEnabled: Bool,
                                                   noInternetConnectionErrorIsEnabled: Bool,
                                                   otherErrorPagesIsEnabled: Bool = false) {
        FxNimbus.shared.features.nativeErrorPageFeature.with { _, _ in
                return NativeErrorPageFeature(enabled: isEnabled,
                                              noInternetConnectionError: noInternetConnectionErrorIsEnabled,
                                              otherErrorPages: otherErrorPagesIsEnabled)
        }
    }
}
