import Foundation
import XCTest

class TestJoinedHistoryVisits : XCTestCase {
    var db: SwiftData!

    private func addSite(history: JoinedHistoryVisitsTable, url: String, title: String, s: Bool = true) -> Site {
        var inserted = -1;
        let site = Site(url: url, title: title)
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            inserted = history.insert(connection, item: (site, nil), err: &err)
            return err
        }

        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded \(url) \(title)")
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
            inserted = history.insert(connection, item: (nil, visit), err: &err)
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
                if let (site, visit) = cursor[index] as? (Site,Visit) {
                    XCTAssertNotNil(site, "cursor has a site for entry")
                    let title = urls[site.url]
                    XCTAssertNotNil(title, "Found url")
                    XCTAssertEqual(site.title, title!, "Found right title")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func checkSitesOrdered(history: JoinedHistoryVisitsTable, options: QueryOptions?, urls: [(String, String)], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = history.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, urls.count, "cursor has right num of entries")

            for index in 0..<urls.count {
                let d = cursor[index]
                println("Found \(d)")
                let (site, visit) = cursor[index] as (site: Site, visit: Visit)
                XCTAssertNotNil(s, "cursor has a site for entry")
                let info = urls[index]
                XCTAssertEqual(site.url, info.0, "Found url")
                XCTAssertEqual(site.title, info.1, "Found right title")
            }
            return nil
        }
    }

    private func clear(history: JoinedHistoryVisitsTable, item: (site:Site?, visit:Visit?)? = nil, s: Bool = true) {
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
        let files = MockFiles()
        self.db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent("test.db"))
        let h = JoinedHistoryVisitsTable(files: files)

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            h.create(db, version: 2)
            return nil
        })

        // Add a few visits to some sites
        self.addSite(h, url: "url1", title: "title1")
        let site = self.addSite(h, url: "url1", title: "title1")
        self.addSite(h, url: "url2", title: "title2")
        self.addSite(h, url: "url2", title: "title2")

        // Query all the sites
        self.checkSites(h, options: nil, urls: ["url1": "title1", "url2": "title2"])

        // Query all the sites sorted by data
        let opts = QueryOptions()
        opts.sort = .LastVisit
        self.checkSitesOrdered(h, options: opts, urls: [("url2", "title2"), ("url1", "title1")])

        // Adding an already existing site should update the title
        self.addSite(h, url: "url1", title: "title1 alt")
        self.checkSites(h, options: nil, urls: ["url1": "title1 alt", "url2": "title2"])

        // Adding an visit with an existing site should update the title
        let site2 = Site(url: site.url, title: "title1 second alt")
        let visit = self.addVisit(h, site: site2)
        self.checkSites(h, options: nil, urls: ["url1": "title1 second alt", "url2": "title2"])

        // Filtering should default to matching urls
        let options = QueryOptions()
        options.filter = "url2"
        self.checkSites(h, options: options, urls: ["url2": "title2"])

        // Clearing with a site should remove the site
        self.clear(h, item: (site, nil))
        self.checkSites(h, options: nil, urls: ["url2": "title2"])

        // Clearing with a site should remove the visit
        self.clear(h, item: (nil, visit))
        self.checkSites(h, options: nil, urls: ["url2": "title2"])

        // Clearing with nil should remove everything
        self.clear(h)
        self.checkSites(h, options: nil, urls: [String: String]())
        
        files.remove("test.db")
    }
}