// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperDataServiceTests: XCTestCase, WallpaperTestDataProvider {
    typealias ServiceError = WallpaperDataService.DataServiceError

    var networking: NetworkingMock!

    override func setUp() {
        networking = NetworkingMock()
    }

    override func tearDown() {
        networking = nil
    }

    // MARK: - Test metadata functions
    func testExtractGoodDataToWallpaperMetadata() async {
        let data = getDataFromJSONFile(named: .goodData)
        let expectedMetadata = getExpectedMetadata(for: .goodData)

        networking.result = .success(data)
        let sut = WallpaperDataService(with: networking)

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

    func testExtractBadLastUpdatedDateToWallpaperMetadata() async {
        let data = getDataFromJSONFile(named: .badLastUpdatedDate)

        networking.result = .success(data)
        let sut = WallpaperDataService(with: networking)

        do {
            _ = try await sut.getMetadata()
            XCTFail("We should fail the extraction process")
        } catch let error {
            XCTFail(error.localizedDescription)
        }
    }

}

// MARK: - Test fetching images
extension WallpaperDataServiceTests {

}
