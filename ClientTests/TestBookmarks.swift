/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import Storage

import XCTest

class TestBookmarks: ProfileTest {
    func testBookmarks() {
        withTestProfile { profile -> Void in
            for i in 0...10 {
                let bookmark = ShareItem(url: "http://www.example.com/\(i)", title: "Example \(i)", favicon: nil)
                profile.bookmarks.shareItem(bookmark)
            }

            let expectation = self.expectationWithDescription("asynchronous request")
            profile.bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID).upon { result in
                guard let model = result.successValue else {
                    XCTFail("Should not have failed to get mock bookmarks.")
                    expectation.fulfill()
                    return
                }
                // 11 bookmarks plus our two suggested sites.
                XCTAssertEqual(model.current.count, 13, "We create \(model.current.count) stub bookmarks in the Mobile Bookmarks folder.")
                let bookmark = model.current[0]
                XCTAssertTrue(bookmark is BookmarkItem)
                XCTAssertEqual((bookmark as! BookmarkItem).url, "http://www.example.com/0", "Example URL found.")
                expectation.fulfill()
            }

            self.waitForExpectationsWithTimeout(10.0, handler:nil)
            // This'll do.
            try! profile.files.remove("mock.db")
        }
    }
}
