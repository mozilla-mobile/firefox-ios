// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperDataServiceTests: XCTestCase, WallpaperTestDataProvider {
    // MARK: - Properties
    var networking: NetworkingMock!

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        networking = NetworkingMock()
    }

    override func tearDown() {
        networking = nil
        super.tearDown()
    }

    // MARK: - Test metadata functions
    func testSuccessfullyExtractWallpaperMetadata_WithGoodData() async {
        let data = getDataFromJSONFile(named: .goodData)
        let expectedMetadata = getExpectedMetadata(for: .goodData)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testSuccessfullyExtractWallpaperMetadata_WithNoURL() async {
        let data = getDataFromJSONFile(named: .noLearnMoreURL)
        let expectedMetadata = getExpectedMetadata(for: .noLearnMoreURL)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testSuccessfullyExtractWallpaperMetadata_WithNoAvailabilityRange() async {
        let data = getDataFromJSONFile(named: .noAvailabilityRange)
        let expectedMetadata = getExpectedMetadata(for: .noAvailabilityRange)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testSuccessfullyExtractWallpaperMetadata_WithNoLocales() async {
        let data = getDataFromJSONFile(named: .noLocales)
        let expectedMetadata = getExpectedMetadata(for: .noLocales)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testSuccessfullyExtractWallpaperMetadata_WithOnlyStartingAvailability() async {
        let data = getDataFromJSONFile(named: .availabilityStart)
        let expectedMetadata = getExpectedMetadata(for: .availabilityStart)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testSuccessfullyExtractWallpaperMetadata_WithOnlyEndingAvailability() async {
        let data = getDataFromJSONFile(named: .availabilityEnd)
        let expectedMetadata = getExpectedMetadata(for: .availabilityEnd)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    func testFailToExtractWallpaperMetadata_WithBadLastUpdatedDate() async {
        let data = getDataFromJSONFile(named: .badLastUpdatedDate)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            _ = try await subject.getMetadata()
            XCTFail("We should fail the extraction process")
        } catch let error {
            XCTAssertEqual(error.localizedDescription,
                           "The data couldn’t be read because it isn’t in the correct format.",
                           "Unexpected decoding failure")
        }
    }

    func testFailToExtractWallpaperMetadata_WithBadTextColor() async {
        let data = getDataFromJSONFile(named: .badTextColor)
        let expectedMetadata = getExpectedMetadata(for: .badTextColor)

        networking.result = .success(data)
        let subject = WallpaperDataService(with: networking)

        do {
            let actualMetadata = try await subject.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch let error {
            XCTFail("We should not fail the extraction process despite bad text color, but did with error: \(error)")
        }
    }
}
