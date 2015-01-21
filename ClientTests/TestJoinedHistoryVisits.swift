import Foundation
import XCTest

class TestJoinedHistoryVisits : AccountTest {
    var db: SwiftData!

    private func addSite(history: JoinedHistoryVisitsTable, url: String, title: String, s: Bool = true) -> Site {
        var inserted = -1;
        let site = Site(url: url, title: title)
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            inserted = history.insert(connection, item: site, err: &err)
            return err
        }

        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }
        return site
    }

    private func addVisit(history: JoinedHistoryVisitsTable, site: Site, s: Bool = true) -> Visit {
        var inserted = -1;
        let visit = Visit(site: site, date: NSDate())
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            inserted = history.insert(connection, item: visit, err: &err)
            return err
        }

        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }
        return visit
    }

    private func checkSites(history: JoinedHistoryVisitsTable, options: QueryOptions?, urls: [String: String], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = history.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] as? Site {
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    let title = urls[s.url]
                    XCTAssertNotNil(title, "Found url")
                    XCTAssertEqual(s.title, title!, "Found right title")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func clear(history: JoinedHistoryVisitsTable, item: AnyObject? = nil, s: Bool = true) {
        var deleted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            deleted = history.delete(connection, item: item, err: &err)
            return nil
        }
        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testJoinedHistoryVisitsTable() {
        withTestAccount { account -> Void in
            self.db = SwiftData(filename: account.files.get("test.db")!)
            let h = JoinedHistoryVisitsTable()

            self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
                h.create(db, version: 2)
                return nil
            })

            self.addSite(h, url: "url", title: "title")
            let site = self.addSite(h, url: "url", title: "title")
            self.addSite(h, url: "url2", title: "title")
            self.addSite(h, url: "url2", title: "title")

            self.checkSites(h, options: nil, urls: ["url": "title", "url2": "title"])

            self.addSite(h, url: "url", title: "title 2")
            self.checkSites(h, options: nil, urls: ["url": "title 2", "url2": "title"])

            site.title = "title 3"
            let visit = self.addVisit(h, site: site)
            self.checkSites(h, options: nil, urls: ["url": "title 3", "url2": "title"])

            let options = QueryOptions()
            options.filter = "url2"
            self.checkSites(h, options: options, urls: ["url2": "title"])

            self.clear(h, item: site)
            self.checkSites(h, options: nil, urls: ["url2": "title"])

            self.clear(h, item: visit)
            self.checkSites(h, options: nil, urls: ["url2": "title"])

            self.clear(h)
            self.checkSites(h, options: nil, urls: [String: String]())
            
            account.files.remove("test.db")
        }
    }
}