// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Foundation
import Shared
import Storage

import XCTest

class TestBookmarks: ProfileTest {
    /* Disabled due to issue #7411 - Should not have failed to get mock bookmarks
    func testBookmarks() {
        withTestProfile { profile -> Void in
            for i in 0...10 {
                let bookmark = ShareItem(url: "http://www.example.com/\(i)", title: "Example \(i)", favicon: nil)
                _ = profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID, url: bookmark.url, title: bookmark.title).value
            }

            let expectation = self.expectation(description: "asynchronous request")
            profile.places.getBookmarksTree(rootGUID: BookmarkRoots.MobileFolderGUID, recursive: false) >>== { folder in
                guard let mobileFolder = folder as? BookmarkFolder else {
                    XCTFail("Should not have failed to get mock bookmarks.")
                    expectation.fulfill()
                    return
                }

                // 11 bookmarks plus our two suggested sites.
                XCTAssertEqual(mobileFolder.children!.count, 11, "We create 11 stub bookmarks in the Mobile Bookmarks folder.")
                let bookmark = mobileFolder.children![0]
                XCTAssertTrue(bookmark is BookmarkItem)
                XCTAssertTrue((bookmark as! BookmarkItem).url.hasPrefix("http://www.example.com/"), "Example URL found.")
                expectation.fulfill()
            }

            self.waitForExpectations(timeout: 15.0, handler:nil)

            // This'll do.
            _ = profile.places.forceClose()
            try? profile.files.remove("profile-test_places.db")
        }
    }*/
}
