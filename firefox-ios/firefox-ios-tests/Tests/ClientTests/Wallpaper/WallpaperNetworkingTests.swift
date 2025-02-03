// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperNetworkingTests: XCTestCase {
    var networking: NetworkingMock!

    override func setUp() {
        super.setUp()
        networking = NetworkingMock()
    }

    override func tearDown() {
        networking = nil
        super.tearDown()
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

    func testChangingNetworkResultReturnsExpectedResult() async {
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
}
