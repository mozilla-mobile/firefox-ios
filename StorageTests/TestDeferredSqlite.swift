/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest


class TestDeferredSqlite: XCTestCase {
    func testCancelling() {
        let files = MockFiles()
        let db = SwiftData(filename: (try! (files.getAndEnsureDirectory() as NSString)).stringByAppendingPathComponent("test.db"))
        let expectation = self.expectationWithDescription("Wait")

        let deferred = DeferredDBOperation(db: db, block: { (connection, err) -> Int? in
            XCTFail("This should be cancelled before hitting this")
            return 2
        })

        deferred.upon({ res in
            XCTAssert(res.isFailure, "Cancelled query is failure")
            expectation.fulfill()
        })

        deferred.cancel()
        deferred.start()

        waitForExpectationsWithTimeout(10, handler: nil)
    }
}