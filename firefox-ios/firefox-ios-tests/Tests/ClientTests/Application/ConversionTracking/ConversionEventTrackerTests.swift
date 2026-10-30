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

    // MARK: - ConversionWindow

    func testConversionWindow_mapsDayIndicesToWindows() {
        XCTAssertEqual(ConversionWindow(dayIndex: 0), .first)
        XCTAssertEqual(ConversionWindow(dayIndex: 1), .first)
        XCTAssertEqual(ConversionWindow(dayIndex: 2), .second)
        XCTAssertEqual(ConversionWindow(dayIndex: 6), .second)
        XCTAssertEqual(ConversionWindow(dayIndex: 7), .third)
        XCTAssertEqual(ConversionWindow(dayIndex: 34), .third)
        XCTAssertNil(ConversionWindow(dayIndex: 35))
    }

    // MARK: - record

    func testRecord_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.record(.activeFirstDay, now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecord_activeFirstDay_firstWindow_emitsMedium() {
        assertRecord(.activeFirstDay, onDay: 0, emits: ConversionValue(fine: 5, coarse: .medium))
    }

    func testRecord_setAsDefault_firstWindow_emitsMedium() {
        assertRecord(.setAsDefault, onDay: 0, emits: ConversionValue(fine: 10, coarse: .medium))
    }

    func testRecord_appOpenDay2Plus_firstWindow_emitsHigh() {
        assertRecord(.appOpenDay2Plus, onDay: 1, emits: ConversionValue(fine: 15, coarse: .high))
    }

    func testRecord_appOpenDay2Plus_thirdWindow_emitsMedium() {
        assertRecord(.appOpenDay2Plus, onDay: 7, emits: ConversionValue(fine: 15, coarse: .medium))
    }

    func testRecord_uriLoadDay2Plus_firstWindow_emitsHigh() {
        assertRecord(.uriLoadDay2Plus, onDay: 1, emits: ConversionValue(fine: 25, coarse: .high))
    }

    func testRecord_uriLoadDay2Plus_thirdWindow_emitsMedium() {
        assertRecord(.uriLoadDay2Plus, onDay: 7, emits: ConversionValue(fine: 25, coarse: .medium))
    }

    func testRecord_firstAdClick_firstWindow_emitsMedium() {
        assertRecord(.firstAdClick, onDay: 1, emits: ConversionValue(fine: 35, coarse: .medium))
    }

    func testRecord_activeLastThreeWeek1_secondWindow_emitsMedium() {
        assertRecord(.activeLastThreeWeek1, onDay: 4, emits: ConversionValue(fine: 20, coarse: .medium))
    }

    func testRecord_thirdActivityFirstWeek_secondWindow_emitsMedium() {
        assertRecord(.thirdActivityFirstWeek, onDay: 2, emits: ConversionValue(fine: 22, coarse: .medium))
    }

    func testRecord_activeTwoOfFourAndThreeWeek1_secondWindow_emitsMedium() {
        assertRecord(.activeTwoOfFourAndThreeWeek1, onDay: 5, emits: ConversionValue(fine: 30, coarse: .medium))
    }

    func testRecord_activated_secondWindow_emitsHigh() {
        assertRecord(.activated, onDay: 3, emits: ConversionValue(fine: 45, coarse: .high))
    }

    func testRecord_activated_thirdWindow_emitsHigh() {
        assertRecord(.activated, onDay: 7, emits: ConversionValue(fine: 45, coarse: .high))
    }

    func testRecord_dailyActiveFirstWeek_secondWindow_emitsHigh() {
        assertRecord(.dailyActiveFirstWeek, onDay: 6, emits: ConversionValue(fine: 55, coarse: .high))
    }

    func testRecord_isNoOpForEventsNotMappedInWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.record(.setAsDefault, now: timestamp(onDay: 2))
        subject.record(.firstAdClick, now: timestamp(onDay: 2))
        subject.record(.firstAdClick, now: timestamp(onDay: 7))
        subject.record(.appOpenDay2Plus, now: timestamp(onDay: 2))
        subject.record(.uriLoadDay2Plus, now: timestamp(onDay: 2))
        subject.record(.dailyActiveFirstWeek, now: timestamp(onDay: 7))
        subject.record(.activeFirstDay, now: timestamp(onDay: 7))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecord_isNoOpPastLastWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.record(.activated, now: timestamp(onDay: 35))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecord_sendsEveryMappedEvent() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.record(.uriLoadDay2Plus, now: timestamp(onDay: 1))
        subject.record(.appOpenDay2Plus, now: timestamp(onDay: 1))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [
            ConversionValue(fine: 25, coarse: .high),
            ConversionValue(fine: 15, coarse: .high)
        ])
    }

    // MARK: - recordURILoadConversionEvent

    func testRecordURILoadConversionEvent_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: timestamp(onDay: 1))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_isNoOpOnDayZero() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_isNoOpInSecondWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: timestamp(onDay: 5))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_isNoOpPastTwentyEighthDay() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: timestamp(onDay: 29))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordURILoadConversionEvent_firesInFirstWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: timestamp(onDay: 1))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 25, coarse: .high)])
    }

    func testRecordURILoadConversionEvent_firesInThirdWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordURILoadConversionEvent(now: timestamp(onDay: 28))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 25, coarse: .medium)])
    }

    // MARK: - recordActivityEvents

    func testRecordActivityEvents_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp)

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_isNoOpPastLastWindow() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = Set(0...6)
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 35))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_dayZero_firesActiveFirstDayOnly() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0]
        let subject = createSubject()

        subject.recordActivityEvents(now: installTimestamp)

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 5, coarse: .medium)])
    }

    func testRecordActivityEvents_dayOne_firesAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 1))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 15, coarse: .high)])
    }

    func testRecordActivityEvents_secondWindow_doesNotFireAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 3]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 3))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_thirdWindow_firesAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 10]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 10))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 15, coarse: .medium)])
    }

    func testRecordActivityEvents_dayThirty_doesNotFireAppOpenDay2Plus() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 30))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testRecordActivityEvents_thirdWindow_keepsActivatedHigh() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 5]
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 10))

        XCTAssertEqual(mockUpdater.receivedConversionValues.last?.coarse, .high)
    }

    func testThirdActivityFirstWeek_firesWhenThreeWeek1Days() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 3]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 3))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 22, coarse: .medium)])
    }

    func testThirdActivityFirstWeek_doesNotFireWithOnlyTwoDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 2))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testActiveLastThreeWeek1_firesWhenAnyOfDays4Through6Active() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 5))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [ConversionValue(fine: 20, coarse: .medium)])
    }

    func testActiveLastThreeWeek1_doesNotFireWhenOnlyEarlyWeekActive() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 3]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 3))

        XCTAssertTrue(mockUpdater.receivedConversionValues.isEmpty)
    }

    func testActiveTwoOfFourAndThreeWeek1_firesWhenBothHalvesHaveTwo() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 4, 6]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 6))

        XCTAssertEqual(mockUpdater.receivedConversionValues.last, ConversionValue(fine: 30, coarse: .medium))
    }

    func testActiveTwoOfFourAndThreeWeek1_doesNotFireWhenOnlyOneHalfMet() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1, 2, 3, 4]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 4))

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 30 })
    }

    func testDailyActiveFirstWeek_firesWhenAllSevenDaysActive() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = Set(0...6)
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 6))

        XCTAssertEqual(mockUpdater.receivedConversionValues.last, ConversionValue(fine: 55, coarse: .high))
    }

    func testDailyActiveFirstWeek_doesNotFireWhenAnyDayMissing() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 1, 2, 3, 4, 5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 5))

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 55 })
    }

    func testActivated_firesWhenThreeActiveDaysAndSearchInLatterHalf() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 5]
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 5))

        XCTAssertEqual(mockUpdater.receivedConversionValues.last, ConversionValue(fine: 45, coarse: .high))
    }

    func testActivated_doesNotFireWithoutSearchInLatterHalf() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 2, 5]
        dataManager.searchedDayIndices = [1]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 5))

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 45 })
    }

    func testActivated_doesNotFireWithoutEnoughActiveDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        dataManager.activeDayIndices = [0, 5]
        dataManager.searchedDayIndices = [5]
        let subject = createSubject()

        subject.recordActivityEvents(now: timestamp(onDay: 5))

        XCTAssertFalse(mockUpdater.receivedConversionValues.contains { $0.fine == 45 })
    }

    // MARK: - Helpers

    private func createSubject() -> ConversionEventTracker {
        return ConversionEventTracker(
            dataManager: dataManager,
            conversionValueUpdater: mockUpdater
        )
    }

    private func timestamp(onDay dayIndex: Int) -> Timestamp {
        return installTimestamp + OneDayInMilliseconds * Timestamp(dayIndex)
    }

    private func assertRecord(
        _ event: ConversionEvent,
        onDay dayIndex: Int,
        emits expected: ConversionValue,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.record(event, now: timestamp(onDay: dayIndex))

        XCTAssertEqual(mockUpdater.receivedConversionValues, [expected], file: file, line: line)
    }
}
