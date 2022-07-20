// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperNetworkUtilityTests: XCTestCase {

    func testGetData_SimulatingNoResponse() async {
        let dataService = WallpaperNetworkDataServiceMock()
        let sut = WallpaperDataService(with: dataService)

        let result: Result<WallpaperMetadata, Error>? = nil
        dataService.setServiceResponse(to: result)

        do {
            _ = try await sut.getMetadata()
            XCTFail("This test should throw an error.")
        } catch let error {
            XCTAssertThrowsError(error)
        }
    }
}

extension WallpaperNetworkUtilityTests {
    
}
