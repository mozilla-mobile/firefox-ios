/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred
import WebImage

import XCTest

private let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
private let oneHourInMicroseconds: UInt64 = 60 * microsecondsPerMinute
private let oneDayInMicroseconds: UInt64 = 24 * oneHourInMicroseconds

class TestSQLiteHistoryRecommendations: XCTestCase {
    let files = MockFiles()

    var db: BrowserDB!
    var prefs: MockProfilePrefs!
    var history: SQLiteHistory!
    var bookmarks: SQLiteBookmarkBufferStorage!

    override func setUp() {
        super.setUp()

        db = BrowserDB(filename: "browser.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        prefs = MockProfilePrefs()
        history = SQLiteHistory(db: db, prefs: prefs)
        bookmarks = SQLiteBookmarkBufferStorage(db: db)
    }

    override func tearDown() {
        // Clear out anything we might have changed on disk
        history.clearHistory().succeeded()
        history.clearHighlights().succeeded()
        db.run("DELETE FROM \(AttachedTablePageMetadata)").succeeded()
        db.run("DELETE FROM \(TableActivityStreamBlocklist)").succeeded()

        SDWebImageManager.shared().imageCache.clearDisk()
        SDWebImageManager.shared().imageCache.clearMemory()

        super.tearDown()
    }

    /*
     * Verify that we return a non-recent history highlight if:
     *
     * 1. We haven't visited the site in the last 30 minutes
     * 2. We've only visited the site less than or equal to 3 times
     * 3. The site we visited has a non-empty title
     *
     */
    func testHistoryHighlights() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds
        let fifteenMinutesAgo = startTime - 15 * microsecondsPerMinute

        /*
         * Site A: 1 visit, 1 hour ago = highlight
         * Site B: 1 visits, 15 minutes ago = non-highlight
         * Site C: 3 visits, 1 hour ago = highlight
         * Site D: 4 visits, 1 hour ago = non-highlight
         */
        let siteA = Site(url: "http://siteA/", title: "A")
        let siteB = Site(url: "http://siteB/", title: "B")
        let siteC = Site(url: "http://siteC/", title: "C")
        let siteD = Site(url: "http://siteD/", title: "D")

        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)
        let siteVisitB1 = SiteVisit(site: siteB, date: fifteenMinutesAgo, type: .link)

        let siteVisitC1 = SiteVisit(site: siteC, date: oneHourAgo + 1, type: .link)
        let siteVisitC2 = SiteVisit(site: siteC, date: oneHourAgo + 1000, type: .link)
        let siteVisitC3 = SiteVisit(site: siteC, date: oneHourAgo + 2000, type: .link)
        
