/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

func XCTAssertOptionalNotNil(@autoclosure expression:  () -> AnyObject?, _ message: String? = nil) {
    let evaluatedExpression:AnyObject? = expression()

    if evaluatedExpression == nil {
        if let messageValue = message {
            XCTFail(messageValue)
        }
        else {
            XCTFail("Optional assertion failed: \(evaluatedExpression)")
        }
    }
}
