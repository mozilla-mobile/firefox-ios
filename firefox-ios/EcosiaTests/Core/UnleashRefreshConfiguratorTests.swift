// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UnleashRefreshConfiguratorTests: XCTestCase {

    override func setUp() {
        Unleash.rules = []
    }

    override func tearDown() {
        Unleash.rules = []
    }

    func testAppUpdateRuleCheck() async {
        // Given
        let configurator = UnleashRefreshConfigurator()
        configurator.withAppUpdateCheckRule(appVersion: "1.0.0")

        // Simulate App Version update
        Unleash.model.appVersion = "1.1.0"

        // Then
        XCTAssertTrue(Unleash.shouldRefresh, "Unleash should refresh after an app update.")
    }

    func testAppUpdateRuleCheckNoVersionChange() async {
        // Given
        let configurator = UnleashRefreshConfigurator()
        configurator.withAppUpdateCheckRule(appVersion: "1.0.0")

        // Simulate no App Version update (version stays the same)
        Unleash.model.appVersion = "1.0.0"

        // Then
        XCTAssertFalse(Unleash.shouldRefresh, "Unleash should not refresh when app version has not changed.")
    }

    func testTwentyFourHourCacheExpirationRuleMoreThan24h() async {
        // Given
        let mockTimestampProvider = MockTimestampProvider(currentTimestamp: Date().addingTimeInterval(TimeInterval.twentyFourHoursTimeInterval + 1).timeIntervalSince1970)
        let timeRule = TimeBasedRefreshingRule(interval: TimeInterval.twentyFourHoursTimeInterval, timestampProvider: mockTimestampProvider)
        Unleash.addRule(timeRule)

        // When
        Unleash.model.updated = Date()

        // Then
        XCTAssertTrue(Unleash.shouldRefresh, "Unleash should refresh after 24 hours.")
    }

    func testTwentyFourHourCacheExpirationRuleLessThan24h() async {
        // Given
        let configurator = UnleashRefreshConfigurator()
        configurator.withTwentyFourHoursCacheExpirationRule()

        // When
        Unleash.model.updated = Date().addingTimeInterval(TimeInterval.twentyFourHoursTimeInterval - 1)

        // Then
        XCTAssertFalse(Unleash.shouldRefresh, "Unleash should not refresh if less than 24 hours have passed.")
    }

    func testDeviceRegionUpdateCheckWithNoDeviceRegionChange() async {
        // Given
        let configurator = UnleashRefreshConfigurator()
        configurator.withDeviceRegionUpdateCheckRule(localeProvider: MockLocale("us"))

        // When
        Unleash.model.deviceRegion = "us"

        // Then
        XCTAssertFalse(Unleash.shouldRefresh, "Unleash should not refresh when the device region has not changed.")
    }

    func testDeviceRegionUpdateCheckWithDeviceRegionChange() async {
        // Given
        let configurator = UnleashRefreshConfigurator()
        configurator.withDeviceRegionUpdateCheckRule(localeProvider: MockLocale("us"))

        // When
        Unleash.model.deviceRegion = "uk"

        // Then
        XCTAssertTrue(Unleash.shouldRefresh, "Unleash should refresh after a device region change.")
    }
}
