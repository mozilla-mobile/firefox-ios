/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage

class TestBookmarks : ProfileTest {
    func testBookmarks() {
        withTestProfile { profile -> Void in
            for i in 0...10 {
                let bookmark = ShareItem(url: "http://www.example.com/\(i)", title: "Example \(i)", favicon: nil)
                profile.bookmarks.shareItem(bookmark)
            }

            let expectation = self.expectationWithDescription("asynchronous request")
            profile.bookmarks.modelForRoot({ (model: BookmarksModel) in
                XCTAssertEqual(model.current.count, 11, "We create \(model.current.count) stub bookmarks.")
                let bookmark = model.current[0]
                XCTAssertTrue(bookmark is BookmarkItem)
                XCTAssertEqual((bookmark as! BookmarkItem).url, "http://www.example.com/0", "Example URL found.")
                expectation.fulfill()
            }, failure: { (Any) -> () in
                XCTFail("Should not have failed to get mock bookmarks.")
                expectation.fulfill()
            })

            self.waitForExpectationsWithTimeout(10.0, handler:nil)
        }
    }
}
