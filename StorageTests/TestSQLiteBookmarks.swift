/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage

import XCTest

private func getBrowserDB(filename: String, files: FileAccessor) -> BrowserDB? {
    let db = BrowserDB(filename: filename, files: files)

    // BrowserTable exists only to perform create/update etc. operations -- it's not
    // a queryable thing that needs to stick around.
    if !db.createOrUpdate(BrowserTable()) {
        return nil
    }
    return db
}

// MARK: - Tests.

class TestSQLiteBookmarks: XCTestCase {
    let files = MockFiles()

    private func remove(path: String) {
        do {
            try self.files.remove(path)
        } catch {}
    }

    override func tearDown() {
        self.remove("TSQLBtestBookmarks.db")
        self.remove("TSQLBtestBufferStorage.db")
        self.remove("TSQLBtestLocalAndMirror.db")
        self.remove("TSQLBtestRecursiveAndURLDelete.db")
        super.tearDown()
    }

    func testBookmarks() {
        guard let db = getBrowserDB("TSQLBtestBookmarks.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarks(db: db)

        let url = "http://url1/"
        let u = url.asURL!

        bookmarks.addToMobileBookmarks(u, title: "Title", favicon: nil).succeeded()
        let model = bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID).value.successValue
        XCTAssertEqual((model?.current[0] as? BookmarkItem)?.url, url)
        XCTAssertTrue(bookmarks.isBookmarked(url).value.successValue ?? false)
        bookmarks.removeByURL("").succeeded()

        // Grab that GUID and move it into desktop bookmarks.
        let guid = (model?.current[0] as! BookmarkItem).guid

        // Desktop bookmarks.
        XCTAssertFalse(bookmarks.hasDesktopBookmarks().value.successValue ?? true)
        let toolbar = BookmarkRoots.ToolbarFolderGUID
        XCTAssertTrue(bookmarks.db.run([
            "UPDATE \(TableBookmarksLocal) SET parentid = '\(toolbar)' WHERE guid = '\(guid)'",
            "UPDATE \(TableBookmarksLocalStructure) SET parent = '\(toolbar)' WHERE child = '\(guid)'",
            ]).value.isSuccess)
        XCTAssertTrue(bookmarks.hasDesktopBookmarks().value.successValue ?? true)
    }

    func testRecursiveAndURLDelete() {
        guard let db = getBrowserDB("TSQLBtestRecursiveAndURLDelete.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        let bookmarks = SQLiteBookmarks(db: db)

        // Set up a mirror tree.
        let mirrorQuery =
        "INSERT INTO \(TableBookmarksMirror) (guid, type, bmkUri, title, parentid, parentName, description, tags, keyword, is_overridden, server_modified, pos) " +
        "VALUES " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Folder.rawValue), NULL, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +

        "(?, \(BookmarkNodeType.Separator.rawValue), NULL, NULL, ?, '', '', '', '', 0, \(NSDate.now()), 0), " +

        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL), " +
        "(?, \(BookmarkNodeType.Bookmark.rawValue), ?, ?, ?, '', '', '', '', 0, \(NSDate.now()), NULL) "

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
        "(?, ?, ?) "

