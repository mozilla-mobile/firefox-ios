/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
import FxA
import Client

let TEST_AUTH_API_ENDPOINT = STAGE_AUTH_SERVER_ENDPOINT

class FxAClient10Tests: XCTestCase {
    func testLoginSuccess() {
        let client = FxAClient10()

        let email : NSData = "testtestoo@mockmyid.com".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        let password : NSData = email
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let expectation = expectationWithDescription("login to \(TEST_AUTH_API_ENDPOINT)")
        client.login(emailUTF8: email, quickStretchedPW: quickStretchedPW, getKeys: true) { (response, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
            XCTAssertNotNil(response!.uid)
            XCTAssertEqual(response!.verified, true)
            XCTAssertNotNil(response!.sessionToken)
            XCTAssertNotNil(response!.keyFetchToken)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10) { (error) in
            XCTAssertNil(error, "\(error)")
        }
    }
}
