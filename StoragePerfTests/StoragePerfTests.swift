// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
@testable import Storage
import XCTest

class MockFiles: FileAccessor {
    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        super.init(rootPath: (docPath as NSString).appendingPathComponent("testing"))
    }
}

class TestSQLiteHistoryFrecencyPerf: XCTestCase {
    func testFrecencyPerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 100

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: true) {
                history.getFrecentHistory().getSites(matchingSearchQuery: nil, limit: 10).succeeded()
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

        let maxRows = UInt(250)

        let doCleanup1 = history.checkIfCleanupIsNeeded(maxHistoryRows: maxRows).value.successValue!
        XCTAssertFalse(doCleanup1, "We should not need to perform clean-up")

        // Clean-up is triggered once we exceed 2,500 history items in a test environment.
        populateHistoryForFrecencyCalculations(history, siteCount: Int(maxRows + 1))
        let doCleanup2 = history.checkIfCleanupIsNeeded(maxHistoryRows: maxRows).value.successValue!
        XCTAssertTrue(doCleanup2, "We should not need to perform clean-up")

        // Trigger the actual clean-up operation to happen and re-check.
        _ = db.run(history.cleanupOldHistory(numberOfRowsToPrune: 50)).value.successValue
        let doCleanup3 = history.checkIfCleanupIsNeeded(maxHistoryRows: maxRows).value.successValue!
        XCTAssertFalse(doCleanup3, "We should not need to perform clean-up")
    }
}

class TestSQLiteHistoryTopSitesCachePref: XCTestCase {
    func testCachePerf() {
        let files = MockFiles()
        let db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: db, prefs: prefs)

        let count = 100

        history.clearHistory().succeeded()
        populateHistoryForFrecencyCalculations(history, siteCount: count)

        history.setTopSitesNeedsInvalidation()
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: true) {
            history.repopulate(invalidateTopSites: true).succeeded()
            self.stopMeasuring()
        }
    }
}
