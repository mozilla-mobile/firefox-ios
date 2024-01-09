// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

extension XCTestCase {
    func wait(_ timeout: TimeInterval) {
        let expectation = XCTestExpectation(description: "Waiting for \(timeout) seconds")
        XCTWaiter().wait(for: [expectation], timeout: timeout)
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

    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(
                instance,
                "Instance should have been deallocated, potential memory leak.",
                file: file,
                line: line
            )
        }
    }
}
