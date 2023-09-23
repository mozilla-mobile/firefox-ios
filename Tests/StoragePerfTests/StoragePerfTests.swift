// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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

class HistoryFrecencyPerfTests: XCTestCase {
    func testFrecencyPerf() throws {
        let files = MockFiles()
        let placesDatabasePath = URL(fileURLWithPath: (try files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("places.db").path
        let places = RustPlaces(databasePath: placesDatabasePath)
        _ = places.reopenIfClosed()
        let count = 100

        _ = places.deleteEverythingHistory().value

        populateHistoryForFrecencyCalculations(places, siteCount: count)
        self.measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: true) {
            _ = places.queryAutocomplete(matchingSearchQuery: "", limit: 10).value
            self.stopMeasuring()
        }
    }
}
