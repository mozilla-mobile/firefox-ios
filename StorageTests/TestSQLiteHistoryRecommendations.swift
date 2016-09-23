/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred

import XCTest

private let microsecondsPerMinute: UInt64 = 60_000_000 // 1000 * 1000 * 60
private let oneHourInMicroseconds: UInt64 = 60 * microsecondsPerMinute
private let oneDayInMicroseconds: UInt64 = 24 * oneHourInMicroseconds

class TestSQLiteHistoryRecommendations: XCTestCase {
    let files = MockFiles()


    /*
     * Verify that we return a non-recent history highlight if:
     *
     * 1. We haven't visited the site in the last 30 minutes
     * 2. We've only visited the site less than or equal to 3 times
     * 3. The site we visited has a non-empty title
     *
     */
    func testHistoryHighlights() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!

        let startTime = NSDate.nowMicroseconds()
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

        let siteVisitA1 = SiteVisit(site: siteA, date: oneHourAgo, type: .Link)
        let siteVisitB1 = SiteVisit(site: siteB, date: fifteenMinutesAgo, type: .Link)

        let siteVisitC1 = SiteVisit(site: siteC, date: oneHourAgo, type: .Link)
        let siteVisitC2 = SiteVisit(site: siteC, date: oneHourAgo + 1000, type: .Link)
        let siteVisitC3 = SiteVisit(site: siteC, date: oneHourAgo + 2000, type: .Link)
        
        let siteVisitD1 = SiteVisit(site: siteD, date: oneHourAgo, type: .Link)
        let siteVisitD2 = SiteVisit(site: siteD, date: oneHourAgo + 1000, type: .Link)
        let siteVisitD3 = SiteVisit(site: siteD, date: oneHourAgo + 2000, type: .Link)
        let siteVisitD4 = SiteVisit(site: siteD, date: oneHourAgo + 3000, type: .Link)

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

        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 2)
        XCTAssertEqual(highlights[0]!.title, "A")
        XCTAssertEqual(highlights[1]!.title, "C")
    }

    /*
     * Verify that we return a bookmark highlight if:
     * 
     * 1. Bookmark was last modified less than 3 days ago
     * 2. Bookmark has been visited at least 3 times
     * 3. Bookmark has a non-empty title
     *
     */
    func testBookmarkHighlights() {
        let db = BrowserDB(filename: "browser.db", files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)!
        let bookmarks = SQLiteBookmarkBufferStorage(db: db)

        let startTime = NSDate.nowMicroseconds()
        let oneHourAgo = startTime - oneHourInMicroseconds
        let fourDaysAgo = startTime - 4 * oneDayInMicroseconds

        let bookmarkA = BookmarkMirrorItem.bookmark("A", modified: oneHourAgo, hasDupe: false,
                                                    parentID: BookmarkRoots.MenuFolderGUID,
                                                    parentName: "Menu Bookmarks",
                                                    title: "A Bookmark", description: nil,
                                                    URI: "http://bookmarkA/", tags: "", keyword: nil)

        let bookmarkB = BookmarkMirrorItem.bookmark("B", modified: fourDaysAgo, hasDupe: false,
                                                    parentID: BookmarkRoots.MenuFolderGUID,
                                                    parentName: "Menu Bookmarks",
                                                    title: "B Bookmark", description: nil,
                                                    URI: "http://bookmarkB/", tags: "", keyword: nil)

        bookmarks.applyRecords([bookmarkA, bookmarkB]).succeeded()

        let bookmarkSiteA = Site(url: "http://bookmarkA/", title: "A Bookmark")
        let bookmarkVisitA1 = SiteVisit(site: bookmarkSiteA, date: oneHourAgo, type: .Bookmark)
        let bookmarkVisitA2 = SiteVisit(site: bookmarkSiteA, date: oneHourAgo + 1000, type: .Bookmark)
        let bookmarkVisitA3 = SiteVisit(site: bookmarkSiteA, date: oneHourAgo + 2000, type: .Bookmark)
        
        let bookmarkSiteB = Site(url: "http://bookmarkB/", title: "B Bookmark")
        let bookmarkVisitB1 = SiteVisit(site: bookmarkSiteB, date: fourDaysAgo, type: .Bookmark)
        let bookmarkVisitB2 = SiteVisit(site: bookmarkSiteB, date: fourDaysAgo + 1000, type: .Bookmark)
        let bookmarkVisitB3 = SiteVisit(site: bookmarkSiteB, date: fourDaysAgo + 2000, type: .Bookmark)
        let bookmarkVisitB4 = SiteVisit(site: bookmarkSiteB, date: fourDaysAgo + 3000, type: .Bookmark)

        history.clearHistory().succeeded()
        history.addLocalVisit(bookmarkVisitA1).succeeded()
        history.addLocalVisit(bookmarkVisitA2).succeeded()
        history.addLocalVisit(bookmarkVisitA3).succeeded()

        history.addLocalVisit(bookmarkVisitB1).succeeded()
        history.addLocalVisit(bookmarkVisitB2).succeeded()
        history.addLocalVisit(bookmarkVisitB3).succeeded()
        history.addLocalVisit(bookmarkVisitB4).succeeded()

        let highlights = history.getHighlights().value.successValue!
        XCTAssertEqual(highlights.count, 1)
        XCTAssertEqual(highlights[0]!.title, "A Bookmark")
    }
}
