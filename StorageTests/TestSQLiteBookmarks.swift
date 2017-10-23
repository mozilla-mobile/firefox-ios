/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest

private func getBrowserDB(_ filename: String, files: FileAccessor) -> BrowserDB? {
    return BrowserDB(filename: filename, schema: BrowserSchema(), files: files)
}

extension SQLiteBookmarks {
    var testFactory: SQLiteBookmarksModelFactory {
        return SQLiteBookmarksModelFactory(bookmarks: self, direction: .local)
    }
}

// MARK: - Tests.

class TestTruncation: XCTestCase {
    func testTruncate() {
        let a = "🤠"
        let b = "abcdefghi"
        let c = ""
        XCTAssertEqual(a.truncateToUTF8ByteCount(1), "")
        XCTAssertEqual(a.truncateToUTF8ByteCount(4), a)
        XCTAssertEqual(a.truncateToUTF8ByteCount(16), a)

        XCTAssertEqual(b.truncateToUTF8ByteCount(16), b)
        XCTAssertEqual(b.truncateToUTF8ByteCount(5), "abcde")
        XCTAssertEqual(b.truncateToUTF8ByteCount(0), "")
        XCTAssertEqual(c.truncateToUTF8ByteCount(1), c)
        XCTAssertEqual(c.truncateToUTF8ByteCount(4), c)
    }
}

class TestSQLiteBookmarks: XCTestCase {
    let files = MockFiles()

    fileprivate func remove(_ path: String) {
        do {
            try self.files.remove(path)
        } catch {}
    }

    override func tearDown() {
        self.remove("TSQLBtestBookmarks.db")
        self.remove("TSQLBtestBufferStorage.db")
        self.remove("TSQLBtestLocalAndMirror.db")
        self.remove("TSQLBtestRecursiveAndURLDelete.db")
        self.remove("TSQLBtestUnrooted.db")
        self.remove("TSQLBtestTreeBuilding.db")
        self.remove("TSQLBtestLocalBookmarksModifications.db")
        self.remove("TSQLBtestApplyBufferUpdatedCompletionOp.db")
        self.remove("TSQLBtestApplyRecordsPendingDeletions.db")
        super.tearDown()
    }

    func testBookmarks() {
        guard let db = getBrowserDB("TSQLBtestBookmarks.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarks(db: db)
        let factory = bookmarks.testFactory

        let url = "http://url1/"
        let u = url.asURL!

        bookmarks.addToMobileBookmarks(u, title: "Title", favicon: nil).succeeded()
        let model = factory.modelForFolder(BookmarkRoots.MobileFolderGUID).value.successValue
        XCTAssertEqual((model?.current[0] as? BookmarkItem)?.url, url)
        XCTAssertTrue(factory.isBookmarked(url).value.successValue ?? false)
        factory.removeByURL("").succeeded()

        // Grab that GUID and move it into desktop bookmarks.
        let guid = (model?.current[0] as! BookmarkItem).guid

        // Desktop bookmarks.
        XCTAssertFalse(factory.hasDesktopBookmarks().value.successValue ?? true)
        let toolbar = BookmarkRoots.ToolbarFolderGUID
        XCTAssertTrue(bookmarks.db.run([
            "UPDATE \(TableBookmarksLocal) SET parentid = '\(toolbar)' WHERE guid = '\(guid)'",
            "UPDATE \(TableBookmarksLocalStructure) SET parent = '\(toolbar)' WHERE child = '\(guid)'",
            ]).value.isSuccess)
        XCTAssertTrue(factory.hasDesktopBookmarks().value.successValue ?? true)
    }

    func testGetLocalBookmarksModifications() {
        guard let db = getBrowserDB("TSQLBtestLocalBookmarksModifications.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarks(db: db)

        let localQuery =
        "INSERT INTO \(TableBookmarksLocal) (guid, type, bmkUri, title, parentid, parentName, sync_status) " +
        "VALUES " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 0), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', 2) "

        let localArgs: Args = [
            "folder123", "123 (nok)", BookmarkRoots.MobileFolderGUID,
            "bookmark123", "http://example.org/1", "Bookmark in folder 123 (nok)", "folder123",
            "bookmark_other_folder", "http://example.org/2", "Bookmark in another folder (nok)", BookmarkRoots.ToolbarFolderGUID,
            "bookmark_good_nonsynced", "http://example.org/3", "Bookmark 1 (ok)", BookmarkRoots.MobileFolderGUID,
            "bookmark_good_synced", "http://example.org/4", "Bookmark 2 (nok)", BookmarkRoots.MobileFolderGUID,
            "bookmark_duplicate_in_buffer", "http://example.org/5", "Bookmark in buffer(nok)", BookmarkRoots.MobileFolderGUID,
            "bookmark_good_additional", "http://example.org/6", "Bookmark additional 1", BookmarkRoots.MobileFolderGUID,
            "bookmark_good_additional_over_limit", "http://example.org/7", "Bookmark additional 2", BookmarkRoots.MobileFolderGUID,
        ]

        let structureQuery =
        "INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?) "

        let structureArgs: Args = [
            BookmarkRoots.MobileFolderGUID, "folder123", 0,
            "folder123", "bookmark123", 0,
            BookmarkRoots.ToolbarFolderGUID, "bookmark_other_folder", 0,
            BookmarkRoots.MobileFolderGUID, "bookmark_good_nonsynced", 1,
            BookmarkRoots.MobileFolderGUID, "bookmark_good_synced", 2,
            BookmarkRoots.MobileFolderGUID, "bookmark_duplicate_in_buffer", 3,
            BookmarkRoots.MobileFolderGUID, "bookmark_good_additional", 4,
            BookmarkRoots.MobileFolderGUID, "bookmark_good_additional_over_limit", 5,
        ]

        let bufferQuery =
        "INSERT INTO \(TableBookmarksBuffer) (guid, type, bmkUri, title, parentid, parentName, server_modified) VALUES " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?) "

        let bufferArgs: Args = [
            "bookmark_duplicate_in_buffer", "http://example.org/5", "Bookmark in buffer(nok)", BookmarkRoots.MobileFolderGUID, Date.now(),
            "bookmark_to_delete", "http://example.org/delme", "Bookmark in buffer to delete(ok)", BookmarkRoots.MobileFolderGUID, 88888
        ]

        let bufferStructureQuery =
        "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES " +
        "(?, ?, ?), " +
        "(?, ?, ?)"

        let bufferStructureArgs: Args = [
            "bookmark_duplicate_in_buffer", "bookmark_duplicate_in_buffer", 0, // It's its own parent because we are lazy.
            "bookmark_to_delete", "bookmark_to_delete", 0
        ]

        let pendingDeletionsQuery =
        "INSERT INTO \(TablePendingBookmarksDeletions) (id) VALUES " +
        "(?)"

        let pendingDeletionsArgs: Args = [
            "bookmark_to_delete"
        ]

        db.run([
            (sql: localQuery, args: localArgs),
            (sql: structureQuery, args: structureArgs),
            (sql: bufferQuery, args: bufferArgs),
            (sql: bufferStructureQuery, args: bufferStructureArgs),
            (sql: pendingDeletionsQuery, args: pendingDeletionsArgs),
        ]).succeeded()

        var modifications = bookmarks.getLocalBookmarksModifications(limit: 3).value.successValue!
        XCTAssertEqual(modifications.additions.count, 2)
        XCTAssertEqual(modifications.additions.map { $0.guid }, ["bookmark_good_nonsynced", "bookmark_good_additional"])
        XCTAssertEqual(modifications.deletions.count, 1)
        XCTAssertEqual(modifications.deletions, ["bookmark_to_delete"])

        // Deletions are prioritized.
        modifications = bookmarks.getLocalBookmarksModifications(limit: 1).value.successValue!
        XCTAssertEqual(modifications.additions.count, 0)
        XCTAssertEqual(modifications.deletions.count, 1)
        XCTAssertEqual(modifications.deletions, ["bookmark_to_delete"])
    }

