/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
@testable import Storage
@testable import Sync
import XCTest

// Thieved mercilessly from TestSQLiteBookmarks.
private func getBrowserDBForFile(filename: String, files: FileAccessor) -> BrowserDB? {
    let db = BrowserDB(filename: filename, files: files)

    // BrowserTable exists only to perform create/update etc. operations -- it's not
    // a queryable thing that needs to stick around.
    if !db.createOrUpdate(BrowserTable()) {
        return nil
    }
    return db
}

class TestBookmarkModel: FailFastTestCase {
    let files = MockFiles()

    override func tearDown() {
        do {
            try self.files.removeFilesInDirectory()
        } catch {
        }
        super.tearDown()
    }

    private func getBrowserDB(name: String) -> BrowserDB? {
        let file = "TBookmarkModel\(name).db"
        print("DB file named: \(file)")
        return getBrowserDBForFile(file, files: self.files)
    }

    func getSyncableBookmarks(name: String) -> MergedSQLiteBookmarks? {
        guard let db = self.getBrowserDB(name) else {
            XCTFail("Couldn't get prepared DB.")
            return nil
        }

        return MergedSQLiteBookmarks(db: db)
    }

    func testBookmarkEditableIfNeverSyncedAndEmptyBuffer() {
        guard let bookmarks = self.getSyncableBookmarks("A") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set a local bookmark
        let bookmarkURL = "http://AAA.com".asURL!
        bookmarks.local.insertBookmark(bookmarkURL, title: "AAA", favicon: nil, intoFolder: BookmarkRoots.MenuFolderGUID, withTitle: "").succeeded()

        XCTAssertTrue(bookmarks.isMirrorEmpty().value.successValue!)
        XCTAssertTrue(bookmarks.buffer.isEmpty().value.successValue!)

        let menuFolder = bookmarks.menuFolder()
        XCTAssertEqual(menuFolder.current.count, 1)
        XCTAssertTrue(menuFolder.current[0]!.isEditable)
    }

    func testBookmarkEditableIfNeverSyncedWithBufferedChanges() {
        guard let bookmarks = self.getSyncableBookmarks("B") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        let bookmarkURL = "http://AAA.com".asURL!
        bookmarks.local.insertBookmark(bookmarkURL, title: "AAA", favicon: nil, intoFolder: BookmarkRoots.MenuFolderGUID, withTitle: "").succeeded()

        // Add a buffer into the buffer
        let mirrorDate = NSDate.now() - 100000
        bookmarks.applyRecords([
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["BBB"]),
            BookmarkMirrorItem.bookmark("BBB", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "BBB", description: nil, URI: "http://BBB.com", tags: "", keyword: nil)
        ]).succeeded()

        XCTAssertFalse(bookmarks.buffer.isEmpty().value.successValue!)
        XCTAssertTrue(bookmarks.isMirrorEmpty().value.successValue!)

