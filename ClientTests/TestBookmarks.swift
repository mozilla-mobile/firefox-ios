// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class TestBookmarks : AccountTest {
    func testBookmarks() {
        withTestAccount { account -> Void in
            let expectation = self.expectationWithDescription("asynchronous request")

            MockAccount().bookmarks.modelForFolder("mobile", success: { (model: BookmarksModel) in
                XCTAssert(model.current.count == 11, "We create 11 stub bookmarks.")
                let bookmark = model.current.get(0)
                XCTAssertTrue(bookmark != nil)
                XCTAssertTrue(bookmark is BookmarkItem)
                XCTAssertEqual((bookmark as BookmarkItem).url, "http://www.example.com/0", "Example URL found.")
                expectation.fulfill()
            }, failure: { (Any) -> () in
                XCTFail("Should not have failed to get mock bookmarks.")
                expectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(10.0, handler:nil)
        }
    }
}