    func testApplyRecordsRemovesPendingDeletions() {
        guard let db = getBrowserDB("TSQLBtestApplyRecordsPendingDeletions.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = MergedSQLiteBookmarks(db: db)

        let bufferQuery =
        "INSERT INTO \(TableBookmarksBuffer) (guid, type, bmkUri, title, parentid, parentName, server_modified) VALUES " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?) "

        let bufferArgs: Args = [
            "bkm1", "http://example.org/1", "Bookmark 1", BookmarkRoots.MobileFolderGUID, Date.now(),
            "bkm2", "http://example.org/2", "Bookmark 2", BookmarkRoots.MobileFolderGUID, Date.now()
        ]

        let bufferStructureQuery =
        "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES " +
        "(?, ?, ?), " +
        "(?, ?, ?)"

        let bufferStructureArgs: Args = [
            "bkm1", "bkm1", 0, // It's its own parent because we are lazy.
            "bkm2", "bkm2", 0
        ]

        let pendingDeletionsQuery =
        "INSERT INTO \(TablePendingBookmarksDeletions) (id) VALUES " +
        "(?)"

        let pendingDeletionsArgs: Args = [
            "bkm2"
        ]

        db.run([
            (sql: bufferQuery, args: bufferArgs),
            (sql: bufferStructureQuery, args: bufferStructureArgs),
            (sql: pendingDeletionsQuery, args: pendingDeletionsArgs),
        ]).succeeded()

        let modified: [BookmarkMirrorItem] = [BookmarkMirrorItem.bookmark("bkm2", dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: "bkm2", parentName: nil, title: "BKM 2", description: nil, URI: "https://test.com", tags: "", keyword: nil)]
        bookmarks.applyRecords(modified).succeeded()

        XCTAssertTrue(db.queryReturnsNoResults("SELECT * FROM \(TablePendingBookmarksDeletions)").value.successValue!)
    }