        let structureArgs: Args = [
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

        let menuOverridden = BookmarkRoots.MenuFolderGUID
        XCTAssertFalse(db.isOverridden(menuOverridden) ?? true)

        func getMenuChildren() -> [GUID] {
            return db.getChildrenOfFolder(BookmarkRoots.MenuFolderGUID)
        }

        XCTAssertEqual(["folderBBBBBB"], getMenuChildren())

        // Locally add an item to the menu. This'll override the menu folder.
        bookmarks.insertBookmark(NSURL(string: "http://example.com/2")!, title: "Bookmark 2 added locally", favicon: nil, intoFolder: BookmarkRoots.MenuFolderGUID, withTitle: "Bookmarks Menu").succeeded()

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

        bookmarks.removeByGUID("folderBBBBBB").succeeded()

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

        bookmarks.removeByURL("http://example.org/1").succeeded()

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
        bookmarks.insertBookmark("http://example.org/".asURL!, title: "Example", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()

        let rowA = db.getRecordByURL("http://example.org/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowA.bookmarkURI, "http://example.org/")
        XCTAssertEqual(rowA.title, "Example")
        XCTAssertEqual(rootGUIDs + [rowA.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowA.guid))

        // Add another. Order should be maintained.
        bookmarks.insertBookmark("https://reddit.com/".asURL!, title: "Reddit", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()

        let rowB = db.getRecordByURL("https://reddit.com/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowB.bookmarkURI, "https://reddit.com/")
        XCTAssertEqual(rowB.title, "Reddit")
        XCTAssertEqual(rootGUIDs + [rowA.guid, rowB.guid], db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid, rowB.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowA.guid))
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowB.guid))

        // The indices should be 0, 1.
        let positions = db.getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positions.count, 2)
        XCTAssertEqual(positions[rowA.guid], 0)
        XCTAssertEqual(positions[rowB.guid], 1)

        // Delete the first. sync_status was New, so the row was immediately deleted.
        bookmarks.removeByURL("http://example.org/").succeeded()
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
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(rowC.guid))
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // If we delete the old record, we mark it as changed, and it's no longer in the structure.
        bookmarks.removeByGUID(rowB.guid).succeeded()
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual([rowC.guid], db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Add a duplicate to test multi-deletion (unstar).
        bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").succeeded()
        let guidD = db.getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx").last!
        XCTAssertNotEqual(rowC.guid, guidD)
        XCTAssertEqual(SyncStatus.New, db.getSyncStatusForGUID(guidD))
        XCTAssertEqual(SyncStatus.Changed, db.getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // Delete by URL.
        // If we delete the new records, they just go away -- there's no server version to delete.
        bookmarks.removeByURL(rowC.bookmarkURI!).succeeded()
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
        guard let db = getBrowserDB("TSQLBtestBufferStorage.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }
        let bookmarks = SQLiteBookmarkBufferStorage(db: db)

        let record1 = BookmarkMirrorItem.bookmark("aaaaaaaaaaaa", modified: NSDate.now(), hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "AAA", description: "AAA desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let record2 = BookmarkMirrorItem.bookmark("bbbbbbbbbbbb", modified: NSDate.now() + 10, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "BBB", description: "BBB desc", URI: "http://getfirefox.com", tags: "[]", keyword: nil)
        let toolbar = BookmarkMirrorItem.folder("toolbar", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "Bookmarks Toolbar", description: "Add bookmarks to this folder to see them displayed on the Bookmarks Toolbar", children: ["aaaaaaaaaaaa", "bbbbbbbbbbbb"])
        let recordsA: [BookmarkMirrorItem] = [record1, toolbar, record2]
        bookmarks.applyRecords(recordsA, withMaxVars: 3).succeeded()

        // Insert mobile bookmarks as produced by Firefox 40-something on desktop.

        let children = ["M87np9Vfh_2s","-JxRyqNte-ue","6lIQzUtbjE8O","eOg3jPSslzXl","1WJIi9EjQErp","z5uRo45Rvfbd","EK3lcNd0sUFN","gFD3GTljgu12","eRZGsbN1ew9-","widfEdgGn9de","l7eTOR4Uf6xq","vPbxG-gpN4Rb","4dwJ8CototFe","zK-kw9Ii6ScW","eDmDU-gtEFW6","lKjqWQaL_syt","ETVDvWgGT31Q","3Z_bMIHPSZQ8","Fqu4_bJOk7fT","Uo_5K1QrA67j","gDTXNg4m1AJZ","zpds8P-9xews","87zjNtVGPtEp","ZJru8Sn3qhW7","txVnzBBBOgLP","JTnRqFaj_oNa","soaMlfmM4kjR","g8AcVBjo6IRf","uPUDaiG4q637","rfq2bUud_w4d","XBGxsiuUG2UD","-VQRnJlyAvMs","6wu7TScKdTU7","ZeFji2hLVpLj","HpCn_TVizMWX","IPR5HZwRdlwi","00JFOGuWnhWB","P1jb3qKt32Vg","D6MQJ43V1Ir5","qWSoXFteRfsq","o2avfYqEdomL","xRS0U0YnjK9G","VgOgzE_xfP4w","SwP3rMJGvoO3","Hf2jEgI_-PWa","AyhmBi7Cv598","-PaMuzTJXxVk","JMhYrg8SlY5K","SQeySEjzyplL","GTAwd2UkEQEe","x3RsZj5Ilebr","sRZWZqPi74FP","amHR50TpygA6","XSk782ceVNN6","ipiMyYQzeypI","ph2k3Nqfhau4","m5JKC3hAEQ0H","yTVerkmQbNxk","7taA6FbbbUbH","PZvpbSRuJLPs","C8atoa25U94F","KOfNJk_ISLc6","Bt74lBG9tJq6","BuHoY2rUhuKA","XTmoWKnwfIPl","ZATwa3oTD1m0","e8TczN5It6Am","6kCUYs8hQtKg","jDD8s5aiKoex","QmpmcrYwLU29","nCRcekynuJ08","resttaI4J9tu","EKSX3HV55VU3","2-yCz0EIsVls","sSeeGw3VbBY-","qfpCrU34w9y0","RKDgzPWecD6m","5SgXEKu_dICW","R143WAeB5E5r","8Ns4-NiKG62r","4AHuZDvop5XX","YCP1OsO1goFF","CYYaU1mQ_N6t","UGkzEOMK8cuU","1RzZOarkzQBa","qSW2Z3cZSI9c","ooPlKEAfQsnn","jIUScoKLiXQt","bjNTKugzRRL1","hR24ZVnHUZcs","3j2IDAZgUyYi","xnWcy-sQDJRu","UCcgJqGk3bTV","WSSRWeptH9tq","4ugv47OGD2E2","XboCZgUx-x3x","HrmWqiqsuLrm","OjdxvRJ3Jb6j"]

        let mA = BookmarkMirrorItem.bookmark("jIUScoKLiXQt", modified: NSDate.now(), hasDupe: false, parentID: "mobile", parentName: "mobile", title: "Join the Engineering Leisure Class — Medium", description: nil, URI: "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e", tags: "[]", keyword: nil)

        let mB = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: children)
        bookmarks.applyRecords([mA, mB]).succeeded()

        func childCount(parent: GUID) -> Int? {
            let sql = "SELECT COUNT(*) AS childCount FROM \(TableBookmarksBufferStructure) WHERE parent = ?"
            let args: Args = [parent]
            return db.runQuery(sql, args: args, factory: { $0["childCount"] as! Int }).value.successValue?[0]
        }

        // We have children.
        XCTAssertEqual(children.count, childCount("UjAHxFOGEqU8"))

        // Insert an empty mobile bookmarks folder, so we can verify that the structure table is wiped.
        let mBEmpty = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: NSDate.now() + 1, hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: [])
        bookmarks.applyRecords([mBEmpty]).succeeded()

        // We no longer have children.
        XCTAssertEqual(0, childCount("UjAHxFOGEqU8"))
    }
}
