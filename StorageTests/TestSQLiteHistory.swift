/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

extension Site {
    func asPlace() -> Place {
        return Place(guid: self.guid!, url: self.url, title: self.title)
    }
}

class TestSQLiteHistory: XCTestCase {
    // Test that our visit partitioning for frecency is correct.
    func testHistoryLocalAndRemoteVisits() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!

        let siteL = Site(url: "http://url1/", title: "title local only")
        let siteR = Site(url: "http://url2/", title: "title remote only")
        let siteB = Site(url: "http://url3/", title: "title local and remote")

        siteL.guid = "locallocal12"
        siteR.guid = "remoteremote"
        siteB.guid = "bothbothboth"

        let siteVisitL1 = SiteVisit(site: siteL, date: 1437088398461000, type: VisitType.Link)
        let siteVisitL2 = SiteVisit(site: siteL, date: 1437088398462000, type: VisitType.Link)

        let siteVisitR1 = SiteVisit(site: siteR, date: 1437088398461000, type: VisitType.Link)
        let siteVisitR2 = SiteVisit(site: siteR, date: 1437088398462000, type: VisitType.Link)
        let siteVisitR3 = SiteVisit(site: siteR, date: 1437088398463000, type: VisitType.Link)

        let siteVisitBL1 = SiteVisit(site: siteB, date: 1437088398464000, type: VisitType.Link)
        let siteVisitBR1 = SiteVisit(site: siteB, date: 1437088398465000, type: VisitType.Link)

        let deferred =
        history.clearHistory()
            >>> { history.addLocalVisit(siteVisitL1) }
            >>> { history.addLocalVisit(siteVisitL2) }
            >>> { history.addLocalVisit(siteVisitBL1) }
            >>> { history.insertOrUpdatePlace(siteL.asPlace(), modified: 1437088398462) }
            >>> { history.insertOrUpdatePlace(siteR.asPlace(), modified: 1437088398463) }
            >>> { history.insertOrUpdatePlace(siteB.asPlace(), modified: 1437088398465) }

