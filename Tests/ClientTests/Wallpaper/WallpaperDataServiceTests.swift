// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperDataServiceTests: XCTestCase {
    typealias ServiceError = WallpaperDataService.WallpaperDataServiceError

    // MARK: - Test metadata functions
    func testGetData_SimulatingNoInternet() async {
        let networking = NetworkingMock()
        let sut = WallpaperDataService(with: networking)

        do {
            _ = try await sut.getMetadata()
            XCTFail("This test should throw an error.")
        } catch let error {
            XCTAssertEqual(error as? URLError, URLError(.notConnectedToInternet))
        }
    }

    func testGetData_SimulatingBadResponse() async {
        let networking = NetworkingMock()
        networking.result = .failure(URLError(.badServerResponse))
        let sut = WallpaperDataService(with: networking)

        do {
            _ = try await sut.getMetadata()
            XCTFail("This test should throw an error.")
        } catch let error {
            XCTAssertEqual(error as? URLError, URLError(.badServerResponse))
        }
    }

    func testExtractWallpaperMetadata() async {
        let data = convertLocalJSONToData()
        let networking = NetworkingMock()
        networking.result = .success(data)
        let sut = WallpaperDataService(with: networking)

        let lastUpdatedDate = dateWith(year: 2001, month: 02, day: 03)
        let startDate = dateWith(year: 2002, month: 11, day: 28)
        let endDate = dateWith(year: 2022, month: 09, day: 10)

        let expectedMetadata = WallpaperMetadata(
            lastUpdated: lastUpdatedDate,
            collections: [
                WallpaperCollection(
                    id: "firefox",
                    availableLocales: ["en-US", "es-US", "en-CA", "fr-CA"],
                    availability: WallpaperCollectionAvailability(
                        start: startDate,
                        end: endDate),
                    wallpapers: [
                        Wallpaper(id: "beachVibes", textColour: "0xADD8E6")
                    ])
            ])

        do {
            let actualMetadata = try await sut.getMetadata()
            XCTAssertEqual(
                actualMetadata,
                expectedMetadata,
                "The metadata that was decoded from data was not what was expected.")
        } catch {
            XCTFail("We should not fail the extraction process, but did with error: \(error)")
        }
    }

    // MARK: - Test fetching images

    // MARK: - Test bulding URLs
//    func testBuildingURLForMetadata() {
//        let sut = WallpaperDataService()
//
//        let suffix = "\(WallpaperDataService.metadataEndpoint)\(WallpaperDataService.versionEndpoint)"
//
//        let expectedURL = URL(string: "https://my.test.url\(suffix)")?.absoluteString
//        let actualURL = sut.buildURLWith(for: .metadata)?.absoluteString
//
//        XCTAssertEqual(actualURL, expectedURL, "beep boop")
//    }
//
//    func testBuildingURLForImage() {
//        let sut = WallpaperDataService()
//
//        let path = "/imageName/imageName_thumbnail"
//
//        let expectedURL = URL(string: "https://my.test.url\(path).png")?.absoluteString
//        let actualURL = sut.buildURLWith(for: .image, using: path)?.absoluteString
//
//        XCTAssertEqual(
//            actualURL,
//            expectedURL,
//            "The urls do not match, when it is expected that they should")
//    }
}

// MARK: - Test helpers
extension WallpaperDataServiceTests {
    private func convertLocalJSONToData() -> Data {

        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: "wallpaperInitial", withExtension: "json") else {
            fatalError("Missing file: User.json")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Test")
        }

        return data
    }

    private func dateWith(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        let userCalendar = Calendar(identifier: .gregorian)
        guard let expectedDate = userCalendar.date(from: dateComponents) else {
            fatalError("Error creating expected date.")
        }

        return expectedDate
    }
}
