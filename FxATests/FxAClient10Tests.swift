/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxA
import UIKit
import XCTest

class FxAClient10Tests: XCTestCase {
    func testLoginSuccess() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = email
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let result = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        result.upon { result in
            if let response = result.successValue {
                XCTAssertNotNil(response.uid)
                XCTAssertEqual(response.verified, true)
                XCTAssertNotNil(response.sessionToken)
                XCTAssertNotNil(response.keyFetchToken)
            } else {
                let error = result.failureValue as NSError
                XCTAssertNil(error)
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testLoginFailure() {
        let e = self.expectationWithDescription("")

        let email : NSData = "testtestoo@mockmyid.com".utf8EncodedData!
        let password : NSData = "INCORRECT PASSWORD".utf8EncodedData!
        let quickStretchedPW : NSData = FxAClient10.quickStretchPW(email, password: password)

        let client = FxAClient10()
        let result = client.login(email, quickStretchedPW: quickStretchedPW, getKeys: true)
        result.upon { result in
            if let response = result.successValue {
                XCTFail("Got response: \(response)")
            } else {
                let error = result.failureValue as NSError
                XCTAssertEqual(error.code, 103) // Incorrect password.
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
