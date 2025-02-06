// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class BrazeServiceTests: XCTestCase {
    var brazeService: BrazeService!

    override func setUp() {
        super.setUp()
        brazeService = BrazeService.shared
    }

    override func tearDown() {
        super.tearDown()
        brazeService = nil
    }

    func testConfigurationWithStagingEnvironment() {
        // Set up your test environment for staging
        let apiKey = "staging_api_key"

        // Call the configuration retrieval
        do {
            let brazeConfiguration = try brazeService.getBrazeConfiguration(apiKey: apiKey, environment: .staging)

            // Assert that the configuration is not nil
            XCTAssertNotNil(brazeConfiguration)

            // Assert that the configuration has the expected values for staging
            XCTAssertEqual(brazeConfiguration.api.key, "staging_api_key")
        } catch {
            // If an unexpected error occurs, fail the test
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfigurationWithProductionEnvironment() {
        // Set up your test environment for production
        let apiKey = "production_api_key"

        // Call the configuration retrieval
        do {
            let brazeConfiguration = try brazeService.getBrazeConfiguration(apiKey: apiKey, environment: .production)

            // Assert that the configuration is not nil
            XCTAssertNotNil(brazeConfiguration)

            // Assert that the configuration has the expected values for production
            XCTAssertEqual(brazeConfiguration.api.key, "production_api_key")
        } catch {
            // If an unexpected error occurs, fail the test
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfigurationWithInvalidEnvironment_InavlidApiKey() {
        // Set up your test environment with missing or invalid configuration
        let apiKey = ""

        // Call the configuration retrieval
        do {
            _ = try brazeService.getBrazeConfiguration(apiKey: apiKey, environment: .production)

            XCTFail("Expected getBrazeConfiguration to throw an error for invalid configuration")
        } catch BrazeService.Error.invalidConfiguration {
            // If the error is as expected, the test succeeds
        } catch {
            // If an unexpected error occurs, fail the test
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testConfigurationWithInvalidEnvironment_InavlidEndpoint() {
        // Set up your test environment with missing or invalid configuration
        let apiKey = ""

        // Call the configuration retrieval
        do {
            _ = try brazeService.getBrazeConfiguration(apiKey: apiKey, environment: .production)

            XCTFail("Expected getBrazeConfiguration to throw an error for invalid configuration")
        } catch BrazeService.Error.invalidConfiguration {
            // If the error is as expected, the test succeeds
        } catch {
            // If an unexpected error occurs, fail the test
            XCTFail("Unexpected error: \(error)")
        }
    }
}
