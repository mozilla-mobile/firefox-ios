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
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        subject = NativeErrorPageFeatureFlag()
    }

    override func tearDown() async throws {
        subject = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testFeatureFlag_WhenNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true)

        XCTAssertTrue(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: false)

        XCTAssertFalse(subject.isNativeErrorPageEnabled)
    }

    func testFeatureFlag_WhenNICEnabledAndNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: true,
            noInternetConnectionErrorIsEnabled: true
        )

        XCTAssertTrue(subject.isNICErrorPageEnabled)
    }

    func testFeatureFlag_WhenNICEnabledAndNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: false,
            noInternetConnectionErrorIsEnabled: true
        )

        XCTAssertFalse(subject.isNICErrorPageEnabled)
    }

    func testFeatureFlag_WhenNICDisabledAndNativeErrorPageEnabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: true,
            noInternetConnectionErrorIsEnabled: false
        )

        XCTAssertFalse(subject.isNICErrorPageEnabled)
    }

    func testFeatureFlag_WhenBadCertDomainErrorPageEnabledAndNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: true,
            badCertDomainErrorPageIsEnabled: true
        )

        XCTAssertTrue(subject.isBadCertDomainErrorPageEnabled)
    }

    func testFeatureFlag_WhenBadCertDomainErrorPageEnabledAndNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: false,
            badCertDomainErrorPageIsEnabled: true
        )

        XCTAssertFalse(subject.isBadCertDomainErrorPageEnabled)
    }

    func testFeatureFlag_WhenBadCertDomainErrorPageDisabledAndNativeErrorPageEnabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(
            isEnabled: true,
            badCertDomainErrorPageIsEnabled: false
        )

        XCTAssertFalse(subject.isBadCertDomainErrorPageEnabled)
    }

    func testFeatureFlag_WhenWaybackEnabledAndNativeErrorPageEnabled_ThenFeatureIsEnabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true)
        setupNimbusWaybackTesting(isEnabled: true)

        XCTAssertTrue(subject.isWaybackEnabled)
    }

    func testFeatureFlag_WhenWaybackEnabledAndNativeErrorPageDisabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: false)
        setupNimbusWaybackTesting(isEnabled: true)

        XCTAssertFalse(subject.isWaybackEnabled)
    }

    func testFeatureFlag_WhenWaybackDisabledAndNativeErrorPageEnabled_ThenFeatureIsDisabled() {
        setupNimbusNativeErrorPageTesting(isEnabled: true)
        setupNimbusWaybackTesting(isEnabled: false)

        XCTAssertFalse(subject.isWaybackEnabled)
    }

    private func setupNimbusNativeErrorPageTesting(
        isEnabled: Bool,
        noInternetConnectionErrorIsEnabled: Bool = false,
        badCertDomainErrorPageIsEnabled: Bool = false
    ) {
        FxNimbus.shared.features.nativeErrorPageFeature.with { _, _ in
            NativeErrorPageFeature(
                badCertDomainErrorPage: badCertDomainErrorPageIsEnabled,
                enabled: isEnabled,
                noInternetConnectionError: noInternetConnectionErrorIsEnabled
            )
        }
    }

    private func setupNimbusWaybackTesting(isEnabled: Bool) {
        FxNimbus.shared.features.waybackMachineFeature.with { _, _ in
            WaybackMachineFeature(enabled: isEnabled)
        }
    }
}
