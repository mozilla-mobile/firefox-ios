/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
@testable import Storage

import XCTest

class TestFaviconsTable: XCTestCase {
    var db: BrowserDB!

    @discardableResult
    fileprivate func addIcon(_ favicons: FaviconsTable<Favicon>, url: String, s: Bool = true) -> Favicon {
        var inserted: Int? = -1
        var icon: Favicon!
        var err: NSError?
        let _ = self.db.withConnection(flags: SwiftData.Flags.readWrite, err: &err) { (connection, err) -> Int? in
            XCTAssertNil(err)
            icon = Favicon(url: url, type: IconType.icon)
            var error: NSError? = nil
            inserted = favicons.insert(connection, item: icon, err: &error)
            return inserted
        }

        if s {
            XCTAssert(inserted! >= 0, "Insert succeeded")
        } else {
            XCTAssert(inserted == nil, "Insert failed")
        }
        return icon
    }

    fileprivate func checkIcons(_ favicons: FaviconsTable<Favicon>, options: QueryOptions?, urls: [String], s: Bool = true) {
        var err: NSError?
        let _ = self.db.withConnection(flags: SwiftData.Flags.readOnly, err: &err) { (connection, err) -> Bool in
            XCTAssertNil(err)
            let cursor = favicons.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] {
                    XCTAssertNotNil(s, "cursor has an icon for entry")
                    let index = urls.index(of: s.url)
                    XCTAssert(index! > -1, "Found right url")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return true
        }
    }

    fileprivate func clear(_ favicons: FaviconsTable<Favicon>, icon: Favicon? = nil, s: Bool = true) {
        var deleted = -1
        var err: NSError?
        let _ = self.db.withConnection(flags: SwiftData.Flags.readWriteCreate, err: &err) { (db, err) -> Int in
            deleted = favicons.delete(db, item: icon, err: &err)
            return deleted
        }
        XCTAssertNil(err)
        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testFaviconsTable() {
        let files = MockFiles()
        db = BrowserDB(filename: "test.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        XCTAssertTrue(db.createOrUpdate(BrowserTable()) == .success)
        let f = FaviconsTable<Favicon>()

        var err: NSError?
        let _ = self.db.withConnection(flags: SwiftData.Flags.readWriteCreate, err: &err) { (db, err) -> Bool in
            let result = f.create(db)
            XCTAssertTrue(result)
            return result
        }
        XCTAssertNil(err)

        let icon = self.addIcon(f, url: "url1")
        self.addIcon(f, url: "url1", s: false)
        self.addIcon(f, url: "url2")
        self.addIcon(f, url: "url2", s: false)

        self.checkIcons(f, options: nil, urls: ["url1", "url2"])

        let options = QueryOptions()
        options.filter = "url2"
        self.checkIcons(f, options: options, urls: ["url2"])

        _ = Favicon(url: "url1", type: IconType.icon)
        self.clear(f, icon: icon, s: true)
        self.checkIcons(f, options: nil, urls: ["url2"])
        self.clear(f)
        self.checkIcons(f, options: nil, urls: [String]())
        
        do {
            try files.remove("test.db")
        } catch _ {
        }
    }
}
