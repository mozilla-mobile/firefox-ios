// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest
@testable import Client
@testable import Ecosia

final class AnalyticsTests: XCTestCase {

    // Cleanup method that runs after each test
    override func tearDownWithError() throws {
        let defaults = UserDefaults.standard
        // Remove any saved dates or flags after each test to avoid side effects between tests
        defaults.removeObject(forKey: "dayPassedCheckIdentifier")
        defaults.removeObject(forKey: "installCheckIdentifier")
    }

    // MARK: - hasDayPassedSinceLastCheck Tests

    func testFirstCheckAlwaysReturnsTrue() throws {
        // Given: No previous date exists in UserDefaults for the identifier
        // (Handled by setUpWithError)

        // When: The method is called for the first time
        let result = Analytics.hasDayPassedSinceLastCheck(for: "dayPassedCheckIdentifier")

        // Then: The result should be true because no previous date exists
        XCTAssertTrue(result, "The first check should return true because no previous date exists.")
    }

    func testCheckWithinADayReturnsFalse() throws {
        // Given: The current date is saved as the last check date
        let defaults = UserDefaults.standard
        defaults.set(Date(), forKey: "dayPassedCheckIdentifier")

        // When: The method is called within the same day
        let result = Analytics.hasDayPassedSinceLastCheck(for: "dayPassedCheckIdentifier")

        // Then: The result should be false since less than a day has passed
        XCTAssertFalse(result, "The check should return false if it's been less than a day since the last check.")
    }

    func testDateUpdateAfterADayPasses() throws {
        // Given: A date more than a day ago is saved as the last check date
        let defaults = UserDefaults.standard
        let moreThanADayAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        defaults.set(moreThanADayAgo, forKey: "dayPassedCheckIdentifier")

        // When: The method is called after more than a day has passed
        let result = Analytics.hasDayPassedSinceLastCheck(for: "dayPassedCheckIdentifier")

        // Then: The method should return true and update the last check date to today
        XCTAssertTrue(result, "The check should return true since more than a day has passed.")
        let updatedDate = defaults.object(forKey: "dayPassedCheckIdentifier") as? Date
        XCTAssertNotNil(updatedDate, "The date should be updated in UserDefaults.")
        XCTAssertTrue(Calendar.current.isDateInToday(updatedDate!), "The last check date should be updated to today's date.")
    }

    func testHandleCorruptedOrMissingData() throws {
        // Given: Corrupted data (e.g., a string instead of a Date) is saved in UserDefaults
        let defaults = UserDefaults.standard
        defaults.set("corruptedData", forKey: "dayPassedCheckIdentifier")

        // When: The method is called
        let result = Analytics.hasDayPassedSinceLastCheck(for: "dayPassedCheckIdentifier")

        // Then: The method should return true, treat it as the first check, and reset the last check date to today
        XCTAssertTrue(result, "The method should handle corrupted data gracefully and treat it as the first check.")
        let updatedDate = defaults.object(forKey: "dayPassedCheckIdentifier") as? Date
        XCTAssertNotNil(updatedDate, "The date should be reset in UserDefaults after detecting corrupted data.")
        XCTAssertTrue(Calendar.current.isDateInToday(updatedDate!), "The last check date should be updated to today's date after handling corrupted data.")
    }

    // MARK: - isFirstInstall Tests

    func testIsFirstInstall_FirstCall_ReturnsTrue() {
        // Given: No previous installation flag exists in UserDefaults for the identifier
        // Also, EcosiaInstallType is not set to .upgrade
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "installCheckIdentifier")
        defaults.removeObject(forKey: EcosiaInstallType.installTypeKey)

        // Set EcosiaInstallType to .fresh to simulate a fresh install
        EcosiaInstallType.set(type: .fresh)

        // When: The method is called for the first time
        let result = Analytics.isFirstInstall(for: "installCheckIdentifier")

