/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class WaitCondition {
    let userStatePredicate: NSPredicate?
    let predicate: NSPredicate
    let object: Any
    let file: String
    let line: UInt

    init(_ predicate: String, object: Any, if userStatePredicate: String? = nil, file: String, line: UInt) {
        self.predicate = NSPredicate(format: predicate)
        if let p = userStatePredicate {
            self.userStatePredicate = NSPredicate(format: p)
        } else {
            self.userStatePredicate = nil
        }
        self.object = object
        self.file = file
        self.line = line
    }

    func wait(timeoutHandler: () -> ()) {
        waitOrTimeout(predicate, object: object, timeoutHandler: timeoutHandler)
    }
}

let existsPredicate = NSPredicate(format: "exists == true")

// This is a function for waiting for a condition of an object to come true.
func waitOrTimeout(_ predicate: NSPredicate = existsPredicate, object: Any, timeout: TimeInterval = 5, timeoutHandler: () -> ()) {
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: object)
    let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
    if result != .completed {
        timeoutHandler()
    }
}
