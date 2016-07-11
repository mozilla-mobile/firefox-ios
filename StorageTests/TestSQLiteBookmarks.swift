/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest

private func getBrowserDB(_ filename: String, files: FileAccessor) -> BrowserDB? {
    let db = BrowserDB(filename: filename, files: files)

    // BrowserTable exists only to perform create/update etc. operations -- it's not
    // a queryable thing that needs to stick around.
    if !db.createOrUpdate(BrowserTable()) {
        return nil
    }
    return db
}

extension SQLiteBookmarks {
    var testFactory: SQLiteBookmarksModelFactory {
        return SQLiteBookmarksModelFactory(bookmarks: self, direction: .Local)
    }
}

// MARK: - Tests.

class TestSQLiteBookmarks: XCTestCase {
    let files = MockFiles()

    private func remove(_ path: String) {
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
        super.tearDown()
    }

    func testBookmarks() {
        guard let db = getBrowserDB(filename: "TSQLBtestBookmarks.db", files: self.files) else {
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
        factory.remove(byURL: "").succeeded()

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

    private func createStockMirrorTree(_ db: BrowserDB) {
        // Set up a mirror tree.
        let mirrorQuery =
        "INSERT INTO \(TableBookmarksMirror) (guid, type, bmkUri, title, parentid, parentName, description, tags, keyword, is_overridden, server_modified, pos) " +
        "VALUES " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +

        "(?, \(BookmarkNodeType.Separator.rawValue), NULL, NULL, ?, '', '', '', '', 0, \(Date.now()), 0), " +

        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(Date.now()), NULL) "

        let mirrorArgs: Args = [
            "folderAAAAAA", "AAA", BookmarkRoots.ToolbarFolderGUID,
            "folderBBBBBB", "BBB", BookmarkRoots.MenuFolderGUID,
            "folderCCCCCC", "CCC", "folderBBBBBB",

            "separator101", "folderAAAAAA",

            "bookmark1001", "http://example.org/1", "Bookmark 1",       "folderAAAAAA",
            "bookmark1002", "http://example.org/1", "Bookmark 1 Again", "folderAAAAAA",
            "bookmark2001", "http://example.org/2", "Bookmark 2",       "folderAAAAAA",
            "bookmark2002", "http://example.org/2", "Bookmark 2 Again", "folderCCCCCC",
            "bookmark3001", "http://example.org/3", "Bookmark 3",       "folderBBBBBB",
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

    private func isUnknown(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .Unknown(let guid):
            XCTAssertEqual(withGUID, guid)
        default:
            XCTFail("Not an unknown with GUID \(withGUID).")
        }
    }

    private func isNonFolder(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .NonFolder(let guid):
            XCTAssertEqual(withGUID, guid)
        default:
            XCTFail("Not a non-folder with GUID \(withGUID).")
        }
    }

    private func isFolder(_ folder: BookmarkTreeNode, withGUID: GUID) {
        switch folder {
        case .Folder(let record):
            XCTAssertEqual(withGUID, record.guid)
        default:
            XCTFail("Not a folder with GUID \(withGUID).")
        }
    }

    private func areFolders(_ folders: [BookmarkTreeNode], withGUIDs: [GUID]) {
        folders.zip(withGUIDs).forEach { (node, guid) in
            self.isFolder(node, withGUID: guid)
        }
    }

    private func assertTreeIsEmpty(_ treeMaybe: Maybe<BookmarkTree>) {
        guard let tree = treeMaybe.successValue else {
            XCTFail("Couldn't get tree!")
            return
        }
        XCTAssertTrue(tree.orphans.isEmpty)
        XCTAssertTrue(tree.deleted.isEmpty)
        XCTAssertTrue(tree.isEmpty)
    }

    private func assertTreeContainsOnlyRoots(_ treeMaybe: Maybe<BookmarkTree>) {
        guard let tree = treeMaybe.successValue else {
            XCTFail("Couldn't get tree!")
            return
        }

        XCTAssertTrue(tree.orphans.isEmpty)
        XCTAssertTrue(tree.deleted.isEmpty)
        XCTAssertFalse(tree.isEmpty)
        XCTAssertEqual(1, tree.subtrees.count)
        if case let .Folder(guid, children) = tree.subtrees[0] {
            XCTAssertEqual(guid, "root________")
            XCTAssertEqual(4, children.count)
            children.forEach { child in
                guard case let .Folder(_, lower) = child where lower.isEmpty else {
                    XCTFail("Child \(child) wasn't empty!")
                    return
                }
            }
        } else {
            XCTFail("Tree didn't contain root.")
        }
    }

    func testUnrootedBufferRowsDontAppearInTrees() {
        guard let db = getBrowserDB(filename: "TSQLBtestUnrooted.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        let bookmarks = SQLiteBookmarks(db: db)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForMirror().value)
        self.assertTreeIsEmpty(bookmarks.treeForBuffer().value)
        self.assertTreeContainsOnlyRoots(bookmarks.treeForLocal().value)

        let args: Args = [
            "unrooted0001", BookmarkNodeType.Bookmark.rawValue, 0, "somefolder01", "Some Folder", "I have no folder", "http://example.org/",
            "rooted000002", BookmarkNodeType.Bookmark.rawValue, 0, "somefolder02", "Some Other Folder", "I have a folder", "http://example.org/",
            "somefolder02", BookmarkNodeType.Folder.rawValue, 0, BookmarkRoots.MobileFolderGUID, "Mobile Bookmarks", "Some Other Folder",
        ]
        let now = Date.now()
        let bufferSQL =
        "INSERT INTO \(TableBookmarksBuffer) (server_modified, guid, type, is_deleted, parentid, parentName, title, bmkUri) VALUES " +
        "(\(now), ?, ?, ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, ?, ?, ?, ?, NULL)"

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
        guard let db = getBrowserDB(filename: "TSQLBtestTreeBuilding.db", files: self.files) else {
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
        if case let .Folder(guid, children) = tree.subtrees[0] {
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
        if case let .Folder(guidR, rootChildren) = tree.subtrees[0] {
            XCTAssertEqual(guidR, "root________")
            if case let .Folder(guidM, menuChildren) = rootChildren[0] {
                XCTAssertEqual(guidM, "menu________")
                if case let .Folder(guidB, bbbChildren) = menuChildren[0] {
                    XCTAssertEqual(guidB, "folderBBBBBB")
                    // BBB contains bookmark3001.
                    if case let .NonFolder(guidBM) = bbbChildren[0] {
                        XCTAssertEqual(guidBM, "bookmark3001")
                    } else {
                        XCTFail("First child of BBB should be bookmark3001.")
                    }

                    // BBB contains folderCCCCCC.
                    if case let .Folder(guidBF, _) = bbbChildren[1] {
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
        if case let .Folder(guid, children) = local.subtrees[0] {
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
            "ihavenoparent", BookmarkNodeType.Folder.rawValue, 0, "myparentnoexist", "No Exist", "No Parent",
            // * A folder with no children.
            "ihavenochildren", BookmarkNodeType.Folder.rawValue, 0, "ihavenoparent", "No Parent", "No Children",
            // * A folder that meets both criteria.
            "xhavenoparent", BookmarkNodeType.Folder.rawValue, 0, "myparentnoexist", "No Exist", "No Parent And No Children",
            // * A changed bookmark with no parent.
            "changedbookmark", BookmarkNodeType.Bookmark.rawValue, 0, "folderCCCCCC", "CCC", "I changed", "http://change.org/",
            // * A deleted record.
            "iwasdeleted", BookmarkNodeType.Bookmark.rawValue,
        ]

        let now = Date.now()
        let bufferSQL = "INSERT INTO \(TableBookmarksBuffer) (server_modified, guid, type, is_deleted, parentid, parentName, title, bmkUri) VALUES " +
        "(\(now), ?, ?, ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, ?, ?, ?, ?, NULL), " +
        "(\(now), ?, ?, ?, ?, ?, ?, ?), " +
        "(\(now), ?, ?, 1, NULL, NULL, NULL, NULL) "

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
        if case let .Folder(_, children) = partialBuffer.lookup["ihavenochildren"]! {
            XCTAssertTrue(children.isEmpty)
        } else {
            XCTFail("Couldn't look up childless folder.")
        }
    }

    func testRecursiveAndURLDelete() {
        guard let db = getBrowserDB(filename: "TSQLBtestRecursiveAndURLDelete.db", files: self.files) else {
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

        bookmarks.testFactory.remove(byGUID: "folderBBBBBB").succeeded()

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

        bookmarks.testFactory.remove(byURL: "http://example.org/1").succeeded()

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
        guard let db = getBrowserDB(filename: "TSQLBtestLocalAndMirror.db", files: self.files) else {
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

        XCTAssertEqual(rootGUIDs, db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual(positioned, db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) ORDER BY idx"))
        XCTAssertEqual([], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksMirror)"))
        XCTAssertEqual([], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksMirrorStructure)"))

        // Add a local bookmark.
        let bookmarks = SQLiteBookmarks(db: db)
        bookmarks.insertBookmark("http://example.org/".asURL!, title: "Example", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "The Mobile").succeeded()

        let rowA = db.getRecordByURL("http://example.org/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowA.bookmarkURI, "http://example.org/")
        XCTAssertEqual(rowA.title, "Example")
        XCTAssertEqual(rowA.parentName, "The Mobile")
        XCTAssertEqual(rootGUIDs + [rowA.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowA.guid))

        // Add another. Order should be maintained.
        bookmarks.insertBookmark("https://reddit.com/".asURL!, title: "Reddit", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()

        let rowB = db.getRecordByURL("https://reddit.com/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowB.bookmarkURI, "https://reddit.com/")
        XCTAssertEqual(rowB.title, "Reddit")
        XCTAssertEqual(rootGUIDs + [rowA.guid, rowB.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid, rowB.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowA.guid))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowB.guid))

        // The indices should be 0, 1.
        let positions = db.getPositionsForChildren(ofParent: BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positions.count, 2)
        XCTAssertEqual(positions[rowA.guid], 0)
        XCTAssertEqual(positions[rowB.guid], 1)

        // Delete the first. sync_status was New, so the row was immediately deleted.
        bookmarks.testFactory.remove(byURL: "http://example.org/").succeeded()
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let positionsAfterDelete = db.getPositionsForChildren(ofParent: BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positionsAfterDelete.count, 1)
        XCTAssertEqual(positionsAfterDelete[rowB.guid], 0)

        // Manually shuffle all of these into the mirror, as if we were fully synchronized.
        db.moveLocalToMirrorForTesting()
        XCTAssertEqual([], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure)"))
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let mirrorPositions = db.getPositionsForChildren(ofParent: BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksMirrorStructure)
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
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // We have the new structure in the local table.
        XCTAssertEqual(Set([BookmarkRoots.MobileFolderGUID, rowC.guid]), Set(db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksLocal) ORDER BY id")))
        XCTAssertEqual([rowB.guid, rowC.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Parent is changed. The new record is New. The unmodified and deleted records aren't present.
        XCTAssertNil(db.getSyncStatusForGUID(rowA.guid))
        XCTAssertNil(db.getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowC.guid))
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // If we delete the old record, we mark it as changed, and it's no longer in the structure.
        bookmarks.testFactory.remove(byGUID: rowB.guid).succeeded()
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual([rowC.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Add a duplicate to test multi-deletion (unstar).
        bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()
        let guidD = db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx").last!
        XCTAssertNotEqual(rowC.guid, guidD)
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(guidD))
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // Delete by URL.
        // If we delete the new records, they just go away -- there's no server version to delete.
        bookmarks.testFactory.remove(byURL: rowC.bookmarkURI!).succeeded()
        XCTAssertNil(db.getSyncStatusForGUID(rowC.guid))
        XCTAssertNil(db.getSyncStatusForGUID(guidD))
        XCTAssertEqual([], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // The mirror structure is unchanged after all this.
        XCTAssertEqual(rootGUIDs + [rowB.guid], db.getGUIDs(sql: "SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], db.getGUIDs(sql: "SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
    }

    /*
    // This is dead test code after we eliminated the merged view.
    // Expect this to be ported to reflect post-sync state.
    func testBookmarkStructure() {
        guard let db = getBrowserDB(filename: "TSQLBtestBufferStorage.db", files: self.files) else {
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

        let del: [BookmarkMirrorItem] = [BookmarkMirrorItem.deleted(BookmarkNodeType.Bookmark, guid: "aaaaaaaaaaaa", modified: NSDate.now())]
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
        guard let db = getBrowserDB(filename: "TSQLBtestBufferStorage.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarkBufferStorage(db: db)

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.bookmark("bbbbbbbbbbbb", modified: Date.now() + 10, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "BBB", description: "BBB desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let toolbar = BookmarkMirrorItem.folder("toolbar", modified: Date.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]
        bookmarks.applyRecords(recordsA, withMaxVars: 3).succeeded()

        // Insert mobile bookmarks as produced by Firefox 40-something on desktop.

        let children = ["M87np9Vfh_2s","-JxRyqNte-ue","6lIQzUtbjE8O","eOg3jPSslzXl","1WJIi9EjQErp","z5uRo45Rvfbd","EK3lcNd0sUFN","gFD3GTljgu12","eRZGsbN1ew9-","widfEdgGn9de","l7eTOR4Uf6xq","vPbxG-gpN4Rb","4dwJ8CototFe","zK-kw9Ii6ScW","eDmDU-gtEFW6","lKjqWQaL_syt","ETVDvWgGT31Q","3Z_bMIHPSZQ8","Fqu4_bJOk7fT","Uo_5K1QrA67j","gDTXNg4m1AJZ","zpds8P-9xews","87zjNtVGPtEp","ZJru8Sn3qhW7","txVnzBBBOgLP","JTnRqFaj_oNa","soaMlfmM4kjR","g8AcVBjo6IRf","uPUDaiG4q637","rfq2bUud_w4d","XBGxsiuUG2UD","-VQRnJlyAvMs","6wu7TScKdTU7","ZeFji2hLVpLj","HpCn_TVizMWX","IPR5HZwRdlwi","00JFOGuWnhWB","P1jb3qKt32Vg","D6MQJ43V1Ir5","qWSoXFteRfsq","o2avfYqEdomL","xRS0U0YnjK9G","VgOgzE_xfP4w","SwP3rMJGvoO3","Hf2jEgI_-PWa","AyhmBi7Cv598","-PaMuzTJXxVk","JMhYrg8SlY5K","SQeySEjzyplL","GTAwd2UkEQEe","x3RsZj5Ilebr","sRZWZqPi74FP","amHR50TpygA6","XSk782ceVNN6","ipiMyYQzeypI","ph2k3Nqfhau4","m5JKC3hAEQ0H","yTVerkmQbNxk","7taA6FbbbUbH","PZvpbSRuJLPs","C8atoa25U94F","KOfNJk_ISLc6","Bt74lBG9tJq6","BuHoY2rUhuKA","XTmoWKnwfIPl","ZATwa3oTD1m0","e8TczN5It6Am","6kCUYs8hQtKg","jDD8s5aiKoex","QmpmcrYwLU29","nCRcekynuJ08","resttaI4J9tu","EKSX3HV55VU3","2-yCz0EIsVls","sSeeGw3VbBY-","qfpCrU34w9y0","RKDgzPWecD6m","5SgXEKu_dICW","R143WAeB5E5r","8Ns4-NiKG62r","4AHuZDvop5XX","YCP1OsO1goFF","CYYaU1mQ_N6t","UGkzEOMK8cuU","1RzZOarkzQBa","qSW2Z3cZSI9c","ooPlKEAfQsnn","jIUScoKLiXQt","bjNTKugzRRL1","hR24ZVnHUZcs","3j2IDAZgUyYi","xnWcy-sQDJRu","UCcgJqGk3bTV","WSSRWeptH9tq","4ugv47OGD2E2","XboCZgUx-x3x","HrmWqiqsuLrm","OjdxvRJ3Jb6j"]

        let mA = BookmarkMirrorItem.bookmark("jIUScoKLiXQt", modified: Date.now(), hasDupe: false, parentID: "mobile", parentName: "mobile", title: "Join the Engineering Leisure Class — Medium", description: nil, URI: "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e", tags: "[]", keyword: nil)

        let mB = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: Date.now(), hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: children)
        bookmarks.applyRecords([mA, mB]).succeeded()

        func childCount(_ parent: GUID) -> Int? {
            let sql = "SELECT COUNT(*) AS childCount FROM \(TableBookmarksBufferStructure) WHERE parent = ?"
            let args: Args = [parent]
            return db.runQuery(sql, args: args, factory: { $0["childCount"] as! Int }).value.successValue?[0]
        }

        // We have children.
        XCTAssertEqual(children.count, childCount("UjAHxFOGEqU8"))

        // Insert an empty mobile bookmarks folder, so we can verify that the structure table is wiped.
        let mBEmpty = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: Date.now() + 1, hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: [])
        bookmarks.applyRecords([mBEmpty]).succeeded()

        // We no longer have children.
        XCTAssertEqual(0, childCount("UjAHxFOGEqU8"))
    }
}
