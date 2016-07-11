/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Shared
import Deferred
import XCTest

// Trivial test for using Deferred.

class DeferredTests: XCTestCase {
    func testDeferred() {
        let d = Deferred<Int>()
        XCTAssertNil(d.peek(), "Value not yet filled.")

        let expectation = self.expectation(withDescription: "Waiting on value.")
        d.upon({ x in
            expectation.fulfill()
        })

        d.fill(5)
        waitForExpectations(withTimeout: 10) { (error) in
            XCTAssertNil(error, "\(error)")
        }

        XCTAssertEqual(5, d.peek()!, "Value is filled.");
    }

    func testMultipleUponBlocks() {
        let e1 = self.expectation(withDescription: "First.")
        let e2 = self.expectation(withDescription: "Second.")
        let d = Deferred<Int>()
        d.upon { x in
            XCTAssertEqual(x, 5)
            e1.fulfill()
        }
        d.upon { x in
            XCTAssertEqual(x, 5)
            e2.fulfill()
        }
        d.fill(5)
        waitForExpectations(withTimeout: 10, handler: nil)
    }

    func testOperators() {
        let e1 = self.expectation(withDescription: "First.")
        let e2 = self.expectation(withDescription: "Second.")

        let f1: () -> Deferred<Maybe<Int>> = {
            return deferMaybe(5)
        }

        let f2: (x: Int) -> Deferred<Maybe<String>> = {
            if $0 == 5 {
                e1.fulfill()
            }
            return deferMaybe("Hello!")
        }

        // Type signatures:
        let combined: () -> Deferred<Maybe<String>> = { f1() >>== f2 }
        let result: Deferred<Maybe<String>> = combined()

        result.upon {
            XCTAssertEqual("Hello!", $0.successValue!)
            e2.fulfill()
        }

        waitForExpectations(withTimeout: 10, handler: nil)
    }
}