        // Then: The result should be true indicating the first install
        XCTAssertTrue(result, "The first install should return TRUE when not an upgrade")
    }

    func testIsFirstInstall_SecondCall_ReturnsFalse() {
        // Given: The method has already been called once
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "installCheckIdentifier")
        defaults.removeObject(forKey: EcosiaInstallType.installTypeKey)

        // Set EcosiaInstallType to .fresh to simulate a fresh install
        EcosiaInstallType.set(type: .fresh)

        // First call to set the flag
        _ = Analytics.isFirstInstall(for: "installCheckIdentifier")

        // When: The method is called again
        let result = Analytics.isFirstInstall(for: "installCheckIdentifier")

        // Then: The result should be false indicating it is no longer the first install
        XCTAssertFalse(result, "The second call should return FALSE as the app is no longer on its first install")
    }

    func testIsFirstInstall_StoresValueInUserDefaults() {
        // Given: The method is called for the first time
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "installCheckIdentifier")
        defaults.removeObject(forKey: EcosiaInstallType.installTypeKey)

        // Set EcosiaInstallType to .fresh to simulate a fresh install
        EcosiaInstallType.set(type: .fresh)

        _ = Analytics.isFirstInstall(for: "installCheckIdentifier")

        // When: The value is retrieved from UserDefaults
        let storedValue = defaults.object(forKey: "installCheckIdentifier") as? Bool

        // Then: The stored value should be false indicating the first install has been recorded
        XCTAssertNotNil(storedValue, "The value should be stored in UserDefaults")
        XCTAssertEqual(storedValue, false, "The stored value in UserDefaults should be FALSE after the first call")
    }

    func testIsFirstInstall_FirstCallOnUpgrade_ReturnsFalse() {
        // Given: No previous installation flag exists in UserDefaults for the identifier
        // Also, EcosiaInstallType is set to .upgrade
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "installCheckIdentifier")
        defaults.removeObject(forKey: EcosiaInstallType.installTypeKey)

        // Set EcosiaInstallType to .upgrade to simulate an upgrade scenario
        EcosiaInstallType.set(type: .upgrade)

        // When: The method is called for the first time
        let result = Analytics.isFirstInstall(for: "installCheckIdentifier")

        // Then: The result should be false because it's an upgrade
        XCTAssertFalse(result, "The first install should return FALSE when it's an upgrade")
    }

    func test_makeNetworkConfig_usesStandardEndpoint_whenShouldUseMicroIsFalse() {
        Analytics.shouldUseMicroInstance = false
        let mockUrlProvider: URLProvider = .staging
        let config = Analytics.makeNetworkConfig(urlProvider: mockUrlProvider)
        XCTAssertEqual(mockUrlProvider.snowplow, config.endpoint?.asURL?.host)
    }

    func test_makeNetworkConfig_usesMicroEndpoint_whenShouldUseMicroIsTrue() {
        Analytics.shouldUseMicroInstance = true
        let mockUrlProvider: URLProvider = .staging
        let config = Analytics.makeNetworkConfig(urlProvider: mockUrlProvider)
        XCTAssertEqual(mockUrlProvider.snowplowMicro, config.endpoint)
        XCTAssertEqual(config.requestHeaders?.keys.contains(CloudflareKeyProvider.clientId), true)
        XCTAssertEqual(config.requestHeaders?.keys.contains(CloudflareKeyProvider.clientSecret), true)
    }

    func test_makeNetworkConfig_usesProductionEndpoint_whenShouldUseMicroIsFalse_andUrlProvider_isProduction() {
        Analytics.shouldUseMicroInstance = false
        let mockUrlProvider: URLProvider = .production
        let config = Analytics.makeNetworkConfig(urlProvider: mockUrlProvider)
        XCTAssertEqual(mockUrlProvider.snowplow, "sp.ecosia.org")
        XCTAssertEqual(mockUrlProvider.snowplow, config.endpoint?.asURL?.host)
        XCTAssertNil(config.requestHeaders?.keys.contains(CloudflareKeyProvider.clientId))
        XCTAssertNil(config.requestHeaders?.keys.contains(CloudflareKeyProvider.clientSecret))
    }
}
