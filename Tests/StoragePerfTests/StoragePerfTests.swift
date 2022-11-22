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


class TestSQLiteHistoryTopSitesCachePref: XCTestCase {
    func testCachePerf() {
        let files = MockFiles()
        let database = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        let prefs = MockProfilePrefs()
        let history = SQLiteHistory(db: database, prefs: prefs)

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
