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

    // This is a very basic test. Adds an entry, retrieves it, updates it,
    // and then clears the database.
    func testHistoryTable() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        let history = SQLiteHistory(db: db)
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

        func checkSitesByDate(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByLastVisit(10)
                >>== f
            }
        }

        func checkSitesByFrecency(f: Cursor<Site> -> Success) -> () -> Success {
            return {
                history.getSitesByFrecencyWithLimit(10)
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
        let history = SQLiteHistory(db: db)
        let bookmarks = SQLiteBookmarks(db: db)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        func updateFavicon() -> Success {
            var fav = Favicon(url: "http://url2/", date: NSDate(), type: .Icon)
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
        let history = SQLiteHistory(db: db)

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
        let history = SQLiteHistory(db: db)

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
            for i in 0...5 {
                history.getSitesByFrecencyWithLimit(10).value
            }
            self.stopMeasuring()
        }
    }
}