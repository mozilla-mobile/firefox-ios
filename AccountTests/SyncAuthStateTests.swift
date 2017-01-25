/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import FxA
import Shared
import UIKit

import XCTest

class SyncAuthStateTests: LiveAccountTest {
    func testLive() {
        let e = self.expectation(description: "Wait for token.")
        syncAuthState(Date.now()).upon { result in
            if let (token, forKey) = result.successValue {
                let uidString = NSNumber(value: token.uid).stringValue
                XCTAssertTrue(token.api_endpoint.endsWith(uidString))
                XCTAssertNotNil(forKey)
            } else {
                if let error = result.failureValue as? AccountError {
                    XCTAssertEqual(error, AccountError.noSignedInUser)
                } else {
                    XCTAssertEqual(result.failureValue!.description, "")
                }
            }
            e.fulfill()
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }
}
