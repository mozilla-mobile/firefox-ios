// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import Client
import XCTest

import Common
import Foundation
import Shared
import StoreKit

final class UserConversionMetricsTests: XCTestCase {
    var mockUserDefaults: MockUserDefaults!
    var metrics: UserConversionMetrics!

    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        metrics = UserConversionMetrics()
        metrics.userDefaults = mockUserDefaults
        self.resetDefaults()
    }

    override func tearDown() {
        self.resetDefaults()
        super.tearDown()
    }

    func resetDefaults() {
        UserDefaults.standard.removeObject(forKey: "appOpenTimestampsTest")
        UserDefaults.standard.removeObject(forKey: "searchesTimestampsTest")
        UserDefaults.standard.removeObject(forKey: "didUpdateConversionValueTest")
    }

    func testShouldRecordMetric() {
        // Set the first app use to the current time (in milliseconds)
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)

        // Check that the method returns true
        XCTAssertTrue(metrics.shouldRecordMetric())
        // Set the first app use to more than a week ago
        let moreThanAWeekAgo = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        mockUserDefaults.set(UInt64(moreThanAWeekAgo.timeIntervalSince1970 * 1000), forKey: PrefsKeys.Session.FirstAppUse)

        // Check that the method now returns false
        XCTAssertFalse(metrics.shouldRecordMetric())
    }

    func testShouldActivateProfile() {
        // Set the first app use to the current time (in milliseconds)
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let fourDaysAfter = Calendar.current.date(byAdding: .day, value: 4, to: Date())!
        let fiveDaysAfter = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        mockUserDefaults.set(openTimestamps, forKey: PrefsKeys.Session.firstWeekAppOpenTimestamps)
        let searchesTimestamps = [fiveDaysAfter, fourDaysAfter]
        mockUserDefaults.set(searchesTimestamps, forKey: PrefsKeys.Session.firstWeekSearchesTimestamps)
        XCTAssertTrue(metrics.shouldActivateProfile())
        mockUserDefaults.set(nil, forKey: PrefsKeys.Session.firstWeekSearchesTimestamps)
        XCTAssertFalse(metrics.shouldActivateProfile())
    }
}
