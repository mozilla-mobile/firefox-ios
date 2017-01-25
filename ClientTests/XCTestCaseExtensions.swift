/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

extension XCTestCase {
    func wait(_ time: TimeInterval) {
        let expectation = self.expectation(description: "Wait")
        let delayTime = DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: time + 1, handler: nil)
    }

    func waitForCondition(timeout: TimeInterval = 10, condition: () -> Bool) {
        let timeoutTime = Date.timeIntervalSinceReferenceDate + timeout

        while !condition() {
            if Date.timeIntervalSinceReferenceDate > timeoutTime {
                XCTFail("Condition timed out")
                return
            }

            wait(0.1)
        }
    }
}