    func testApplyBufferUpdatedCompletionOp() {
        guard let db = getBrowserDB("TSQLBtestApplyBufferUpdatedCompletionOp.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarks(db: db)
        bookmarks.addToMobileBookmarks("http://example.org/1".asURL!, title: "Bookmark 1", favicon: nil).succeeded()
        bookmarks.addToMobileBookmarks("http://example.org/2".asURL!, title: "Bookmark 2", favicon: nil).succeeded()
        bookmarks.addToMobileBookmarks("http://example.org/3".asURL!, title: "Bookmark 3", favicon: nil).succeeded()
        bookmarks.addToMobileBookmarks("http://example.org/4".asURL!, title: "Bookmark 4", favicon: nil).succeeded()
        var localTree = bookmarks.treeForLocal().value.successValue!
        var mobileFolderNode = localTree.find(BookmarkRoots.MobileFolderGUID)!
        let localChildrenGUIDs = mobileFolderNode.children!.map { $0.recordGUID }
        XCTAssertEqual(localChildrenGUIDs.count, 4)
        let childrenGUIDsUploaded = localChildrenGUIDs.dropLast(1)
        let childrenGUIDsFailed = localChildrenGUIDs.dropFirst(3)

        let bufferQuery =
        "INSERT INTO \(TableBookmarksBuffer) (guid, type, bmkUri, title, parentid, parentName, server_modified) VALUES " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', ?) "

        let bkmBufModified = Date.now()
        let bufferArgs: Args = [
            BookmarkRoots.RootGUID, "", BookmarkRoots.RootGUID, 123,
            BookmarkRoots.MobileFolderGUID, "Mobile Bookmarks", BookmarkRoots.RootGUID, 456,
            "bkmbuf", "http://example.org/5", "Bookmark 5", BookmarkRoots.MobileFolderGUID, bkmBufModified,
            "bkmtodelete", "http://example.org/to_delete", "Bookmark to delete", BookmarkRoots.MobileFolderGUID, 88888,
            "bkmtodelete_uploadfail", "http://example.org/to_delete_updfail", "Bookmark to delete but upload failed", BookmarkRoots.MobileFolderGUID, 88888
        ]

        let bufferStructureQuery =
        "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?)"

        let bufferStructureArgs: Args = [
            BookmarkRoots.RootGUID, BookmarkRoots.RootGUID, 0,
            BookmarkRoots.RootGUID, BookmarkRoots.MobileFolderGUID, 0,
            BookmarkRoots.MobileFolderGUID, "bkmbuf", 0,
            BookmarkRoots.MobileFolderGUID, "bkmtodelete", 1,
            BookmarkRoots.MobileFolderGUID, "bkmtodelete_uploadfail", 2,
        ]

        let pendingDeletionsQuery =
        "INSERT INTO \(TablePendingBookmarksDeletions) (id) VALUES " +
        "(?), " +
        "(?)"

        let pendingDeletionsArgs: Args = [
            "bkmtodelete", "bkmtodelete_uploadfail"
        ]

        db.run([
            (sql: bufferQuery, args: bufferArgs),
            (sql: bufferStructureQuery, args: bufferStructureArgs),
            (sql: pendingDeletionsQuery, args: pendingDeletionsArgs),
            ]).succeeded()

        let mobileRoot = BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID,
                                                   parentName: nil, title: "Mobile Bookmarks", description: nil, children: ["bkmbuf"] + childrenGUIDsUploaded)
        let op = BufferUpdatedCompletionOp(bufferValuesToMoveFromLocal: Set(childrenGUIDsUploaded), deletedValues: Set(["bkmtodelete"]), mobileRoot: mobileRoot, modifiedTime: 123456)

        let mergedBookmarks = MergedSQLiteBookmarks(db: db)
        mergedBookmarks.applyBufferUpdatedCompletionOp(op).succeeded()

        let rootFolder = mergedBookmarks.getBufferItemWithGUID(BookmarkRoots.RootGUID).value.successValue!
        XCTAssertEqual(rootFolder.serverModified, 123)
        let mobileFolder = mergedBookmarks.getBufferItemWithGUID(BookmarkRoots.MobileFolderGUID).value.successValue!
        XCTAssertEqual(mobileFolder.serverModified, 123456)
        let childrenGUIDs = mergedBookmarks.getBufferChildrenGUIDsForParent(BookmarkRoots.MobileFolderGUID).value.successValue!
        XCTAssertEqual(childrenGUIDs, ["bkmbuf", "bkmtodelete_uploadfail"] + childrenGUIDsUploaded)
        let children = mergedBookmarks.getBufferItemsWithGUIDs(["bkmbuf"] + childrenGUIDsUploaded).value.successValue!
        for item in children.values {
            XCTAssertEqual(item.serverModified, item.guid == "bkmbuf" ? bkmBufModified : 123456)
        }
        localTree = bookmarks.treeForLocal().value.successValue!
        mobileFolderNode = localTree.find(BookmarkRoots.MobileFolderGUID)!
        XCTAssertEqual(mobileFolderNode.children!.map { $0.recordGUID }, Array(childrenGUIDsFailed))
    }

    fileprivate func createStockMirrorTree(_ db: BrowserDB) {
        // Set up a mirror tree.
        let mirrorQuery =
        "INSERT INTO \(TableBookmarksMirror) (guid, type, bmkUri, title, parentid, parentName, description, tags, keyword, is_overridden, server_modified, pos) " +
        "VALUES " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +

        "(?, \(BookmarkNodeType.separator.rawValue), NULL, NULL, ?, '', '', '', '', 0, \(Date.now()), 0), " +

        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL) "

        let mirrorArgs: Args = [
            "folderAAAAAA", "AAA", BookmarkRoots.ToolbarFolderGUID,
            "folderBBBBBB", "BBB", BookmarkRoots.MenuFolderGUID,
            "folderCCCCCC", "CCC", "folderBBBBBB",

            "separator101", "folderAAAAAA",

            "bookmark1001", "http://example.org/1", "Bookmark 1", "folderAAAAAA",
            "bookmark1002", "http://example.org/1", "Bookmark 1 Again", "folderAAAAAA",
            "bookmark2001", "http://example.org/2", "Bookmark 2", "folderAAAAAA",
            "bookmark2002", "http://example.org/2", "Bookmark 2 Again", "folderCCCCCC",
            "bookmark3001", "http://example.org/3", "Bookmark 3", "folderBBBBBB",
        ]

