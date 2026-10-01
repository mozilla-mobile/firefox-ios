// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

class ServerErrorHelperTests {
    func testIsClientError_whenNetworkError() async {
        let networkError = URLError(.notConnectedToInternet)

        let isClientError = ServerErrorHelper.isClientError(networkError)

        XCTAssertTrue(isClientError, "The error should be identified as a client error.")
    }

    func testIsClientError_whenServerError() async {
        let serverError = URLError(.badServerResponse)

        let isClientError = ServerErrorHelper.isClientError(serverError)

        XCTAssertFalse(isClientError, "The error should be identified as a server error.")
    }
}
