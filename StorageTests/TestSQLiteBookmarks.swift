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

        // Insert mobile bookmarks as produced by Firefox 40-something on desktop.

        let children = ["M87np9Vfh_2s","-JxRyqNte-ue","6lIQzUtbjE8O","eOg3jPSslzXl","1WJIi9EjQErp","z5uRo45Rvfbd","EK3lcNd0sUFN","gFD3GTljgu12","eRZGsbN1ew9-","widfEdgGn9de","l7eTOR4Uf6xq","vPbxG-gpN4Rb","4dwJ8CototFe","zK-kw9Ii6ScW","eDmDU-gtEFW6","lKjqWQaL_syt","ETVDvWgGT31Q","3Z_bMIHPSZQ8","Fqu4_bJOk7fT","Uo_5K1QrA67j","gDTXNg4m1AJZ","zpds8P-9xews","87zjNtVGPtEp","ZJru8Sn3qhW7","txVnzBBBOgLP","JTnRqFaj_oNa","soaMlfmM4kjR","g8AcVBjo6IRf","uPUDaiG4q637","rfq2bUud_w4d","XBGxsiuUG2UD","-VQRnJlyAvMs","6wu7TScKdTU7","ZeFji2hLVpLj","HpCn_TVizMWX","IPR5HZwRdlwi","00JFOGuWnhWB","P1jb3qKt32Vg","D6MQJ43V1Ir5","qWSoXFteRfsq","o2avfYqEdomL","xRS0U0YnjK9G","VgOgzE_xfP4w","SwP3rMJGvoO3","Hf2jEgI_-PWa","AyhmBi7Cv598","-PaMuzTJXxVk","JMhYrg8SlY5K","SQeySEjzyplL","GTAwd2UkEQEe","x3RsZj5Ilebr","sRZWZqPi74FP","amHR50TpygA6","XSk782ceVNN6","ipiMyYQzeypI","ph2k3Nqfhau4","m5JKC3hAEQ0H","yTVerkmQbNxk","7taA6FbbbUbH","PZvpbSRuJLPs","C8atoa25U94F","KOfNJk_ISLc6","Bt74lBG9tJq6","BuHoY2rUhuKA","XTmoWKnwfIPl","ZATwa3oTD1m0","e8TczN5It6Am","6kCUYs8hQtKg","jDD8s5aiKoex","QmpmcrYwLU29","nCRcekynuJ08","resttaI4J9tu","EKSX3HV55VU3","2-yCz0EIsVls","sSeeGw3VbBY-","qfpCrU34w9y0","RKDgzPWecD6m","5SgXEKu_dICW","R143WAeB5E5r","8Ns4-NiKG62r","4AHuZDvop5XX","YCP1OsO1goFF","CYYaU1mQ_N6t","UGkzEOMK8cuU","1RzZOarkzQBa","qSW2Z3cZSI9c","ooPlKEAfQsnn","jIUScoKLiXQt","bjNTKugzRRL1","hR24ZVnHUZcs","3j2IDAZgUyYi","xnWcy-sQDJRu","UCcgJqGk3bTV","WSSRWeptH9tq","4ugv47OGD2E2","XboCZgUx-x3x","HrmWqiqsuLrm","OjdxvRJ3Jb6j"]

        let mA = BookmarkMirrorItem.bookmark("jIUScoKLiXQt", modified: NSDate.now(), hasDupe: false, parentID: "mobile", parentName: "mobile", title: "Join the Engineering Leisure Class — Medium", description: nil, URI: "https://medium.com/@chrisloer/join-the-engineering-leisure-class-b3083c09a78e", tags: "[]", keyword: nil)

        let mB = BookmarkMirrorItem.folder("UjAHxFOGEqU8", modified: NSDate.now(), hasDupe: false, parentID: "places", parentName: "", title: "mobile", description: nil, children: children)
        let applyM = bookmarks.applyRecords([mA, mB]).value
        XCTAssertTrue(applyM.isSuccess)

        func childCount(parent: GUID) -> Int? {
            let sql = "SELECT COUNT(*) AS childCount FROM \(TableBookmarksMirrorStructure) WHERE parent = ?"
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