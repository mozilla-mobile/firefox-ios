import Foundation
import XCTest

class TestFaviconsTable : XCTestCase {
    var db: SwiftData!

    private func addFavicon(favicons: FaviconsTable<Favicon>, favicon: Favicon, s: Bool = true) -> Favicon {
        var inserted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            inserted = favicons.insert(connection, item: SavedFavicon(favicon: favicon), err: &err)
            return nil
        }

        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }

        return favicon
    }

    private func checkFavicons(favicons: FaviconsTable<Favicon>, options: QueryOptions? = nil, icons: [Favicon], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = favicons.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, icons.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] as? Favicon {
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    XCTAssertEqual(s.updatedDate.timeIntervalSince1970, icons[index].updatedDate.timeIntervalSince1970, "Found right date")
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

    private func getDir() -> String {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testFaviconsTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.get("test.db")!)
        let favicons = FaviconsTable<Favicon>(files: files)

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            favicons.create(db, version: 3)
            return nil
        })

        let icon = Favicon(url: "url1", image: nil, date: NSDate())
        let icon2 = Favicon(url: "url2", image: nil, date: NSDate())

        let i1 = addFavicon(favicons, favicon: icon)
        let i2 = addFavicon(favicons, favicon: icon, s: false)
        let i3 = addFavicon(favicons, favicon: icon2)
        let i4 = addFavicon(favicons, favicon: icon2, s: false)

        checkFavicons(favicons, options: nil, icons: [i1, i3])
        let options = QueryOptions()
        options.filter = i1.url
        checkFavicons(favicons, options: options, icons: [i1])

        clear(favicons, icon: i1, s: true)
        checkFavicons(favicons, options: options, icons: [])
        clear(favicons, s: true)
        checkFavicons(favicons, options: nil, icons: [])
        
        files.remove("test.db")
    }
}