            // Do this step twice, so we exercise the dupe-visit handling.
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }
            >>> { history.storeRemoteVisits([siteVisitR1, siteVisitR2, siteVisitR3], forGUID: siteR.guid!) }

            >>> { history.storeRemoteVisits([siteVisitBR1], forGUID: siteB.guid!) }

            >>> { history.getSitesByFrecencyWithLimit(3)
                >>== { (sites: Cursor) -> Success in
                    XCTAssertEqual(3, sites.count)

                    // Two local visits beat a single later remote visit and one later local visit.
                    // Two local visits beat three remote visits.
                    XCTAssertEqual(siteL.guid!, sites[0]!.guid!)
                    XCTAssertEqual(siteB.guid!, sites[1]!.guid!)
                    XCTAssertEqual(siteR.guid!, sites[2]!.guid!)
                    return succeed()
            }

            // This marks everything as modified so we can fetch it.
            >>> history.onRemovedAccount

            // Now check that we have no duplicate visits.
            >>> { history.getModifiedHistoryToUpload()
                >>== { (places) -> Success in
                    if let (_, visits) = find(places, f: {$0.0.guid == siteR.guid!}) {
                        XCTAssertEqual(3, visits.count)
                    } else {
                        XCTFail("Couldn't find site R.")
                    }
                    return succeed()
                }
            }
        }

        XCTAssertTrue(deferred.value.isSuccess)
    }

    func testUpgrades() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)

        // This calls createOrUpdate. i.e. it may fail, but should not crash and should always return a valid SQLiteHistory object.
        let history = SQLiteHistory(db: db, version: 0)
        XCTAssertNotNil(history)

        // Insert some basic data that we'll have to upgrade
        let expectation = self.expectationWithDescription("First.")
        db.run([("INSERT INTO history (guid, url, title, server_modified, local_modified, is_deleted, should_upload) VALUES (guid, http://www.example.com, title, 5, 10, 0, 1)", nil),
                ("INSERT INTO visits (siteID, date, type, is_local) VALUES (1, 15, 1, 1)", nil),
                ("INSERT INTO favicons (url, width, height, type, date) VALUES (http://www.example.com/favicon.ico, 10, 10, 1, 20)", nil),
                ("INSERT INTO faviconSites (siteID, faviconID) VALUES (1, 1)", nil),
                ("INSERT INTO bookmarks (guid, type, url, parent, faviconID, title) VALUES (guid, 1, http://www.example.com, 0, 1, title)", nil)
        ]).upon { result in
            for i in 1...BrowserTable.DefaultVersion {
                let history = SQLiteHistory(db: db, version: i)
                XCTAssertNotNil(history)
            }

            // This checks to make sure updates actually work (or at least that they don't crash :))
            var err: NSError? = nil
            db.transaction(&err, callback: { (connection, err) -> Bool in
                for i in 0...BrowserTable.DefaultVersion {
                    let table = BrowserTable(version: i)
                    switch db.updateTable(connection, table: table) {
                    case .Updated:
                        XCTAssertTrue(true, "Update to \(i) succeeded")
                    default:
                        XCTFail("Update to version \(i) failed")
                        return false
                    }
                }
                return true
            })

            if err != nil {
                XCTFail("Error creating a transaction \(err)")
            }
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testDomainUpgrade() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!

        let site = Site(url: "http://www.example.com/test1.1", title: "title one")
        var err: NSError? = nil

        // Insert something with an invalid domainId. We have to manually do this since domains are usually hidden.
        db.withWritableConnection(&err, callback: { (connection, err) -> Int in
            let insert = "INSERT INTO \(TableHistory) (guid, url, title, local_modified, is_deleted, should_upload, domain_id) " +
                         "?, ?, ?, ?, ?, ?, ?"
            let args: Args = [Bytes.generateGUID(), site.url, site.title, NSDate.nowNumber(), 0, 0, -1]
            err = connection.executeChange(insert, withArgs: args)
            return 0
        })

        // Now insert it again. This should update the domain
        history.addLocalVisit(SiteVisit(site: site, date: NSDate.nowMicroseconds(), type: VisitType.Link))

        // DomainID isn't normally exposed, so we manually query to get it
        let results = db.withReadableConnection(&err, callback: { (connection, err) -> Cursor<Int> in
            let sql = "SELECT domain_id FROM \(TableHistory) WHERE url = ?"
            let args: Args = [site.url]
            return connection.executeQuery(sql, factory: IntFactory, withArgs: args)
        })
        XCTAssertNotEqual(results[0]!, -1, "Domain id was updated")
    }

    func testDomains() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!

        let initialGuid = Bytes.generateGUID()
        let site11 = Site(url: "http://www.example.com/test1.1", title: "title one")
        let site12 = Site(url: "http://www.example.com/test1.2", title: "title two")
        let site13 = Place(guid: initialGuid, url: "http://www.example.com/test1.3", title: "title three")
        let site3 = Site(url: "http://www.example2.com/test1", title: "title three")
        let expectation = self.expectationWithDescription("First.")

        history.clearHistory().bind({ success in
            return all([history.addLocalVisit(SiteVisit(site: site11, date: NSDate.nowMicroseconds(), type: VisitType.Link)),
                        history.addLocalVisit(SiteVisit(site: site12, date: NSDate.nowMicroseconds(), type: VisitType.Link)),
                        history.addLocalVisit(SiteVisit(site: site3, date: NSDate.nowMicroseconds(), type: VisitType.Link))])
        }).bind({ (results: [Maybe<()>]) in
            return history.insertOrUpdatePlace(site13, modified: NSDate.nowMicroseconds())
        }).bind({ guid in
            XCTAssertEqual(guid.successValue!, initialGuid, "Guid is correct")
            return history.getSitesByFrecencyWithLimit(10)
        }).bind({ (sites: Maybe<Cursor<Site>>) -> Success in
            XCTAssert(sites.successValue!.count == 2, "2 sites returned")
            return history.removeSiteFromTopSites(site11)
        }).bind({ success in
            XCTAssertTrue(success.isSuccess, "Remove was successful")
            return history.getSitesByFrecencyWithLimit(10)
        }).upon({ (sites: Maybe<Cursor<Site>>) in
            XCTAssert(sites.successValue!.count == 1, "1 site returned")
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }

    // This is a very basic test. Adds an entry, retrieves it, updates it,
    // and then clears the database.
    func testHistoryTable() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!
        let bookmarks = SQLiteBookmarks(db: db)

        let site1 = Site(url: "http://url1/", title: "title one")
        let site1Changed = Site(url: "http://url1/", title: "title one alt")

        let siteVisit1 = SiteVisit(site: site1, date: NSDate.nowMicroseconds(), type: VisitType.Link)
        let siteVisit2 = SiteVisit(site: site1Changed, date: NSDate.nowMicroseconds() + 1000, type: VisitType.Bookmark)

        let site2 = Site(url: "http://url2/", title: "title two")
        let siteVisit3 = SiteVisit(site: site2, date: NSDate.nowMicroseconds() + 2000, type: VisitType.Link)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func checkSitesByFrecency(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithLimit(10)
                    >>== f
            }
        }

        func checkSitesByDate(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByLastVisit(10)
                >>== f
            }
        }

        func checkSitesWithFilter(filter: String, f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithLimit(10, whereURLContains: filter)
                >>== f
            }
        }

        func checkDeletedCount(expected: Int) -> () -> Success {
            return {
                history.getDeletedHistoryToUpload()
                >>== { guids in
                    XCTAssertEqual(expected, guids.count)
                    return succeed()
                }
            }
        }

        history.clearHistory()
            >>>
            { history.addLocalVisit(siteVisit1) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1.title, sites[0]!.title)
                XCTAssertEqual(site1.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>>
            { history.addLocalVisit(siteVisit2) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(1, sites.count)
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site1Changed.url, sites[0]!.url)
                sites.close()
                return succeed()
            }
            >>>
            { history.addLocalVisit(siteVisit3) }
            >>> checkSitesByFrecency
            { (sites: Cursor) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of frecency.
                XCTAssertEqual(site1Changed.title, sites[0]!.title)
                XCTAssertEqual(site2.title, sites[1]!.title)
                return succeed()
            }
            >>> checkSitesByDate
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(2, sites.count)
                // They're in order of date last visited.
                let first = sites[0]!
                let second = sites[1]!
                XCTAssertEqual(site2.title, first.title)
                XCTAssertEqual(site1Changed.title, second.title)
                XCTAssertTrue(siteVisit3.date == first.latestVisit!.date)
                return succeed()
            }
            >>> checkSitesWithFilter("two")
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(1, sites.count)
                let first = sites[0]!
                XCTAssertEqual(site2.title, first.title)
                return succeed()
            }
            >>>
            checkDeletedCount(0)
            >>>
            { history.removeHistoryForURL("http://url2/") }
            >>>
            checkDeletedCount(1)
            >>> checkSitesByFrecency
                { (sites: Cursor) -> Success in
                    XCTAssertEqual(1, sites.count)
                    // They're in order of frecency.
                    XCTAssertEqual(site1Changed.title, sites[0]!.title)
                    return succeed()
            }
            >>>
            { history.clearHistory() }
            >>>
            checkDeletedCount(0)
            >>> checkSitesByDate
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> checkSitesByFrecency
            { (sites: Cursor<Site>) -> Success in
                XCTAssertEqual(0, sites.count)
                return succeed()
            }
            >>> done


        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }

    func testFaviconTable() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!
        let bookmarks = SQLiteBookmarks(db: db)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func updateFavicon() -> Success {
            let fav = Favicon(url: "http://url2/", date: NSDate(), type: .Icon)
            fav.id = 1
            let site = Site(url: "http://bookmarkedurl/", title: "My Bookmark")
            return history.addFavicon(fav, forSite: site) >>> { return succeed() }
        }

        func checkFaviconForBookmarkIsNil() -> Success {
            return bookmarks.bookmarksByURL("http://bookmarkedurl/".asURL!) >>== { results in
                XCTAssertEqual(1, results.count)
                XCTAssertNil(results[0]?.favicon)
                return succeed()
            }
        }

        func checkFaviconWasSetForBookmark() -> Success {
            return history.getFaviconsForBookmarkedURL("http://bookmarkedurl/") >>== { results in
                XCTAssertEqual(1, results.count)
                if let actualFaviconURL = results[0]??.url {
                    XCTAssertEqual("http://url2/", actualFaviconURL)
                }
                return succeed()
            }
        }

        func removeBookmark() -> Success {
            return bookmarks.removeByURL("http://bookmarkedurl/")
        }

        func checkFaviconWasRemovedForBookmark() -> Success {
            return history.getFaviconsForBookmarkedURL("http://bookmarkedurl/") >>== { results in
                XCTAssertEqual(0, results.count)
                return succeed()
            }
        }

        history.clearAllFavicons()
            >>> bookmarks.clearBookmarks
            >>> { bookmarks.addToMobileBookmarks("http://bookmarkedurl/".asURL!, title: "Title", favicon: nil) }
            >>> checkFaviconForBookmarkIsNil
            >>> updateFavicon
            >>> checkFaviconWasSetForBookmark
            >>> removeBookmark
            >>> checkFaviconWasRemovedForBookmark
            >>> done

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }
}

