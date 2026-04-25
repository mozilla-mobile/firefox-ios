// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class NativeErrorPageFeatureFlagTests: XCTestCase {
    var subject: NativeErrorPageFeatureFlag!

    override func setUp() async throws {
        try await super.setUp()
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        subject = NativeErrorPageFeatureFlag()
    }

    override func tearDown() async throws {
        subject = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testFeatureFlag_WhenNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          badCertDomainErrorPageIsEnabled: false)
        XCTAssertTrue(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: false,
                                          noInternetConnectionErrorIsEnabled: false,
                                          badCertDomainErrorPageIsEnabled: false)
        XCTAssertFalse(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenBadCertDomainErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          badCertDomainErrorPageIsEnabled: true)
        XCTAssertTrue(subject.isBadCertDomainErrorPageEnabled)
    }

    func testFeatureFlag_WhenBadCertDomainErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true,
                                          noInternetConnectionErrorIsEnabled: true,
                                          badCertDomainErrorPageIsEnabled: false)
        XCTAssertFalse(subject.isBadCertDomainErrorPageEnabled)
    }

    // Helper
    private func setupNimbusNativeErrorPageTesting(isEnabled: Bool,
                                                   noInternetConnectionErrorIsEnabled: Bool,
                                                   badCertDomainErrorPageIsEnabled: Bool = false) {
        FxNimbus.shared.features.nativeErrorPageFeature.with { _, _ in
                return NativeErrorPageFeature(badCertDomainErrorPage: badCertDomainErrorPageIsEnabled,
                                              enabled: isEnabled,
                                              noInternetConnectionError: noInternetConnectionErrorIsEnabled)
        }
    }
}
