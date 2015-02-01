import Foundation
import XCTest

class TestHistoryTable : XCTestCase {
    var db: SwiftData!

    private func addSite(history: HistoryTable<Site>, url: String, title: String, s: Bool = true) {
        var inserted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            let site = Site(url: url, title: title)
            var err: NSError? = nil
            inserted = history.insert(connection, item: site, err: &err)
            return err
        }
        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }
    }

    private func updateSite(history: HistoryTable<Site>, url: String, title: String, s: Bool = true) {
        var updated = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            let site = Site(url: url, title: title)
            var err: NSError? = nil
            updated = history.update(connection, item: site, err: &err)
            return err
        }

        if s {
            XCTAssert(updated >= 0, "Update succeeded")
        } else {
            XCTAssert(updated == -1, "Update failed")
        }
    }

    private func checkSites(history: HistoryTable<Site>, options: QueryOptions?, urls: [String: String], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = history.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] as? Site {
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    println("Lookging for \(s.url)")
                    let title = urls[s.url]
                    XCTAssertNotNil(title, "Found right url")
                    XCTAssertEqual(s.title, title!, "Found right title")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func clear(history: HistoryTable<Site>, site: Site? = nil, s: Bool = true) {
        var deleted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            deleted = history.delete(connection, item: site, err: &err)
            return nil
        }
        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testHistoryTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.get("test.db", basePath: nil)!)
        let h = HistoryTable<Site>()

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            h.create(db, version: 1)
            return nil
        })

        self.addSite(h, url: "url1", title: "title1")
        self.addSite(h, url: "url1", title: "title1", s: false)
        self.updateSite(h, url: "url1", title: "title1 alt")
        self.addSite(h, url: "url2", title: "title2")
        self.addSite(h, url: "url2", title: "title2", s: false)

        self.checkSites(h, options: nil, urls: ["url1": "title1 alt", "url2": "title2"])

        let options = QueryOptions()
        options.filter = "url2"
        self.checkSites(h, options: options, urls: ["url2": "title2"])

        var site = Site(url: "url1", title: "title1 alt")
        self.clear(h, site: site, s: true)
        self.checkSites(h, options: nil, urls: ["url2": "title2"])
        self.clear(h)
        self.checkSites(h, options: nil, urls: [String: String]())

        files.remove("test.db")
    }
}