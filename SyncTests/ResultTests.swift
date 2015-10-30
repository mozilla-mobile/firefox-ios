/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import XCTest

// Trivial test for using Result.
class ResultTests: XCTestCase {
    func testResult() {
        let r = Maybe<Int>(success: 5)
        if let i = r.successValue {
            XCTAssertEqual(5, i)
        } else {
            XCTFail("Expected success.")
        }
    }
}
