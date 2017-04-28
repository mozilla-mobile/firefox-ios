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
        let docPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
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
        let db = BrowserDB(filename: "browser.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 500

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)

        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            for _ in 0...5 {
                history.getSitesByFrecencyWithHistoryLimit(10, includeIcon: false).succeeded()
            }
            self.stopMeasuring()
        }
    }
}

class TestSQLiteHistoryTopSitesCachePref: XCTestCase {
    func testCachePerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", files: files)
        db.attachDB(filename: "metadata.db", as: AttachedDatabaseMetadata)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 500

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)

        history.setTopSitesNeedsInvalidation()
        self.measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: true) {
            history.updateTopSitesCacheIfInvalidated().succeeded()
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
    for i in 0...count {
        let site = Site(url: "http://s\(i)ite\(i)/foo", title: "A \(i)")
        site.guid = "abc\(i)def"

        let baseMillis: UInt64 = baseInstantInMillis - 20000
        history.insertOrUpdatePlace(site.asPlace(), modified: baseMillis).succeeded()

        for j in 0...20 {
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
