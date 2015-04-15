/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

private let ProductionServiceURLString = "https://readinglist.services.mozilla.com"
private let ProductionToken = "TODO REPLACE THIS WITH AN ACTUAL TOKEN"

/// Read-only test on the production endpoint to find out if OAuth authentication works. This test
/// only runs if some special file is present in the project root. We don't do that yet.
class ReadingListOAuthAuthenticatorTestCase: XCTestCase {
    var authenticator: ReadingListAuthenticator!
    var client: ReadingListClient!

    override func setUp() {
        super.setUp()
        if let serviceURL = NSURL(string: ProductionServiceURLString) {
            authenticator = ReadingListOAuthAuthAuthenticator(token: ProductionToken)
            self.client = ReadingListClient(serviceURL: serviceURL, authenticator: authenticator)
            XCTAssertNotNil(self.client)
        } else {
            XCTFail("Cannot parse service url")
        }
    }

    // TODO Enable this when we can use a test token
//    func testGetAllRecords() {
//        let readyExpectation = expectationWithDescription("ready")
//
//        let fetchSpec = ReadingListFetchSpec.Builder().build()
//        client.getAllRecordsWithFetchSpec(fetchSpec, completion: { (result: ReadingListGetAllRecordsResult) -> Void in
//            readyExpectation.fulfill()
//            switch result {
//            case ReadingListGetAllRecordsResult.Success(let response):
//                if let records = response.records {
//                    XCTAssertTrue(records.count != 0)
//                } else {
//                    XCTFail("Expected response.record")
//                }
//            default:
//                XCTFail("Expected a ReadingListGetAllRecordsResult.Success")
//            }
//        })
//
//        waitForExpectationsWithTimeout(5.0, handler: { error in
//            XCTAssertNil(error, "Error")
//        })
//    }
}
