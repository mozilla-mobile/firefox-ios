import Foundation
import XCTest

class TestJoinedFaviconsTable : XCTestCase {
    var db: SwiftData!

    private func addIcon(favicons: JoinedFaviconsHistoryTable<(Site, Favicon)>, site: Site, url: String, s: Bool = true) -> Favicon {
        var inserted = -1;
        var icon: Favicon!
        db.withConnection(.ReadWrite) { connection -> NSError? in
            icon = Favicon(url: url, type: IconType.Icon)
            var err: NSError? = nil
            inserted = favicons.insert(connection, item: (site, icon), err: &err)
            return err
        }
        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }
        return icon
    }

    private func checkIcons(favicons: JoinedFaviconsHistoryTable<(Site, Favicon)>, options: QueryOptions?, urls: [String], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = favicons.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let (site, favicon) = cursor[index] as? (Site, Favicon) {
                    XCTAssertNotNil(s, "cursor has an icon for entry")
                    let index = find(urls, favicon.url)
                    XCTAssert(index > -1, "Found right url \(favicon.url)")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func clear(favicons: JoinedFaviconsHistoryTable<(Site, Favicon)>, icon: (Site?, Favicon?)? = nil, s: Bool = true) {
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
    func testJoinedFaviconsTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.get("test.db", basePath: nil)!)
        let f = JoinedFaviconsHistoryTable<(Site, Favicon)>(files: files)

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            f.create(db, version: 1)
            return nil
        })

        let site1 = Site(url: "site1", title: "title1")
        let site2 = Site(url: "site2", title: "title2")
        let icon = self.addIcon(f, site: site1, url: "url1-1")
        self.addIcon(f, site: site1, url: "url1-2")
        self.addIcon(f, site: site2, url: "url2-1")
        self.addIcon(f, site: site2, url: "url2-2")

        self.checkIcons(f, options: nil, urls: ["url1-1", "url1-2", "url2-1", "url2-2"])

        let options = QueryOptions()
        options.filter = "site1"
        self.checkIcons(f, options: options, urls: ["url1-1", "url1-2"])

        self.clear(f, icon: (nil, icon), s: true)
        self.checkIcons(f, options: options, urls: ["url1-2"])
        self.clear(f, icon: (site1, nil), s: true)
        self.checkIcons(f, options: options, urls: [String]())
        self.clear(f)
        self.checkIcons(f, options: nil, urls: [String]())
        
        files.remove("test.db", basePath: nil)
    }
}