        let siteVisitD1 = SiteVisit(site: siteD, date: oneHourAgo, type: .link)
        let siteVisitD2 = SiteVisit(site: siteD, date: oneHourAgo + 1000, type: .link)
        let siteVisitD3 = SiteVisit(site: siteD, date: oneHourAgo + 2000, type: .link)
        let siteVisitD4 = SiteVisit(site: siteD, date: oneHourAgo + 3000, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.addLocalVisit(siteVisitB1).succeeded()

        history.addLocalVisit(siteVisitC1).succeeded()
        history.addLocalVisit(siteVisitC2).succeeded()
        history.addLocalVisit(siteVisitC3).succeeded()

        history.addLocalVisit(siteVisitD1).succeeded()
        history.addLocalVisit(siteVisitD2).succeeded()
        history.addLocalVisit(siteVisitD3).succeeded()
        history.addLocalVisit(siteVisitD4).succeeded()

        history.invalidateHighlights().succeeded()
        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 2)
        XCTAssertEqual(highlights[0]!.title, "A")
        XCTAssertEqual(highlights[1]!.title, "C")
    }


    /*
     * Verify that we do not return a highlight if
     * its domain is in the blacklist
     *
     */
    func testBlacklistHighlights() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds
        let fifteenMinutesAgo = startTime - 15 * microsecondsPerMinute

        /*
         * Site A: 1 visit, 1 hour ago = highlight that is on the blacklist
         * Site B: 1 visits, 15 minutes ago = non-highlight
         * Site C: 3 visits, 1 hour ago = highlight that is on the blacklist
         * Site D: 4 visits, 1 hour ago = non-highlight
         */
        let siteA = Site(url: "http://www.google.com", title: "A")
        let siteB = Site(url: "http://siteB/", title: "B")
        let siteC = Site(url: "http://www.search.yahoo.com/", title: "C")
        let siteD = Site(url: "http://siteD/", title: "D")

        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)
        let siteVisitB1 = SiteVisit(site: siteB, date: fifteenMinutesAgo, type: .link)

        let siteVisitC1 = SiteVisit(site: siteC, date: oneHourAgo, type: .link)
        let siteVisitC2 = SiteVisit(site: siteC, date: oneHourAgo + 1000, type: .link)
        let siteVisitC3 = SiteVisit(site: siteC, date: oneHourAgo + 2000, type: .link)

        let siteVisitD1 = SiteVisit(site: siteD, date: oneHourAgo, type: .link)
        let siteVisitD2 = SiteVisit(site: siteD, date: oneHourAgo + 1000, type: .link)
        let siteVisitD3 = SiteVisit(site: siteD, date: oneHourAgo + 2000, type: .link)
        let siteVisitD4 = SiteVisit(site: siteD, date: oneHourAgo + 3000, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.addLocalVisit(siteVisitB1).succeeded()

        history.addLocalVisit(siteVisitC1).succeeded()
        history.addLocalVisit(siteVisitC2).succeeded()
        history.addLocalVisit(siteVisitC3).succeeded()

        history.addLocalVisit(siteVisitD1).succeeded()
        history.addLocalVisit(siteVisitD2).succeeded()
        history.addLocalVisit(siteVisitD3).succeeded()
        history.addLocalVisit(siteVisitD4).succeeded()

        history.invalidateHighlights().succeeded()
        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 0)
    }

    /*
     * Verify that we return the most recent highlight per domain
     */
    func testMostRecentUniqueDomainReturnedInHighlights() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds
        let twoHoursAgo = startTime - 2 * oneHourInMicroseconds

        /*
         * Site A: 1 visit, 1 hour ago = highlight
         * Site C: 2 visits, 2 hours ago = highlight with the same domain
         */
        let siteA = Site(url: "http://www.foo.com/", title: "A")
        let siteC = Site(url: "http://m.foo.com/", title: "C")

        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)

        let siteVisitC1 = SiteVisit(site: siteC, date: twoHoursAgo, type: .link)
        let siteVisitC2 = SiteVisit(site: siteC, date: twoHoursAgo + 1000, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.addLocalVisit(siteVisitC1).succeeded()
        history.addLocalVisit(siteVisitC2).succeeded()

        history.invalidateHighlights().succeeded()
        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 1)
        XCTAssertEqual(highlights[0]!.title, "A")
    }

    func testMetadataReturnedInHighlights() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds

        let siteA = Site(url: "http://siteA.com", title: "Site A")
        let siteB = Site(url: "http://siteB.com/", title: "Site B")
        let siteC = Site(url: "http://siteC.com/", title: "Site C")

        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)
        let siteVisitB1 = SiteVisit(site: siteB, date: oneHourAgo + 1000, type: .link)

        let siteVisitC1 = SiteVisit(site: siteC, date: oneHourAgo, type: .link)
        let siteVisitC2 = SiteVisit(site: siteC, date: oneHourAgo + 1000, type: .link)
        let siteVisitC3 = SiteVisit(site: siteC, date: oneHourAgo + 2000, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.addLocalVisit(siteVisitB1).succeeded()

        history.addLocalVisit(siteVisitC1).succeeded()
        history.addLocalVisit(siteVisitC2).succeeded()
        history.addLocalVisit(siteVisitC3).succeeded()

        // add metadata for 2 of the sites
        let metadata = SQLiteMetadata(db: db)
        let pageA = PageMetadata(id: nil, siteURL: siteA.url, mediaURL: "http://image.com",
                                title: siteA.title, description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        metadata.storeMetadata(pageA, forPageURL: siteA.url.asURL!, expireAt: Date.now() + 3000).succeeded()
        let pageB = PageMetadata(id: nil, siteURL: siteB.url, mediaURL: "http://image.com",
                                 title: siteB.title, description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        metadata.storeMetadata(pageB, forPageURL: siteB.url.asURL!, expireAt: Date.now() + 3000).succeeded()
        let pageC = PageMetadata(id: nil, siteURL: siteC.url, mediaURL: "http://image.com",
                                 title: siteC.title, description: "Test Description", type: nil, providerName: nil, mediaDataURI: nil, cacheImages: false)
        metadata.storeMetadata(pageC, forPageURL: siteC.url.asURL!, expireAt: Date.now() + 3000).succeeded()

        history.invalidateHighlights().succeeded()
        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 3)

        for highlight in highlights {
            XCTAssertNotNil(highlight?.metadata)
            XCTAssertNotNil(highlight?.metadata?.mediaURL)
        }
    }

    func testRemoveHighlightForURL() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds

        let siteA = Site(url: "http://siteA/", title: "A")
        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.invalidateHighlights().succeeded()
        var highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 1)
        XCTAssertEqual(highlights[0]!.title, "A")

        history.removeHighlightForURL(siteA.url).succeeded()
        history.invalidateHighlights().succeeded()
        highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 0)
    }

    func testClearHighlightsCache() {
        let startTime = Date.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds

        let siteA = Site(url: "http://siteA/", title: "A")
        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .link)

        history.clearHistory().succeeded()
        history.addLocalVisit(siteVisitA1).succeeded()

        history.invalidateHighlights().succeeded()
        var highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 1)
        XCTAssertEqual(highlights[0]!.title, "A")

        history.clearHighlights().succeeded()
        highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 0)
    }
}

