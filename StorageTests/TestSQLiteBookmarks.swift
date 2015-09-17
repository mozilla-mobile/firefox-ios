/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class TestSQLiteBookmarks: XCTestCase {
    func testBookmarks() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)
        let bookmarks = SQLiteBookmarks(db: db)

        let url = "http://url1/"
        let u = url.asURL!

        func addBookmark() -> Success {
            return bookmarks.addToMobileBookmarks(u, title: "Title", favicon: nil)
        }

        let e1 = self.expectationWithDescription("Waiting for add.")
        func modelContainsItem() -> Success {
            return bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID).bind { res in
                XCTAssertEqual((res.successValue?.current[0] as? BookmarkItem)?.url, url)
                e1.fulfill()
                return succeed()
            }
        }

        let e2 = self.expectationWithDescription("Waiting for existence check.")
        func itemExists() -> Success {
            return bookmarks.isBookmarked(url).bind { res in
                XCTAssertTrue(res.successValue ?? false)
                e2.fulfill()
                return succeed()
            }
        }

        let e3 = self.expectationWithDescription("Waiting for delete.")
        func removeItemFromModel() -> Success {
            return bookmarks.removeByURL("") >>== {
                XCTAssertTrue(true)
                e3.fulfill()
                return succeed()
            }
        }

        addBookmark()
            >>> modelContainsItem
            >>> itemExists
            >>> removeItemFromModel

        self.waitForExpectationsWithTimeout(10.0) { foo in }
    }
}