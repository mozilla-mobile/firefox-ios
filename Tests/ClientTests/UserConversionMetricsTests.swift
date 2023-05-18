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
    }

    override func tearDown() {
        self.resetDefaults()
        super.tearDown()
    }

    func resetDefaults() {
        mockUserDefaults = nil
        metrics = nil
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
        guard let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date()),
              let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let fourDaysAfter = Calendar.current.date(byAdding: .day, value: 4, to: Date()),
              let fiveDaysAfter = Calendar.current.date(byAdding: .day, value: 5, to: Date()) else {
            return
        }
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        let searchesTimestamps = [fiveDaysAfter, fourDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)
        XCTAssertTrue(metrics.shouldActivateProfile())
        mockUserDefaults.set(nil, forKey: PrefsKeys.Session.firstWeekSearchesTimestamps)
        XCTAssertFalse(metrics.shouldActivateProfile())
    }

    func testShouldActivateProfile_ValidOpenAndSearchButConversionUpdated() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        mockUserDefaults.set(true, forKey: PrefsKeys.Session.didUpdateConversionValue)
        guard let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date()),
              let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let fiveDaysAfter = Calendar.current.date(byAdding: .day, value: 5, to: Date()) else {
            return
        }
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        let searchesTimestamps = [fiveDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldRecordMetric()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenTwoTimesWithSearch() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let fiveDaysAfter = Calendar.current.date(byAdding: .day, value: 5, to: Date()) else {
            return
        }
        let openTimestamps = [twoDaysAfter, oneDayAfter]
        let searchesTimestamps = [fiveDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldActivateProfile()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenThreeTimesWithoutSearch() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date()),
              let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            return
        }
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: [])

        let result = metrics.shouldActivateProfile()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenThreeTimesInMixedDatesWithSearch() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let eightDaysAfter = Calendar.current.date(byAdding: .day, value: 8, to: Date()),
              let fiveDaysAfter = Calendar.current.date(byAdding: .day, value: 5, to: Date()) else {
            return
        }
        let openTimestamps = [twoDaysAfter, oneDayAfter, eightDaysAfter]
        let searchesTimestamps = [fiveDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldActivateProfile()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenThreeTimesInInvalidDatesWithSearch() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let eightDaysAfter = Calendar.current.date(byAdding: .day, value: 8, to: Date()),
              let nineDaysAfter = Calendar.current.date(byAdding: .day, value: 9, to: Date()),
              let tenDaysAfter = Calendar.current.date(byAdding: .day, value: 10, to: Date()) else {
            return
        }
        let openTimestamps = [eightDaysAfter, nineDaysAfter, tenDaysAfter]
        let searchesTimestamps = [tenDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldActivateProfile()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenThreeTimesValidDatesWithInvalidSearchDate() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date()),
              let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let nineDaysAfter = Calendar.current.date(byAdding: .day, value: 9, to: Date()) else {
            return
        }
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        let searchesTimestamps = [nineDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldActivateProfile()
        XCTAssertFalse(result)
    }

    func testShouldActivateProfile_OpenThreeTimesValidDatesWithSearchOnDayThree() {
        let currentDate = Date.now()
        mockUserDefaults.set(currentDate, forKey: PrefsKeys.Session.FirstAppUse)
        guard let threeDaysAfter = Calendar.current.date(byAdding: .day, value: 3, to: Date()),
              let twoDaysAfter = Calendar.current.date(byAdding: .day, value: 2, to: Date()),
              let oneDayAfter = Calendar.current.date(byAdding: .day, value: 1, to: Date()),
              let fourDaysAfter = Calendar.current.date(byAdding: .day, value: 4, to: Date()) else {
            return
        }
        let openTimestamps = [threeDaysAfter, twoDaysAfter, oneDayAfter]
        let searchesTimestamps = [fourDaysAfter]
        setupOpenAndSearchTimestamps(openTimestamps: openTimestamps, searchTimestamps: searchesTimestamps)

        let result = metrics.shouldActivateProfile()
        XCTAssertTrue(result)
    }

    private func setupOpenAndSearchTimestamps(openTimestamps: [Date], searchTimestamps: [Date]) {
        mockUserDefaults.set(openTimestamps, forKey: PrefsKeys.Session.firstWeekAppOpenTimestamps)
        mockUserDefaults.set(searchTimestamps, forKey: PrefsKeys.Session.firstWeekSearchesTimestamps)
    }
}
