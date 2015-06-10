/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest


class TestDeferredSqlite: XCTestCase {
    func testCancelling() {
        let files = MockFiles()
        let db = SwiftData(filename: files.getAndEnsureDirectory(relativeDir: "test.db", error: nil)!)
        let expectation = self.expectationWithDescription("Wait")

        let deferred = DeferredSqliteOperation(block: { (connection, err) -> Int? in
            XCTFail("This should be cancelled before hitting this")
            return 2
        }, withDB: db).start()
        deferred.upon({ res in
            XCTAssert(res.isFailure, "Cancelled query is failure")
            expectation.fulfill()
        })
        deferred.cancel()

        waitForExpectationsWithTimeout(10, handler: nil)
    }
}