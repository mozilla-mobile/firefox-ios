// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ContentBlockerTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()

        // Ensure all rules are removed from the global store prior to each test
        let expectation = XCTestExpectation()
        await ContentBlocker.shared.removeAllRulesInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
    }

    func testCompileListsNotInStore_callsCompletionHandlerSuccessfully() async {
        let expectation = XCTestExpectation()
        await ContentBlocker.shared.compileListsNotInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
    }
}
