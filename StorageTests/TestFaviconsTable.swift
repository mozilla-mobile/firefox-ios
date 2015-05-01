/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestFaviconsTable : XCTestCase {
    var db: SwiftData!

    private func addIcon(favicons: FaviconsTable<Favicon>, url: String, s: Bool = true) -> Favicon {
        var inserted = -1;
        var icon: Favicon!
        db.withConnection(.ReadWrite) { connection -> NSError? in
            icon = Favicon(url: url, type: IconType.Icon)
            var err: NSError? = nil
            inserted = favicons.insert(connection, item: icon, err: &err)
            return err
        }
        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }
        return icon
    }

    private func checkIcons(favicons: FaviconsTable<Favicon>, options: QueryOptions?, urls: [String], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = favicons.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] {
                    XCTAssertNotNil(s, "cursor has an icon for entry")
                    let index = find(urls, s.url)
                    XCTAssert(index > -1, "Found right url")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func clear(favicons: FaviconsTable<Favicon>, icon: Favicon? = nil, s: Bool = true) {
        var deleted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            deleted = favicons.delete(connection, item: icon, err: &err)
            return nil
        }
        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testFaviconsTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent("test.db"))
        let f = FaviconsTable<Favicon>()

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            f.create(db, version: 1)
            return nil
        })

        let icon = self.addIcon(f, url: "url1")
        self.addIcon(f, url: "url1", s: false)
        self.addIcon(f, url: "url2")
        self.addIcon(f, url: "url2", s: false)

        self.checkIcons(f, options: nil, urls: ["url1", "url2"])

        let options = QueryOptions()
        options.filter = "url2"
        self.checkIcons(f, options: options, urls: ["url2"])

        var site = Favicon(url: "url1", type: IconType.Icon)
        self.clear(f, icon: icon, s: true)
        self.checkIcons(f, options: nil, urls: ["url2"])
        self.clear(f)
        self.checkIcons(f, options: nil, urls: [String]())
        
        files.remove("test.db")
    }
}