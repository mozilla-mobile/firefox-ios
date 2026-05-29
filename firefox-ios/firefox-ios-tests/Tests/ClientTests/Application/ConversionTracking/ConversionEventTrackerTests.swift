// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

final class ConversionEventTrackerTests: XCTestCase {
    private let installTimestamp: Timestamp = 1_700_000_000_000

    private var userDefaults: MockUserDefaults!
    private var dataManager: ConversionDataManager!
    private var mockUpdater: MockConversionValueUpdater!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
        dataManager = ConversionDataManager(defaults: userDefaults)
        mockUpdater = MockConversionValueUpdater()
    }

    override func tearDown() {
        userDefaults = nil
        dataManager = nil
        mockUpdater = nil
        super.tearDown()
    }

    func testRecord_activeFirstDay_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.activeFirstDay)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 5)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .low)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_setAsDefault_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.setAsDefault)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 10)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .low)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_appOpenDay2Plus_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.appOpenDay2Plus)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 15)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_uriLoadDay2Plus_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.uriLoadDay2Plus)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 25)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_firstAdClick_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.firstAdClick)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 35)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_thirdActivityFirstWeek_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.thirdActivityFirstWeek)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 15)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_activeLastThreeWeek1_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.activeLastThreeWeek1)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 20)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_activeTwoOfFourAndThreeWeek1_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.activeTwoOfFourAndThreeWeek1)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 30)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_activated_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.activated)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 45)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .high)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecord_dailyActiveFirstWeek_emitsExpectedConversionValue() {
        let subject = createSubject()

        subject.record(.dailyActiveFirstWeek)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 55)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .high)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.lockWindow, false)
    }

    func testRecordURILoadConversionEvent_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: installTimestamp + OneDayInMilliseconds * 3)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_isNoOpOnDayZero() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_isNoOpPastTwentyEighthDay() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: installTimestamp + OneDayInMilliseconds * 29)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_firesWithinWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 25)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.coarse, .medium)
    }

    func testRecordActivityEvents_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_isNoOpPastLastAttributionWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = Set(0...6)
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 36)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_dayZero_firesActiveFirstDayOnly() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        // Day 0 is the first day
        dataManager.activeDayIndices = [0]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 5 })
        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 15 })
    }

    func testRecordActivityEvents_dayThree_firesAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        // Day 0 is the first day
        dataManager.activeDayIndices = [0, 3]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 3)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 15 })
        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 5 })
    }

    func testRecordActivityEvents_dayThirty_doesNotFireAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        // Day 0 is the first day
        dataManager.activeDayIndices = [0]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 30)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 15 })
        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 5 })
    }

    func testThirdActivityFirstWeek_firesWhenThreeWeek1Days() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        // Day 0 is the first day
        dataManager.activeDayIndices = [0, 2, 5]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 15 })
    }

    func testThirdActivityFirstWeek_doesNotFireWithOnlyTwoDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        // Day 0 is the first day
        dataManager.activeDayIndices = [0, 2]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 2)

        // Only appOpenDay2Plus should fire; thirdActivityFirstWeek would also use
        // fine=15, so we assert just one call total.
        XCTAssertEqual(mockUpdater.receivedConversionValues.count, 1)
        XCTAssertEqual(mockUpdater.receivedConversionValues.first?.fine, 15)
    }

    func testActiveLastThreeWeek1_firesWhenAnyOfDays4Through6Active() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 20 })
    }

    func testActiveLastThreeWeek1_doesNotFireWhenOnlyEarlyWeekActive() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1, 2, 3]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 3)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 20 })
    }

    func testActiveTwoOfFourAndThreeWeek1_firesWhenBothHalvesHaveTwo() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 4, 6]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 6)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 30 })
    }

    func testActiveTwoOfFourAndThreeWeek1_doesNotFireWhenOnlyOneHalfMet() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1, 2, 3, 4]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 4)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 30 })
    }

    func testDailyActiveFirstWeek_firesWhenAllSevenDaysActive() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = Set(0...6)
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 6)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 55 })
    }

    func testDailyActiveFirstWeek_doesNotFireWhenAnyDayMissing() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1, 2, 3, 4, 5]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 55 })
    }

    func testActivated_firesWhenThreeActiveDaysAndSearchInLatterHalf() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 5]
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertTrue(mockUpdater.receivedConversionValues.contains { $0.fine == 45 })
    }

    func testActivated_doesNotFireWithoutSearchInLatterHalf() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 5]
        dataManager.searchedDayIndices = [1]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 45 })
    }

    func testActivated_doesNotFireWithoutEnoughActiveDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 5]
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp + OneDayInMilliseconds * 5)

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 45 })
    }

    private func createSubject() -> ConversionEventTracker {
        return ConversionEventTracker(
            dataManager: dataManager,
            conversionValueUpdater: mockUpdater
        )
    }
}