        let structureQuery =
        "INSERT INTO \(TableBookmarksMirrorStructure) (parent, child, idx) VALUES " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?), " +
        "(?, ?, ?) "

        let structureArgs: Args = [
            BookmarkRoots.ToolbarFolderGUID, "folderAAAAAA", 0,
            BookmarkRoots.MenuFolderGUID, "folderBBBBBB", 0,
            "folderAAAAAA", "bookmark1001", 0,
            "folderAAAAAA", "separator101", 1,
            "folderAAAAAA", "bookmark1002", 2,
            "folderAAAAAA", "bookmark2001", 3,
            "folderBBBBBB", "bookmark3001", 0,
            "folderBBBBBB", "folderCCCCCC", 1,
            "folderCCCCCC", "bookmark2002", 0,
        ]

        db.moveLocalToMirrorForTesting()   // So we have the roots.
        db.run([
            (sql: mirrorQuery, args: mirrorArgs),
            (sql: structureQuery, args: structureArgs),
        ]).succeeded()
    }

    fileprivate func isUnknown(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .unknown(let guid):
            XCTAssertEqual(withGUID, guid)
        default:
            XCTFail("Not an unknown with GUID \(withGUID).")
        }
    }

    fileprivate func isNonFolder(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .nonFolder(let guid):
            XCTAssertEqual(withGUID, guid)
        default:
            XCTFail("Not a non-folder with GUID \(withGUID).")
        }
    }

    fileprivate func isFolder(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .folder(let record):
            XCTAssertEqual(withGUID, record.guid)
        default:
            XCTFail("Not a folder with GUID \(withGUID).")
        }
    }

    fileprivate func areFolders(_ folders: [BookmarkTreeNode], withGUIDs: [GUID]) {
        folders.zip(withGUIDs).forEach { (node, guid) in
            self.isFolder(node, withGUID: guid)
        }
    }

    fileprivate func assertTreeIsEmpty(_ treeMaybe: Maybe<BookmarkTree>) {
        guard let tree = treeMaybe.successValue else {
            XCTFail("Couldn't get tree!")
            return
        }
        XCTAssertTrue(tree.orphans.isEmpty)
        XCTAssertTrue(tree.deleted.isEmpty)
        XCTAssertTrue(tree.isEmpty)
    }

    fileprivate func assertTreeContainsOnlyRoots(_ treeMaybe: Maybe<BookmarkTree>) {
        guard let tree = treeMaybe.successValue else {
            XCTFail("Couldn't get tree!")
            return
        }

        XCTAssertTrue(tree.orphans.isEmpty)
        XCTAssertTrue(tree.deleted.isEmpty)
        XCTAssertFalse(tree.isEmpty)
        XCTAssertEqual(1, tree.subtrees.count)
        if case let .folder(guid, children) = tree.subtrees[0] {
            XCTAssertEqual(guid, "root________")
            XCTAssertEqual(4, children.count)
            children.forEach { child in
                guard case let .folder(_, lower) = child, lower.isEmpty else {
                    XCTFail("Child \(child) wasn't empty!")
                    return
                }
            }
        } else {
            XCTFail("Tree didn't contain root.")
        }
    }

    func testUnrootedBufferRowsDontAppearInTrees() {
        guard let db = getBrowserDB("TSQLBtestUnrooted.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        let bookmarks = SQLiteBookmarks(db: db)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForMirror().value)
        self.assertTreeIsEmpty(bookmarks.treeForBuffer().value)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForLocal().value)

        let args: Args = [
            "unrooted0001", BookmarkNodeType.bookmark.rawValue, 0, "somefolder01", "Some Folder", "I have no folder", "http://example.org/",
            "rooted000002", BookmarkNodeType.bookmark.rawValue, 0, "somefolder02", "Some Other Folder", "I have a folder", "http://example.org/",
            "somefolder02", BookmarkNodeType.folder.rawValue, 0, BookmarkRoots.MobileFolderGUID, "Mobile Bookmarks", "Some Other Folder",
        ]
        let now = Date.now()
        let bufferSQL =
        "INSERT INTO \(TableBookmarksBuffer) (server_modified, guid, type, date_added, is_deleted, parentid, parentName, title, bmkUri) VALUES " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, NULL)"

        let bufferStructureSQL = "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES ('somefolder02', 'rooted000002', 0)"
        db.run(bufferSQL, withArgs: args).succeeded()
        db.run(bufferStructureSQL).succeeded()

        let tree = bookmarks.treeForBuffer().value.successValue!
        XCTAssertFalse(tree.orphans.contains("somefolder02"))        // Folders are never orphans; they appear in subtrees instead.
        XCTAssertFalse(tree.orphans.contains("rooted000002"))        // This tree contains its parent, so it's not an orphan.
        XCTAssertTrue(tree.orphans.contains("unrooted0001"))
        XCTAssertEqual(Set(tree.subtrees.map { $0.recordGUID }), Set(["somefolder02"]))
    }

    func testTreeBuilding() {
        guard let db = getBrowserDB("TSQLBtestTreeBuilding.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        let bookmarks = SQLiteBookmarks(db: db)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForMirror().value)
        self.assertTreeIsEmpty(bookmarks.treeForBuffer().value)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForLocal().value)

        self.createStockMirrorTree(db)
        self.assertTreeIsEmpty(bookmarks.treeForBuffer().value)

        // Local was emptied when we moved the roots to the mirror.
        self.assertTreeIsEmpty(bookmarks.treeForLocal().value)

        guard let tree = bookmarks.treeForMirror().value.successValue else {
            XCTFail("Couldn't get tree!")
            return
        }

        // Mirror is no longer empty.
        XCTAssertFalse(tree.isEmpty)

        // There's one root.
        XCTAssertEqual(1, tree.subtrees.count)
        if case let .folder(guid, children) = tree.subtrees[0] {
            XCTAssertEqual("root________", guid)
            XCTAssertEqual(4, children.count)
            self.areFolders(children, withGUIDs: BookmarkRoots.RootChildren)
        } else {
            XCTFail("Root should be a folder.")
        }

        // Every GUID is in the tree's nodes.
        ["folderAAAAAA",
         "folderBBBBBB",
         "folderCCCCCC"].forEach {
            isFolder(tree.lookup[$0]!, withGUID: $0)
        }

        ["separator101",
         "bookmark1001",
         "bookmark1002",
         "bookmark2001",
         "bookmark2002",
         "bookmark3001"].forEach {
            isNonFolder(tree.lookup[$0]!, withGUID: $0)
        }

        let expectedCount =
        BookmarkRoots.RootChildren.count + 1 +  // The roots.
        6 +          // Non-folders.
        3            // Folders.

        XCTAssertEqual(expectedCount, tree.lookup.count)

        // There are no orphans and no deletions.
        XCTAssertTrue(tree.orphans.isEmpty)
        XCTAssertTrue(tree.deleted.isEmpty)

        // root________
        //   menu________
        //     folderBBBBBB
        //       bookmark3001
        if case let .folder(guidR, rootChildren) = tree.subtrees[0] {
            XCTAssertEqual(guidR, "root________")
            if case let .folder(guidM, menuChildren) = rootChildren[0] {
                XCTAssertEqual(guidM, "menu________")
                if case let .folder(guidB, bbbChildren) = menuChildren[0] {
                    XCTAssertEqual(guidB, "folderBBBBBB")
                    // BBB contains bookmark3001.
                    if case let .nonFolder(guidBM) = bbbChildren[0] {
                        XCTAssertEqual(guidBM, "bookmark3001")
                    } else {
                        XCTFail("First child of BBB should be bookmark3001.")
                    }

                    // BBB contains folderCCCCCC.
                    if case let .folder(guidBF, _) = bbbChildren[1] {
                        XCTAssertEqual(guidBF, "folderCCCCCC")
                    } else {
                        XCTFail("Second child of BBB should be folderCCCCCC.")
                    }
                } else {
                    XCTFail("First child of menu should be BBB.")
                }
            } else {
                XCTFail("First child of root should be menu________")
            }
        } else {
            XCTFail("First root should be root________")
        }

        // Add a bookmark. It'll override the folder.
        bookmarks.insertBookmark("https://foo.com/".asURL!, title: "Foo", favicon: nil, intoFolder: "folderBBBBBB", withTitle: "BBB").succeeded()
        let newlyInserted = db.getRecordByURL("https://foo.com/", fromTable: TableBookmarksLocal).guid

        guard let local = bookmarks.treeForLocal().value.successValue else {
            XCTFail("Couldn't get local tree!")
            return
        }

        XCTAssertFalse(local.isEmpty)
        XCTAssertEqual(4, local.lookup.count)   // Folder, new bookmark, original two children.
        XCTAssertEqual(1, local.subtrees.count)
        if case let .folder(guid, children) = local.subtrees[0] {
            XCTAssertEqual("folderBBBBBB", guid)

            // We have shadows of the original two children.
            XCTAssertEqual(3, children.count)
            self.isUnknown(children[0], withGUID: "bookmark3001")
            self.isUnknown(children[1], withGUID: "folderCCCCCC")
            self.isNonFolder(children[2], withGUID: newlyInserted)
        } else {
            XCTFail("Root should be folderBBBBBB.")
        }

        // Insert partial data into the buffer.
        // We insert:
        let bufferArgs: Args = [
            // * A folder whose parent isn't present in the structure.
            "ihavenoparent", BookmarkNodeType.folder.rawValue, 0, "myparentnoexist", "No Exist", "No Parent",
            // * A folder with no children.
            "ihavenochildren", BookmarkNodeType.folder.rawValue, 0, "ihavenoparent", "No Parent", "No Children",
            // * A folder that meets both criteria.
            "xhavenoparent", BookmarkNodeType.folder.rawValue, 0, "myparentnoexist", "No Exist", "No Parent And No Children",
            // * A changed bookmark with no parent.
            "changedbookmark", BookmarkNodeType.bookmark.rawValue, 0, "folderCCCCCC", "CCC", "I changed", "http://change.org/",
            // * A deleted record.
            "iwasdeleted", BookmarkNodeType.bookmark.rawValue,
        ]

        let now = Date.now()
        let bufferSQL = "INSERT INTO \(TableBookmarksBuffer) (server_modified, guid, type, date_added, is_deleted, parentid, parentName, title, bmkUri) VALUES " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, \(now), ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, \(now), 1, NULL, NULL, NULL, NULL) "

        let bufferStructureSQL = "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES (?, ?, ?)"
        let bufferStructureArgs: Args = ["ihavenoparent", "ihavenochildren", 0]
        db.run([(bufferSQL, bufferArgs), (bufferStructureSQL, bufferStructureArgs)]).succeeded()

        // Now build the tree.
        guard let partialBuffer = bookmarks.treeForBuffer().value.successValue else {
            XCTFail("Couldn't get buffer tree!")
            return
        }

        XCTAssertEqual(partialBuffer.deleted, Set<GUID>(["iwasdeleted"]))
        XCTAssertEqual(partialBuffer.orphans, Set<GUID>(["changedbookmark"]))
        XCTAssertEqual(partialBuffer.subtreeGUIDs, Set<GUID>(["ihavenoparent", "xhavenoparent"]))
        if case let .folder(_, children) = partialBuffer.lookup["ihavenochildren"]! {
            XCTAssertTrue(children.isEmpty)
        } else {
            XCTFail("Couldn't look up childless folder.")
        }
    }

    func testRecursiveAndURLDelete() {
        guard let db = getBrowserDB("TSQLBtestRecursiveAndURLDelete.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        let bookmarks = SQLiteBookmarks(db: db)
        self.createStockMirrorTree(db)

        let menuOverridden = BookmarkRoots.MenuFolderGUID
        XCTAssertFalse(db.isOverridden(menuOverridden) ?? true)

        func getMenuChildren() -> [GUID] {
            return db.getChildrenOfFolder(BookmarkRoots.MenuFolderGUID)
        }

        XCTAssertEqual(["folderBBBBBB"], getMenuChildren())

        // Locally add an item to the menu. This'll override the menu folder.
        bookmarks.insertBookmark(URL(string: "http://example.com/2")!, title: "Bookmark 2 added locally", favicon: nil, intoFolder: BookmarkRoots.MenuFolderGUID, withTitle: "Bookmarks Menu").succeeded()

        XCTAssertTrue(db.isOverridden(BookmarkRoots.MenuFolderGUID) ?? false)

        let menuChildrenBeforeRecursiveDelete = getMenuChildren()
        XCTAssertEqual(2, menuChildrenBeforeRecursiveDelete.count)
        XCTAssertEqual("folderBBBBBB", menuChildrenBeforeRecursiveDelete[0])

        let locallyAddedBookmark2 = menuChildrenBeforeRecursiveDelete[1]

        // It's local, so it's not overridden.
        // N.B., these tests all use XCTAssertEqual instead of XCTAssert{True,False} because
        // the former plays well with optionals.
        XCTAssertNil(db.isOverridden(locallyAddedBookmark2))
        XCTAssertEqual(false, db.isLocallyDeleted(locallyAddedBookmark2))

        // Now let's delete folder B and check that things that weren't deleted now are.
        XCTAssertEqual(false, db.isOverridden("folderBBBBBB"))
        XCTAssertNil(db.isLocallyDeleted("folderBBBBBB"))
        XCTAssertEqual(false, db.isOverridden("folderCCCCCC"))
        XCTAssertNil(db.isLocallyDeleted("folderCCCCCC"))
        XCTAssertEqual(false, db.isOverridden("bookmark2002"))
        XCTAssertNil(db.isLocallyDeleted("bookmark2002"))
        XCTAssertEqual(false, db.isOverridden("bookmark3001"))
        XCTAssertNil(db.isLocallyDeleted("bookmark3001"))

        bookmarks.testFactory.removeByGUID("folderBBBBBB").succeeded()

        XCTAssertEqual(true, db.isOverridden("folderBBBBBB"))
        XCTAssertEqual(true, db.isLocallyDeleted("folderBBBBBB"))
        XCTAssertEqual(true, db.isOverridden("folderCCCCCC"))
        XCTAssertEqual(true, db.isLocallyDeleted("folderCCCCCC"))
        XCTAssertEqual(true, db.isOverridden("bookmark2002"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark2002"))
        XCTAssertEqual(true, db.isOverridden("bookmark3001"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark3001"))

        // Still there.
        XCTAssertNil(db.isOverridden(locallyAddedBookmark2))
        XCTAssertFalse(db.isLocallyDeleted(locallyAddedBookmark2) ?? true)

        let menuChildrenAfterRecursiveDelete = getMenuChildren()
        XCTAssertEqual(1, menuChildrenAfterRecursiveDelete.count)
        XCTAssertEqual(locallyAddedBookmark2, menuChildrenAfterRecursiveDelete[0])

        // Now let's delete by URL.
        XCTAssertEqual(false, db.isOverridden("bookmark1001"))
        XCTAssertNil(db.isLocallyDeleted("bookmark1001"))
        XCTAssertEqual(false, db.isOverridden("bookmark1002"))
        XCTAssertNil(db.isLocallyDeleted("bookmark1002"))

        bookmarks.testFactory.removeByURL("http://example.org/1").succeeded()

        // To conclude, check the entire hierarchy.
        // Menu: overridden, only the locally-added bookmark 2.
        // B, 3001, C, 2002: locally deleted.
        // A: overridden, children [separator101, 2001].
        // No bookmarks with URL /1.
        XCTAssertEqual(true, db.isOverridden(BookmarkRoots.MenuFolderGUID))
        XCTAssertEqual(true, db.isOverridden("folderBBBBBB"))
        XCTAssertEqual(true, db.isLocallyDeleted("folderBBBBBB"))
        XCTAssertEqual(true, db.isOverridden("folderCCCCCC"))
        XCTAssertEqual(true, db.isLocallyDeleted("folderCCCCCC"))
        XCTAssertEqual(true, db.isOverridden("bookmark2002"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark2002"))
        XCTAssertEqual(true, db.isOverridden("bookmark3001"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark3001"))
        XCTAssertEqual(true, db.isOverridden("bookmark1001"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark1001"))
        XCTAssertEqual(true, db.isOverridden("bookmark1002"))
        XCTAssertEqual(true, db.isLocallyDeleted("bookmark1002"))

        let menuChildrenAfterURLDelete = getMenuChildren()
        XCTAssertEqual(1, menuChildrenAfterURLDelete.count)
        XCTAssertEqual(locallyAddedBookmark2, menuChildrenAfterURLDelete[0])

        XCTAssertEqual(["separator101", "bookmark2001"], db.getChildrenOfFolder("folderAAAAAA"))
    }

    func testLocalAndMirror() {
        guard let db = getBrowserDB("TSQLBtestLocalAndMirror.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        // Preconditions.
        let rootGUIDs = [
            BookmarkRoots.RootGUID,
            BookmarkRoots.MobileFolderGUID,
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,
        ]

        let positioned = [
            BookmarkRoots.MenuFolderGUID,
            BookmarkRoots.ToolbarFolderGUID,
            BookmarkRoots.UnfiledFolderGUID,
            BookmarkRoots.MobileFolderGUID,
        ]

        XCTAssertEqual(rootGUIDs, db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual(positioned, db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) ORDER BY idx"))
        XCTAssertEqual([], db.getGUIDs("SELECT guid FROM \(TableBookmarksMirror)"))
        XCTAssertEqual([], db.getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure)"))

        // Add a local bookmark.
        let bookmarks = SQLiteBookmarks(db: db)
        bookmarks.insertBookmark("http://example.org/".asURL!, title: "Example", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "The Mobile").succeeded()

        let rowA = db.getRecordByURL("http://example.org/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowA.bookmarkURI, "http://example.org/")
        XCTAssertEqual(rowA.title, "Example")
        XCTAssertEqual(rowA.parentName, "The Mobile")
        XCTAssertEqual(rootGUIDs + [rowA.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.new, db.getSyncStatusForGUID(rowA.guid))

        // Add another. Order should be maintained.
        bookmarks.insertBookmark("https://reddit.com/".asURL!, title: "Reddit", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()

        let rowB = db.getRecordByURL("https://reddit.com/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowB.bookmarkURI, "https://reddit.com/")
        XCTAssertEqual(rowB.title, "Reddit")
        XCTAssertEqual(rootGUIDs + [rowA.guid, rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid, rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.new, db.getSyncStatusForGUID(rowA.guid))
        XCTAssertEqual(SyncStatus.new, db.getSyncStatusForGUID(rowB.guid))

        // The indices should be 0, 1.
        let positions = db.getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positions.count, 2)
        XCTAssertEqual(positions[rowA.guid], 0)
        XCTAssertEqual(positions[rowB.guid], 1)

        // Delete the first. sync_status was New, so the row was immediately deleted.
        bookmarks.testFactory.removeByURL("http://example.org/").succeeded()
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let positionsAfterDelete = db.getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positionsAfterDelete.count, 1)
        XCTAssertEqual(positionsAfterDelete[rowB.guid], 0)

        // Manually shuffle all of these into the mirror, as if we were fully synchronized.
        db.moveLocalToMirrorForTesting()
        XCTAssertEqual([], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure)"))
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let mirrorPositions = db.getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksMirrorStructure)
        XCTAssertEqual(mirrorPositions.count, 1)
        XCTAssertEqual(mirrorPositions[rowB.guid], 0)

        // Now insert a new mobile bookmark.
        bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()

        // The mobile bookmarks folder is overridden.
        XCTAssertEqual(true, db.isOverridden(BookmarkRoots.MobileFolderGUID))

        // Our previous inserted bookmark is not.
        XCTAssertEqual(false, db.isOverridden(rowB.guid))

        let rowC = db.getRecordByURL("https://letsencrypt.org/", fromTable: TableBookmarksLocal)

        // We have the old structure in the mirror.
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // We have the new structure in the local table.
        XCTAssertEqual(Set([BookmarkRoots.MobileFolderGUID, rowC.guid]), Set(db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id")))
        XCTAssertEqual([rowB.guid, rowC.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Parent is changed. The new record is New. The unmodified and deleted records aren't present.
        XCTAssertNil(db.getSyncStatusForGUID(rowA.guid))
        XCTAssertNil(db.getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual(SyncStatus.new, db.getSyncStatusForGUID(rowC.guid))
        XCTAssertEqual(SyncStatus.changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // If we delete the old record, we mark it as changed, and it's no longer in the structure.
        bookmarks.testFactory.removeByGUID(rowB.guid).succeeded()
        XCTAssertEqual(SyncStatus.changed, db.getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual([rowC.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Add a duplicate to test multi-deletion (unstar).
        bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()
        let guidD = db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx").last!
        XCTAssertNotEqual(rowC.guid, guidD)
        XCTAssertEqual(SyncStatus.new, db.getSyncStatusForGUID(guidD))
        XCTAssertEqual(SyncStatus.changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // Delete by URL.
        // If we delete the new records, they just go away -- there's no server version to delete.
        bookmarks.testFactory.removeByURL(rowC.bookmarkURI!).succeeded()
        XCTAssertNil(db.getSyncStatusForGUID(rowC.guid))
        XCTAssertNil(db.getSyncStatusForGUID(guidD))
        XCTAssertEqual([], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // The mirror structure is unchanged after all this.
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
    }

    /*
    // This is dead test code after we eliminated the merged view.
    // Expect this to be ported to reflect post-sync state.
    func testBookmarkStructure() {
        guard let db = getBrowserDB("TSQLBtestBufferStorage.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = MergedSQLiteBookmarks(db: db)

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

        let del: [BookmarkMirrorItem] = [BookmarkMirrorItem.deleted(BookmarkNodeType.Bookmark, guid: "aaaaaaaaaaaa", modified: Date.now())]
        bookmarks.applyRecords(del, withMaxVars: 1)

        guard let newToolbar = bookmarks.modelForFolder(BookmarkRoots.ToolbarFolderGUID).value.successValue else {
            XCTFail("Unable to get toolbar.")
            return
        }
        XCTAssertEqual(newToolbar.current.count, 1)
        XCTAssertEqual(newToolbar.current[0]?.guid, "bbbbbbbbbbbb")
    }
    */

    func testBufferStorage() {
        guard let db = getBrowserDB("TSQLBtestBufferStorage.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarkBufferStorage(db: db)

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.bookmark("bbbbbbbbbbbb", dateAdded: Date.now(), modified: Date.now() + 10, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "BBB", description: "BBB desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let toolbar = BookmarkMirrorItem.folder("toolbar", dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]
        bookmarks.applyRecords(recordsA, withMaxVars: 3).succeeded()

        // Insert mobile bookmarks as produced by Firefox 40-something on desktop.
        // swiftlint:disable line_length

        let children = ["M87np9Vfh_2s", "-JxRyqNte-ue", "6lIQzUtbjE8O", "eOg3jPSslzXl", "1WJIi9EjQErp", "z5uRo45Rvfbd", "EK3lcNd0sUFN", "gFD3GTljgu12", "eRZGsbN1ew9-", "widfEdgGn9de", "l7eTOR4Uf6xq", "vPbxG-gpN4Rb", "4dwJ8CototFe", "zK-kw9Ii6ScW", "eDmDU-gtEFW6", "lKjqWQaL_syt", "ETVDvWgGT31Q", "3Z_bMIHPSZQ8", "Fqu4_bJOk7fT", "Uo_5K1QrA67j", "gDTXNg4m1AJZ", "zpds8P-9xews", "87zjNtVGPtEp", "ZJru8Sn3qhW7", "txVnzBBBOgLP", "JTnRqFaj_oNa", "soaMlfmM4kjR", "g8AcVBjo6IRf", "uPUDaiG4q637", "rfq2bUud_w4d", "XBGxsiuUG2UD", "-VQRnJlyAvMs", "6wu7TScKdTU7", "ZeFji2hLVpLj", "HpCn_TVizMWX", "IPR5HZwRdlwi", "00JFOGuWnhWB", "P1jb3qKt32Vg", "D6MQJ43V1Ir5", "qWSoXFteRfsq", "o2avfYqEdomL", "xRS0U0YnjK9G", "VgOgzE_xfP4w", "SwP3rMJGvoO3", "Hf2jEgI_-PWa", "AyhmBi7Cv598", "-PaMuzTJXxVk", "JMhYrg8SlY5K", "SQeySEjzyplL", "GTAwd2UkEQEe", "x3RsZj5Ilebr", "sRZWZqPi74FP", "amHR50TpygA6", "XSk782ceVNN6", "ipiMyYQzeypI", "ph2k3Nqfhau4", "m5JKC3hAEQ0H", "yTVerkmQbNxk", "7taA6FbbbUbH", "PZvpbSRuJLPs", "C8atoa25U94F", "KOfNJk_ISLc6", "Bt74lBG9tJq6", "BuHoY2rUhuKA", "XTmoWKnwfIPl", "ZATwa3oTD1m0", "e8TczN5It6Am", "6kCUYs8hQtKg", "jDD8s5aiKoex", "QmpmcrYwLU29", "nCRcekynuJ08", "resttaI4J9tu", "EKSX3HV55VU3", "2-yCz0EIsVls", "sSeeGw3VbBY-", "qfpCrU34w9y0", "RKDgzPWecD6m", "5SgXEKu_dICW", "R143WAeB5E5r", "8Ns4-NiKG62r", "4AHuZDvop5XX", "YCP1OsO1goFF", "CYYaU1mQ_N6t", "UGkzEOMK8cuU", "1RzZOarkzQBa", "qSW2Z3cZSI9c", "ooPlKEAfQsnn", "jIUScoKLiXQt", "bjNTKugzRRL1", "hR24ZVnHUZcs", "3j2IDAZgUyYi", "xnWcy-sQDJRu", "UCcgJqGk3bTV", "WSSRWeptH9tq", "4ugv47OGD2E2", "XboCZgUx-x3x", "HrmWqiqsuLrm", "OjdxvRJ3Jb6j"]
        // swiftlint:enable line_length

        let mA = BookmarkMirrorItem.bookmark("jIUScoKLiXQt", dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: "mobile", parentName: "mobile", title: "Join the Engineering Leisure Class — Medium", description: nil, URI: "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e", tags: "[]", keyword: nil)

        let mB = BookmarkMirrorItem.folder("UjAHxFOGEqU8", dateAdded: Date.now(), modified: Date.now(), hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: children)
        bookmarks.applyRecords([mA, mB]).succeeded()

        func childCount(_ parent: GUID) -> Int? {
            let sql = "SELECT COUNT(*) AS childCount FROM \(TableBookmarksBufferStructure) WHERE parent = ?"
            let args: Args = [parent]
            return db.runQuery(sql, args: args, factory: { $0["childCount"] as! Int }).value.successValue?[0]
        }

        // We have children.
        XCTAssertEqual(children.count, childCount("UjAHxFOGEqU8"))

        // Insert an empty mobile bookmarks folder, so we can verify that the structure table is wiped.
        let mBEmpty = BookmarkMirrorItem.folder("UjAHxFOGEqU8", dateAdded: Date.now(), modified: Date.now() + 1, hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: [])
        bookmarks.applyRecords([mBEmpty]).succeeded()

        // We no longer have children.
        XCTAssertEqual(0, childCount("UjAHxFOGEqU8"))
    }
}