class TestSQLiteHistoryRecommendationsPerf: XCTestCase {
    func testRecommendationPref() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)
        let bookmarks = SQLiteBookmarkBufferStorage(db: db)

        let count = 500

        history.clearHistory().succeeded()
        populateForRecommendationCalculations(history, bookmarks: bookmarks, historyCount: count, bookmarkCount: count)
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                history.invalidateHighlights().succeeded()
            }
            self.stopMeasuring()
        }
    }
}

private func populateForRecommendationCalculations(_ history: SQLiteHistory, bookmarks: SQLiteBookmarkBufferStorage, historyCount: Int, bookmarkCount: Int) {
    let baseMillis: UInt64 = baseInstantInMillis - 20000

    for i in 0..<historyCount {
        let site = Site(url: "http://s\(i)ite\(i)/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        history.insertOrUpdatePlace(site.asPlace(), modified: baseMillis).succeeded()

        for j in 0...20 {
            let visitTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i) + (1000 * j))
            addVisitForSite(site, intoHistory: history, from: .local, atTime: visitTime)
            addVisitForSite(site, intoHistory: history, from: .remote, atTime: visitTime)
        }
    }

    let bookmarkItems: [BookmarkMirrorItem] = (0..<bookmarkCount).map { i in
        let modifiedTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i))
        let bookmarkSite = Site(url: "http://bookmark-\(i)/", title: "\(i) Bookmark")
        bookmarkSite.guid = "bookmark-\(i)"
        
        addVisitForSite(bookmarkSite, intoHistory: history, from: .local, atTime: modifiedTime)
        addVisitForSite(bookmarkSite, intoHistory: history, from: .remote, atTime: modifiedTime)
        addVisitForSite(bookmarkSite, intoHistory: history, from: .local, atTime: modifiedTime)
        addVisitForSite(bookmarkSite, intoHistory: history, from: .remote, atTime: modifiedTime)
        
        return BookmarkMirrorItem.bookmark("http://bookmark-\(i)/", modified: modifiedTime, hasDupe: false,
                                            parentID: BookmarkRoots.MenuFolderGUID,
                                            parentName: "Menu Bookmarks",
                                            title: "\(i) Bookmark", description: nil,
                                            URI: "http://bookmark-\(i)/", tags: "", keyword: nil)
    }

    bookmarks.applyRecords(bookmarkItems).succeeded()
}
