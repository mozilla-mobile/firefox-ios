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
    if !db.createOrUpdate(BrowserTable()) {
        return nil
    }
    return db
}

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

        XCTAssertTrue(bookmarks.addToMobileBookmarks(u, title: "Title", favicon: nil).value.isSuccess)
        let model = bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID).value.successValue
        XCTAssertEqual((model?.current[0] as? BookmarkItem)?.url, url)
        XCTAssertTrue(bookmarks.isBookmarked(url).value.successValue ?? false)
        XCTAssertTrue(bookmarks.removeByURL("").value.isSuccess)

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

    func testLocalAndMirror() {
        guard let db = getBrowserDB("TSQLBtestLocalAndMirror.db", files: self.files) else {
            XCTFail("Unable to create browser DB.")
            return
        }

        func guidFactory(row: SDRow) -> GUID {
            return row[0] as! GUID
        }

        func getGUIDs(sql: String) -> [GUID] {
            guard let cursor = db.runQuery(sql, args: nil, factory: guidFactory).value.successValue else {
                XCTFail("Unable to get cursor.")
                return []
            }
            return cursor.asArray()
        }

        func getPositionsForChildrenOfParent(parent: GUID, fromTable table: String) -> [GUID: Int] {
            let args: Args = [parent]
            let factory: SDRow -> (GUID, Int) = {
                return ($0["child"] as! GUID, $0["idx"] as! Int)
            }
            let cursor = db.runQuery("SELECT child, idx FROM \(table) WHERE parent = ?", args: args, factory: factory).value.successValue!
            return cursor.reduce([:], combine: { (var dict, pair) in
                if let (k, v) = pair {
                    dict[k] = v
                }
                return dict
            })
        }

        func isOverridden(guid: GUID) -> Bool? {
            let args: Args = [guid]
            let cursor = db.runQuery("SELECT is_overridden FROM \(TableBookmarksMirror) WHERE guid = ?", args: args, factory: { $0.getBoolean("is_overridden") }).value.successValue!
            return cursor[0]
        }

        func getSyncStatusForGUID(guid: GUID) -> SyncStatus? {
            let args: Args = [guid]
            let cursor = db.runQuery("SELECT sync_status FROM \(TableBookmarksLocal) WHERE guid = ?", args: args, factory: { $0[0] as! Int }).value.successValue!
            if let raw = cursor[0] {
                return SyncStatus(rawValue: raw)
            }
            return nil
        }

        func getRecordByURL(url: String, fromTable table: String) -> BookmarkMirrorItem {
            let args: Args = [url]
            return db.runQuery("SELECT * FROM \(table) WHERE bmkUri = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
        }

        func getRecordByGUID(guid: GUID, fromTable table: String) -> BookmarkMirrorItem {
            let args: Args = [guid]
            return db.runQuery("SELECT * FROM \(table) WHERE guid = ?", args: args, factory: BookmarkFactory.mirrorItemFactory).value.successValue![0]!
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

        XCTAssertEqual(rootGUIDs, getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual(positioned, getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) ORDER BY idx"))
        XCTAssertEqual([], getGUIDs("SELECT guid FROM \(TableBookmarksMirror)"))
        XCTAssertEqual([], getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure)"))

        // Add a local bookmark.
        let bookmarks = SQLiteBookmarks(db: db)
        XCTAssertTrue(bookmarks.insertBookmark("http://example.org/".asURL!, title: "Example", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").value.isSuccess)

        let rowA = getRecordByURL("http://example.org/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowA.bookmarkURI, "http://example.org/")
        XCTAssertEqual(rowA.title, "Example")
        XCTAssertEqual(rootGUIDs + [rowA.guid], getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, getSyncStatusForGUID(rowA.guid))

        // Add another. Order should be maintained.
        XCTAssertTrue(bookmarks.insertBookmark("https://reddit.com/".asURL!, title: "Reddit", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").value.isSuccess)

        let rowB = getRecordByURL("https://reddit.com/", fromTable: TableBookmarksLocal)
        XCTAssertEqual(rowB.bookmarkURI, "https://reddit.com/")
        XCTAssertEqual(rowB.title, "Reddit")
        XCTAssertEqual(rootGUIDs + [rowA.guid, rowB.guid], getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowA.guid, rowB.guid], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        XCTAssertEqual(SyncStatus.New, getSyncStatusForGUID(rowA.guid))
        XCTAssertEqual(SyncStatus.New, getSyncStatusForGUID(rowB.guid))

        // The indices should be 0, 1.
        let positions = getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positions.count, 2)
        XCTAssertEqual(positions[rowA.guid], 0)
        XCTAssertEqual(positions[rowB.guid], 1)

        // Delete the first. sync_status was New, so the row was immediately deleted.
        XCTAssertTrue(bookmarks.removeByURL("http://example.org/").value.isSuccess)
        XCTAssertEqual(rootGUIDs + [rowB.guid], getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([rowB.guid], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let positionsAfterDelete = getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksLocalStructure)
        XCTAssertEqual(positionsAfterDelete.count, 1)
        XCTAssertEqual(positionsAfterDelete[rowB.guid], 0)

        // Manually shuffle all of these into the mirror, as if we were fully synchronized.
        self.moveLocalToMirror(db)
        XCTAssertEqual([], getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id"))
        XCTAssertEqual([], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure)"))
        XCTAssertEqual(rootGUIDs + [rowB.guid], getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
        let mirrorPositions = getPositionsForChildrenOfParent(BookmarkRoots.MobileFolderGUID, fromTable: TableBookmarksMirrorStructure)
        XCTAssertEqual(mirrorPositions.count, 1)
        XCTAssertEqual(mirrorPositions[rowB.guid], 0)

        // Now insert a new mobile bookmark.
        XCTAssertTrue(bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").value.isSuccess)

        // The mobile bookmarks folder is overridden.
        XCTAssertEqual(true, isOverridden(BookmarkRoots.MobileFolderGUID))

        // Our previous inserted bookmark is not.
        XCTAssertEqual(false, isOverridden(rowB.guid))

        let rowC = getRecordByURL("https://letsencrypt.org/", fromTable: TableBookmarksLocal)

        // We have the old structure in the mirror.
        XCTAssertEqual(rootGUIDs + [rowB.guid], getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // We have the new structure in the local table.
        XCTAssertEqual(Set([BookmarkRoots.MobileFolderGUID, rowC.guid]), Set(getGUIDs("SELECT guid FROM \(TableBookmarksLocal) ORDER BY id")))
        XCTAssertEqual([rowB.guid, rowC.guid], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Parent is changed. The new record is New. The unmodified and deleted records aren't present.
        XCTAssertNil(getSyncStatusForGUID(rowA.guid))
        XCTAssertNil(getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual(SyncStatus.New, getSyncStatusForGUID(rowC.guid))
        XCTAssertEqual(SyncStatus.Changed, getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // If we delete the old record, we mark it as changed, and it's no longer in the structure.
        XCTAssertTrue(bookmarks.removeByGUID(rowB.guid).value.isSuccess)
        XCTAssertEqual(SyncStatus.Changed, getSyncStatusForGUID(rowB.guid))
        XCTAssertEqual([rowC.guid], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // Add a duplicate to test multi-deletion (unstar).
        XCTAssertTrue(bookmarks.insertBookmark("https://letsencrypt.org/".asURL!, title: "Let's Encrypt", favicon: nil, intoFolder: BookmarkRoots.MobileFolderGUID, withTitle: "Mobile").value.isSuccess)
        let guidD = getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx").last!
        XCTAssertNotEqual(rowC.guid, guidD)
        XCTAssertEqual(SyncStatus.New, getSyncStatusForGUID(guidD))
        XCTAssertEqual(SyncStatus.Changed, getSyncStatusForGUID(BookmarkRoots.MobileFolderGUID))

        // Delete by URL.
        // If we delete the new records, they just go away -- there's no server version to delete.
        XCTAssertTrue(bookmarks.removeByURL(rowC.bookmarkURI!).value.isSuccess)
        XCTAssertNil(getSyncStatusForGUID(rowC.guid))
        XCTAssertNil(getSyncStatusForGUID(guidD))
        XCTAssertEqual([], getGUIDs("SELECT child FROM \(TableBookmarksLocalStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))

        // The mirror structure is unchanged after all this.
        XCTAssertEqual(rootGUIDs + [rowB.guid], getGUIDs("SELECT guid FROM \(TableBookmarksMirror) ORDER BY id"))
        XCTAssertEqual([rowB.guid], getGUIDs("SELECT child FROM \(TableBookmarksMirrorStructure) WHERE parent = '\(BookmarkRoots.MobileFolderGUID)' ORDER BY idx"))
    }

    private func moveLocalToMirror(db: BrowserDB) {
        // This is a risky process -- it's not the same logic that the real synchronizer uses
        // (because I haven't written it yet), so it might end up lying. We do what we can.
        let overrideSQL = "INSERT OR IGNORE INTO \(TableBookmarksMirror) " +
                          "(guid, type, bmkUri, title, parentid, parentName, feedUri, siteUri, pos," +
                          " description, tags, keyword, folderName, queryId, " +
                          " is_overridden, server_modified, faviconID) " +
                          "SELECT guid, type, bmkUri, title, parentid, parentName, " +
                          "feedUri, siteUri, pos, description, tags, keyword, folderName, queryId, " +
                          "0 AS is_overridden, \(NSDate.now()) AS server_modified, faviconID " +
                          "FROM \(TableBookmarksLocal)"

        // Copy its mirror structure.
        let copySQL = "INSERT INTO \(TableBookmarksMirrorStructure) " +
                      "SELECT * FROM \(TableBookmarksLocalStructure)"

        // Throw away the old.
        let deleteLocalStructureSQL = "DELETE FROM \(TableBookmarksLocalStructure)"
        let deleteLocalSQL = "DELETE FROM \(TableBookmarksLocal)"

        XCTAssertTrue(db.run([
            overrideSQL,
            copySQL,
            deleteLocalStructureSQL,
            deleteLocalSQL,
        ]).value.isSuccess)
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
        let applyA = bookmarks.applyRecords(recordsA, withMaxVars: 3).value
        XCTAssertTrue(applyA.isSuccess)


        // Insert mobile bookmarks as produced by Firefox 40-something on desktop.

        let children = ["M87np9Vfh_2s","-JxRyqNte-ue","6lIQzUtbjE8O","eOg3jPSslzXl","1WJIi9EjQErp","z5uRo45Rvfbd","EK3lcNd0sUFN","gFD3GTljgu12","eRZGsbN1ew9-","widfEdgGn9de","l7eTOR4Uf6xq","vPbxG-gpN4Rb","4dwJ8CototFe","zK-kw9Ii6ScW","eDmDU-gtEFW6","lKjqWQaL_syt","ETVDvWgGT31Q","3Z_bMIHPSZQ8","Fqu4_bJOk7fT","Uo_5K1QrA67j","gDTXNg4m1AJZ","zpds8P-9xews","87zjNtVGPtEp","ZJru8Sn3qhW7","txVnzBBBOgLP","JTnRqFaj_oNa","soaMlfmM4kjR","g8AcVBjo6IRf","uPUDaiG4q637","rfq2bUud_w4d","XBGxsiuUG2UD","-VQRnJlyAvMs","6wu7TScKdTU7","ZeFji2hLVpLj","HpCn_TVizMWX","IPR5HZwRdlwi","00JFOGuWnhWB","P1jb3qKt32Vg","D6MQJ43V1Ir5","qWSoXFteRfsq","o2avfYqEdomL","xRS0U0YnjK9G","VgOgzE_xfP4w","SwP3rMJGvoO3","Hf2jEgI_-PWa","AyhmBi7Cv598","-PaMuzTJXxVk","JMhYrg8SlY5K","SQeySEjzyplL","GTAwd2UkEQEe","x3RsZj5Ilebr","sRZWZqPi74FP","amHR50TpygA6","XSk782ceVNN6","ipiMyYQzeypI","ph2k3Nqfhau4","m5JKC3hAEQ0H","yTVerkmQbNxk","7taA6FbbbUbH","PZvpbSRuJLPs","C8atoa25U94F","KOfNJk_ISLc6","Bt74lBG9tJq6","BuHoY2rUhuKA","XTmoWKnwfIPl","ZATwa3oTD1m0","e8TczN5It6Am","6kCUYs8hQtKg","jDD8s5aiKoex","QmpmcrYwLU29","nCRcekynuJ08","resttaI4J9tu","EKSX3HV55VU3","2-yCz0EIsVls","sSeeGw3VbBY-","qfpCrU34w9y0","RKDgzPWecD6m","5SgXEKu_dICW","R143WAeB5E5r","8Ns4-NiKG62r","4AHuZDvop5XX","YCP1OsO1goFF","CYYaU1mQ_N6t","UGkzEOMK8cuU","1RzZOarkzQBa","qSW2Z3cZSI9c","ooPlKEAfQsnn","jIUScoKLiXQt","bjNTKugzRRL1","hR24ZVnHUZcs","3j2IDAZgUyYi","xnWcy-sQDJRu","UCcgJqGk3bTV","WSSRWeptH9tq","4ugv47OGD2E2","XboCZgUx-x3x","HrmWqiqsuLrm","OjdxvRJ3Jb6j"]

        let mA = BookmarkMirrorItem.bookmark("jIUScoKLiXQt", modified: NSDate.now(), hasDupe: false, parentID: "mobile", parentName: "mobile", title: "Join the Engineering Leisure Class — Medium", description: nil, URI: "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e", tags: "[]", keyword: nil)

        let mB = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: children)
        let applyM = bookmarks.applyRecords([mA, mB]).value
        XCTAssertTrue(applyM.isSuccess)

        func childCount(parent: GUID) -> Int? {
            let sql = "SELECT COUNT(*) AS childCount FROM \(TableBookmarksBufferStructure) WHERE parent = ?"
            let args: Args = [parent]
            return db.runQuery(sql, args: args, factory: { $0["childCount"] as! Int }).value.successValue?[0]
        }

        // We have children.
        XCTAssertEqual(children.count, childCount("UjAHxFOGEqU8"))

        // Insert an empty mobile bookmarks folder, so we can verify that the structure table is wiped.
        let mBEmpty = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: NSDate.now() + 1, hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: [])
        XCTAssertTrue(bookmarks.applyRecords([mBEmpty]).value.isSuccess)

        // We no longer have children.
        XCTAssertEqual(0, childCount("UjAHxFOGEqU8"))
    }
}
