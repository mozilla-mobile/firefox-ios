/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import Deferred
import XCTest

class MockFiles: FileAccessor {
    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        super.init(rootPath: (docPath as NSString).appendingPathComponent("testing"))
    }
}

// Start everything three months ago.
let threeMonthsInMillis: UInt64 = 3 * 30 * 24 * 60 * 60 * 1000
let threeMonthsInMicros: UInt64 = UInt64(threeMonthsInMillis) * UInt64(1000)

let baseInstantInMillis = Date.now() - threeMonthsInMillis
let baseInstantInMicros = Date.nowMicroseconds() - threeMonthsInMicros

func advanceMicrosecondTimestamp(_ timestamp: MicrosecondTimestamp, by: Int) -> MicrosecondTimestamp {
    return timestamp + UInt64(by)
}

extension Site {
    func asPlace() -> Place {
        return Place(guid: self.guid!, url: self.url, title: self.title)
    }
}

class TestSQLiteHistoryFrecencyPerf: XCTestCase {
    func testFrecencyPerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 500

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)

        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                history.getFrecentHistory().getSites(whereURLContains: nil, historyLimit: 10, bookmarksLimit: 0).succeeded()
            }
            self.stopMeasuring()
        }
    }
}

class TestSQLiteHistoryRecommendationsPerf: XCTestCase {
    func testCheckIfCleanupIsNeeded() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        history.clearHistory().succeeded()
        let doCleanup1 = history.checkIfCleanupIsNeeded().value.successValue!
        XCTAssertFalse(doCleanup1, "We should not need to perform clean-up")

        // Clean-up is triggered once we exceed 2,500 history items in a test environment.
        populateHistoryForFrecencyCalculations(history, siteCount: 2501)
        let doCleanup2 = history.checkIfCleanupIsNeeded().value.successValue!
        XCTAssertTrue(doCleanup2, "We should not need to perform clean-up")

        // This should trigger the actual clean-up operation to happen.
        history.repopulate(invalidateTopSites: true, invalidateHighlights: true).succeeded()
        let doCleanup3 = history.checkIfCleanupIsNeeded().value.successValue!
        XCTAssertFalse(doCleanup3, "We should not need to perform clean-up")
    }
}

class TestSQLiteHistoryTopSitesCachePref: XCTestCase {
    func testCachePerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 500

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)

        history.setTopSitesNeedsInvalidation()
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: true) {
            history.repopulate(invalidateTopSites: true, invalidateHighlights: true).succeeded()
            self.stopMeasuring()
        }
    }
}

// MARK - Private Test Helper Methods

private enum VisitOrigin {
    case local
    case remote
}

private func populateHistoryForFrecencyCalculations(_ history: SQLiteHistory, siteCount count: Int) {
    for i in 0..<count {
        let site = Site(url: "http://s\(i)ite\(i)/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        let baseMillis: UInt64 = baseInstantInMillis - 20000
        history.insertOrUpdatePlace(site.asPlace(), modified: baseMillis).succeeded()

        for j in 1...20 {
            let visitTime = advanceMicrosecondTimestamp(baseInstantInMicros, by: (1000000 * i) + (1000 * j))
            addVisitForSite(site, intoHistory: history, from: .local, atTime: visitTime)
            addVisitForSite(site, intoHistory: history, from: .remote, atTime: visitTime)
        }
    }
}

private func addVisitForSite(_ site: Site, intoHistory history: SQLiteHistory, from: VisitOrigin, atTime: MicrosecondTimestamp) {
    let visit = SiteVisit(site: site, date: atTime, type: VisitType.link)
    switch from {
    case .local:
        history.addLocalVisit(visit).succeeded()
    case .remote:
        history.storeRemoteVisits([visit], forGUID: site.guid!).succeeded()
    }
}
