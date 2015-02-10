import Foundation
import XCTest

class TestVisitsTable : XCTestCase {
    var db: SwiftData!

    private func addVisit(visits: VisitsTable<Visit>, site: Site, s: Bool = true) -> Visit {
        var inserted = -1;
        var visit : Visit!
        db.withConnection(.ReadWrite) { connection -> NSError? in
            visit = Visit(site: site, date: NSDate())
            var err: NSError? = nil
            visit.id = visits.insert(connection, item: visit, err: &err)
            return nil
        }

        if s {
            XCTAssert(visit.id >= 0, "Inserted succeeded")
        } else {
            XCTAssert(visit.id == -1, "Inserted failed")
        }
        return visit
    }

    private func checkVisits(visits: VisitsTable<Visit>, options: QueryOptions? = nil, vs: [Visit], s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = visits.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, vs.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] as? Visit {
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    XCTAssertEqual(s.date.timeIntervalSince1970, vs[index].date.timeIntervalSince1970, "Found right date")
                } else {
                    XCTAssertFalse(true, "Should not be nil...")
                }
            }
            return nil
        }
    }

    private func clear(visits: VisitsTable<Visit>, visit: Visit? = nil, s: Bool = true) {
        var deleted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            deleted = visits.delete(connection, item: visit, err: &err)
            return nil
        }

        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testVisitsTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.get("test.db", basePath: nil)!)
        let h = VisitsTable<Visit>()

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            h.create(db, version: 2)
            return nil
        })

        let site = Site(url: "url", title: "title")
        site.guid = "myguid"
        site.id = 1

        let site2 = Site(url: "url 2", title: "title 2")
        site2.guid = "myguid 2"
        site2.id = 2

        let v1 = self.addVisit(h, site: site)
        let v2 = self.addVisit(h, site: site)
        let v3 = self.addVisit(h, site: site2)
        let v4 = self.addVisit(h, site: site2)

        self.checkVisits(h, options: nil, vs: [v1, v2, v3, v4])
        let options = QueryOptions()
        options.filter = site.id
        self.checkVisits(h, options: options, vs: [v1, v2])

        self.clear(h, visit: v1, s: true)
        self.checkVisits(h, options: options, vs: [v2])
        self.clear(h, s: true)
        self.checkVisits(h, options: nil, vs: [])

        files.remove("test.db", basePath: nil)
    }
}