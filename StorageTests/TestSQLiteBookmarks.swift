/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

private func getBrowserDB(filename: String, files: FileAccessor) -> BrowserDB? {
    let db = BrowserDB(filename: filename, files: files)

    // BrowserTable exists only to perform create/update etc. operations -- it's not
    // a queryable thing that needs to stick around.
    if !db.createOrUpdate(BrowserTable(version: BrowserTable.DefaultVersion)) {
        return nil
    }
    return db
}

class TestSQLiteBookmarks: XCTestCase {
    func testBookmarks() {
        guard let db = getBrowserDB("browser.db", files: MockFiles()) else {
            XCTFail("Unable to create browser DB.")
            return
        }
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

    func testMirrorStorage() {
        guard let db = getBrowserDB("browser.db", files: MockFiles()) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarkMirrorStorage(db: db)

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", modified: NSDate.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.bookmark("bbbbbbbbbbbb", modified: NSDate.now() + 10, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "BBB", description: "BBB desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let toolbar = BookmarkMirrorItem.folder("toolbar", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]
        let applyA = bookmarks.applyRecords(recordsA, withMaxVars: 3).value
        XCTAssertTrue(applyA.isSuccess)

        guard let model = bookmarks.modelForRoot().value.successValue else {
            XCTFail("Unable to get root.")
            return
        }
        let root = model.current

        // The root isn't useful. The merged bookmark implementation doesn't use it.
        XCTAssertEqual(root.guid, BookmarkRoots.RootGUID)
        XCTAssertEqual(0, root.count)

        // Specifically fetching the fake desktop folder works, though.
        guard let desktopModel = bookmarks.modelForFolder(BookmarkRoots.FakeDesktopFolderGUID).value.successValue else {
            XCTFail("Unable to get desktop bookmarks.")
            return
        }

        // It contains the toolbar.
        let desktopFolder = desktopModel.current
        XCTAssertEqual(desktopFolder.guid, BookmarkRoots.FakeDesktopFolderGUID)
        XCTAssertEqual(1, desktopFolder.count)

        guard let toolbarModel = desktopModel.selectFolder(BookmarkRoots.ToolbarFolderGUID).value.successValue else {
            XCTFail("Unable to get toolbar.")
            return
        }

        // The toolbar is the child, and it has the two bookmarks as entries.
        let toolbarFolder = toolbarModel.current
        XCTAssertEqual(toolbarFolder.guid, BookmarkRoots.ToolbarFolderGUID)
        XCTAssertEqual(2, toolbarFolder.count)

        guard let first = toolbarModel.current[0] else {
            XCTFail("Expected to get AAA.")
            return
        }
        guard let second = toolbarModel.current[1] else {
            XCTFail("Expected to get BBB.")
            return
        }
        XCTAssertEqual(first.guid, "aaaaaaaaaaaa")
        XCTAssertEqual(first.title, "AAA")
        XCTAssertEqual((first as? BookmarkItem)?.url, "http://getfirefox.com")
        XCTAssertEqual(second.guid, "bbbbbbbbbbbb")
        XCTAssertEqual(second.title, "BBB")
        XCTAssertEqual((second as? BookmarkItem)?.url, "http://getfirefox.com")

        let del: [BookmarkMirrorItem] = [BookmarkMirrorItem.deleted(BookmarkNodeType.Bookmark, guid: "aaaaaaaaaaaa", modified: NSDate.now())]
        bookmarks.applyRecords(del, withMaxVars: 1)

        guard let newToolbar = bookmarks.modelForFolder(BookmarkRoots.ToolbarFolderGUID).value.successValue else {
            XCTFail("Unable to get toolbar.")
            return
        }
        XCTAssertEqual(newToolbar.current.count, 1)
        XCTAssertEqual(newToolbar.current[0]?.guid, "bbbbbbbbbbbb")
    }
}