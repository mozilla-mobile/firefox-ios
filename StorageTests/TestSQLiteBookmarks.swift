/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class TestSQLiteBookmarks: XCTestCase {
    func testBookmarks() {
        let files = MockFiles()
        let db = BrowserDB(files: files)
        let history = SQLiteHistory(db: db)
        let bookmarks = SQLiteBookmarks(db: db, favicons: history)

        let url = "http://url1/"
        let u = url.asURL!

        func addBookmark() -> Success {
            return bookmarks.addToMobileBookmarks(u, title: "Title", favicon: nil)
        }

        let e1 = self.expectationWithDescription("Waiting for add.")
        func modelContainsItem() -> Success {
            bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID,
                success: { (model: BookmarksModel) in
                    let folder = model.current
                    let child = folder[0] as? BookmarkItem
                    XCTAssertEqual(url, child!.url)
                    e1.fulfill()
                },
                failure: { any in })
            return succeed()
        }

        let e2 = self.expectationWithDescription("Waiting for existence check.")
        func itemExists() -> Success {
            bookmarks.isBookmarked(url,
                success: { yes in
                    XCTAssertTrue(yes)
                    e2.fulfill()
                },
                failure: { any in })
            return succeed()
        }

        let e3 = self.expectationWithDescription("Waiting for delete.")
        func removeItemFromModel() -> Success {
            bookmarks.removeByURL(url,
                success: { yes in
                    XCTAssertTrue(yes)
                    e3.fulfill()
                },
                failure: { any in })
            return succeed()
        }

        addBookmark()
            >>> modelContainsItem
            >>> itemExists
            >>> removeItemFromModel

        self.waitForExpectationsWithTimeout(10.0) { foo in }
    }
}