class TestSQLiteHistoryTransactionUpdate: XCTestCase {
    func testUpdateInTransaction() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!

        history.clearHistory().value
        let site = Site(url: "http://site/foo", title: "AA")
        site.guid = "abcdefghiabc"

        history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).value

        let local = SiteVisit(site: site, date: Timestamp(1000 * 1437088398461), type: VisitType.Link)
        XCTAssertTrue(history.addLocalVisit(local).value.isSuccess)
    }
}

class TestSQLiteHistoryFrecencyPerf: XCTestCase {
    func testFrecencyPerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)!

        let count = 500

        history.clearHistory().value
        for i in 0...count {
            let site = Site(url: "http://s\(i)ite\(i)/foo", title: "A \(i)")
            site.guid = "abc\(i)def"

            history.insertOrUpdatePlace(site.asPlace(), modified: 1234567890).value

            for j in 0...20 {
                let local = SiteVisit(site: site, date: Timestamp(1000 * (1437088398461 + (1000 * i) + j)), type: VisitType.Link)
                XCTAssertTrue(history.addLocalVisit(local).value.isSuccess)
            }

            var remotes = [Visit]()
            for j in 0...20 {
                remotes.append(SiteVisit(site: site, date: Timestamp(1000 * (1437088399461 + (1000 * i) + j)), type: VisitType.Link))
            }
            history.storeRemoteVisits(remotes, forGUID: site.guid!).value
        }

        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                history.getSitesByFrecencyWithLimit(10, includeIcon: false).value
            }
            self.stopMeasuring()
        }
    }
}