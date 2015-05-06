/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCTest

class TestSQLiteHistory: XCTestCase {
    // This is a very basic test. Adds an entry, retrieves it, updates it,
    // and then clears the database.
    func testHistoryTable() {
        let files = MockFiles()
        let db = BrowserDB(files: files)
        let history = SQLiteHistory(db: db)

        let site1 = Site(url: "http://url1/", title: "title1")
        let site1Changed = Site(url: "http://url1/", title: "title1 alt")

        let siteVisit1 = SiteVisit(site: site1, date: NSDate.nowMicroseconds(), type: VisitType.Link)
        let siteVisit2 = SiteVisit(site: site1Changed, date: NSDate.nowMicroseconds() + 1000, type: VisitType.Bookmark)

        let expectation = self.expectationWithDescription("First.")
        func done() -> Success {
            expectation.fulfill()
            return succeed()
        }

        history.clearHistory()
            >>> { history.addLocalVisit(siteVisit1) }
            >>> {
                history.getSitesByFrecencyWithLimit(10)
                    >>== { (sites: Cursor) -> Success in
                        XCTAssertEqual(1, sites.count)
                        XCTAssertEqual(site1.title, sites[0]!.title)
                        XCTAssertEqual(site1.url, sites[0]!.url)
                        return succeed()
                }
            }
            >>> { history.addLocalVisit(siteVisit2) }
            >>> {
                history.getSitesByFrecencyWithLimit(10)
                    >>== { (sites: Cursor) -> Success in
                        XCTAssertEqual(1, sites.count)
                        XCTAssertEqual(site1Changed.title, sites[0]!.title)
                        XCTAssertEqual(site1Changed.url, sites[0]!.url)
                        return succeed()
                }
            }
            >>> { history.clearHistory() }
            >>> done

        waitForExpectationsWithTimeout(10.0) { error in
            return
        }
    }
}