        // Check to see if we're editable
        let menuFolder = bookmarks.menuFolder()
        XCTAssertEqual(menuFolder.current.count, 1)
        XCTAssertTrue(menuFolder.current[0]!.isEditable)
    }

    func testBookmarksEditableWithEmptyBufferAndRemoteBookmark() {
        guard let bookmarks = self.getSyncableBookmarks("C") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Add a bookmark to the menu folder in our mirror
        let mirrorDate = NSDate.now() - 100000
        bookmarks.populateMirrorViaBuffer([
            BookmarkMirrorItem.folder(BookmarkRoots.RootGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "", description: "", children: BookmarkRoots.RootChildren),
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["CCC"]),
            BookmarkMirrorItem.bookmark("CCC", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "CCC", description: nil, URI: "http://CCC.com", tags: "", keyword: nil)
        ], atDate: mirrorDate)

        // Set a local bookmark
        let bookmarkURL = "http://AAA.com".asURL!
        bookmarks.local.insertBookmark(bookmarkURL, title: "AAA", favicon: nil, intoFolder: BookmarkRoots.MenuFolderGUID, withTitle: "").succeeded()

        XCTAssertTrue(bookmarks.buffer.isEmpty().value.successValue!)
        XCTAssertFalse(bookmarks.isMirrorEmpty().value.successValue!)

        // Check to see if we're editable
        let menuFolder = bookmarks.menuFolder()
        XCTAssertEqual(menuFolder.current.count, 2)
        XCTAssertTrue(menuFolder.current[0]!.isEditable)
        XCTAssertTrue(menuFolder.current[1]!.isEditable)
    }

    func testBookmarksNotEditableForUnmergedChanges() {
        guard let bookmarks = self.getSyncableBookmarks("D") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Add a bookmark to the menu folder in our mirror
        let mirrorDate = NSDate.now() - 100000
        bookmarks.populateMirrorViaBuffer([
            BookmarkMirrorItem.folder(BookmarkRoots.RootGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "", description: "", children: BookmarkRoots.RootChildren),
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["EEE"]),
            BookmarkMirrorItem.bookmark("EEE", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "EEE", description: nil, URI: "http://EEE.com", tags: "", keyword: nil)
        ], atDate: mirrorDate)

        bookmarks.local.insertBookmark("http://AAA.com".asURL!, title: "AAA", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Bookmarks Menu").succeeded()

        // Add some unmerged bookmarks into the menu folder in the buffer.
        bookmarks.applyRecords([
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["EEE", "FFF"]),
            BookmarkMirrorItem.bookmark("FFF", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "FFF", description: nil, URI: "http://FFF.com", tags: "", keyword: nil)
        ]).succeeded()

        XCTAssertFalse(bookmarks.buffer.isEmpty().value.successValue!)
        XCTAssertFalse(bookmarks.isMirrorEmpty().value.successValue!)

        // Check to see that we can't edit these bookmarks
        let menuFolder = bookmarks.menuFolder()
        XCTAssertEqual(menuFolder.current.count, 1)
        XCTAssertFalse(menuFolder.current[0]!.isEditable)

    }

    func testLocalBookmarksEditableWhileHavingUnmergedChangesAndEmptyMirror() {
        guard let bookmarks = self.getSyncableBookmarks("D") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        bookmarks.local.insertBookmark("http://AAA.com".asURL!, title: "AAA", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Bookmarks Menu").succeeded()

        // Add some unmerged bookmarks into the menu folder in the buffer.
        let mirrorDate = NSDate.now() - 100000
        bookmarks.applyRecords([
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["EEE", "FFF"]),
            BookmarkMirrorItem.bookmark("FFF", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "FFF", description: nil, URI: "http://FFF.com", tags: "", keyword: nil)
        ]).succeeded()

        // Local bookmark should be editable
        let mobileFolder = bookmarks.mobileFolder()
        XCTAssertEqual(mobileFolder.current.count, 2)
        XCTAssertTrue(mobileFolder.current[1]!.isEditable)
    }
}

private extension MergedSQLiteBookmarks {
    func isMirrorEmpty() -> Deferred<Maybe<Bool>> {
        return self.local.db.queryReturnsNoResults("SELECT 1 FROM \(TableBookmarksMirror)")
    }

    func wipeLocal() {
        self.local.db.run(["DELETE FROM \(TableBookmarksLocalStructure)", "DELETE FROM \(TableBookmarksLocal)"]).succeeded()
    }

    func populateMirrorViaBuffer(items: [BookmarkMirrorItem], atDate mirrorDate: Timestamp) {
        self.applyRecords(items).succeeded()

        // … and add the root relationships that will be missing (we don't do those for the buffer,
        // so we need to manually add them and move them across).
        self.buffer.db.run([
            "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.MenuFolderGUID)', 0),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.ToolbarFolderGUID)', 1),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.UnfiledFolderGUID)', 2),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.MobileFolderGUID)', 3)",
        ].joinWithSeparator(" ")).succeeded()

        // Move it all to the mirror.
        self.local.db.moveBufferToMirrorForTesting()
    }

    func menuFolder() -> BookmarksModel {
        return modelFactory.value.successValue!.modelForFolder(BookmarkRoots.MenuFolderGUID).value.successValue!
    }

    func mobileFolder() -> BookmarksModel {
        return modelFactory.value.successValue!.modelForFolder(BookmarkRoots.MobileFolderGUID).value.successValue!
    }
}