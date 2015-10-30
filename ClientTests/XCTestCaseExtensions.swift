/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

extension XCTestCase {
    func wait(time: NSTimeInterval) {
        let expectation = expectationWithDescription("Wait")
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(time * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(time + 1, handler: nil)
    }

    func waitForCondition(timeout timeout: NSTimeInterval = 10, condition: () -> Bool) {
        let timeoutTime = NSDate.timeIntervalSinceReferenceDate() + timeout

        while !condition() {
            if NSDate.timeIntervalSinceReferenceDate() > timeoutTime {
                XCTFail("Condition timed out")
                return
            }

            wait(0.1)
        }
    }
}