/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxA
import Shared
import UIKit
import XCTest

class SyncAuthStateTests: LiveAccountTest {
    func testLive() {
        let e = self.expectationWithDescription("Wait for token.")
        syncAuthState(NSDate.now()).upon { result in
            if let (token, forKey) = result.successValue {
                let uidString = NSNumber(unsignedLongLong: token.uid).stringValue
                XCTAssertTrue(token.api_endpoint.endsWith(uidString))
                XCTAssertNotNil(forKey)
            } else {
                if let error = result.failureValue as? AccountError {
                    XCTAssertEqual(error, AccountError.NoSignedInUser)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
            }
            e.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}
