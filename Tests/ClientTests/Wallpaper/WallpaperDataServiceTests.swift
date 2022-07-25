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

    func testSetupWorksAsExpected() async {
        do {
            _ = try await networking.data(from: URL(string: "mozilla.com")!)
            XCTFail("This test should throw an error.")
        } catch {
            XCTAssertEqual(error as? URLError,
                           URLError(.notConnectedToInternet),
                           "Initial result was different than what was expected.")
        }
    }

    func testChangingNetworkingReturnResult() async {
        networking.result = .failure(URLError(.badServerResponse))

        do {
            _ = try await networking.data(from: URL(string: "mozilla.com")!)
            XCTFail("This test should throw an error.")
        } catch {
            XCTAssertEqual(error as? URLError,
                           URLError(.badServerResponse),
                           "Response result was different than what was expected.")
        }
    }

    // MARK: - Test metadata functions
    func testExtractWallpaperMetadata() async {
        let data = getDataFromJSONFile(named: .initial)
        let expectedMetadata = getExpectedMetadata(for: .initial)

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

    // MARK: - Test fetching images
}

// MARK: - Test helpers
extension WallpaperDataServiceTests {
}
