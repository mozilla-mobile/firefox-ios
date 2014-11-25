// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class TestBookmarks : AccountTest {
    func testBookmarks() {
        // Get the test account
        withTestAccount { account -> Void in
            let expectation = self.expectationWithDescription("asynchronous request")

            account.bookmarks.getAll({ (response: [Bookmark]) in
                XCTAssert(response.count > 0, "Found some bookmarks");
                for bookmark in response {
                    XCTAssertNotEqual(bookmark.url, "", "Bookmarks has url \(bookmark.url)")
                    XCTAssertNotEqual(bookmark.title, "", "Bookmarks has title \(bookmark.title)")
                    XCTAssert(bookmark.url != "", "Bookmarks has url \(bookmark.url)");
                    XCTAssert(bookmark.title != "", "Bookmarks has title  \(bookmark.title)");
                }
                expectation.fulfill()
            }, error: { (err: RequestError) -> Void in
                // Something has gone wrong. Assert and finish the test
                switch(err) {
                case RequestError.BadAuth:
                    XCTAssertTrue(false, "Should not have failed to get bookmarks (bad auth)")
                case RequestError.ConnectionFailed:
                    XCTAssertTrue(false, "Should not have failed to get bookmarks (connection failed)")
                }
                expectation.fulfill()
            });

            self.waitForExpectationsWithTimeout(10.0, handler:nil)
        }
    }
}