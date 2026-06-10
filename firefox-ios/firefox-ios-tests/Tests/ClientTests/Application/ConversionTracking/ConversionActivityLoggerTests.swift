// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class ConversionActivityLoggerTests: XCTestCase {
    private let installTimestamp: Timestamp = 1_700_000_000_000

    private var userDefaults: MockUserDefaults!
    private var dataManager: ConversionDataManager!

    override func setUp() async throws {
        try await super.setUp()
        userDefaults = MockUserDefaults()
        dataManager = ConversionDataManager(defaults: userDefaults)
    }

    override func tearDown() async throws {
        userDefaults = nil
        dataManager = nil
        try await super.tearDown()
    }

    // MARK: - recordFirstDayAfterInstallTimestampIfNeeded

    func testRecordFirstDayTimestamp_setsValueWhenAbsent() {
        let subject = createSubject()

        subject.recordFirstDayAfterInstallTimestampIfNeeded(now: installTimestamp)

        XCTAssertEqual(dataManager.firstDayAfterInstallTimestamp, installTimestamp)
    }

    func testRecordFirstDayTimestamp_doesNotOverwriteExistingValue() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let later = installTimestamp + (OneDayInMilliseconds * 5)
        let subject = createSubject()

        subject.recordFirstDayAfterInstallTimestampIfNeeded(now: later)

        XCTAssertEqual(dataManager.firstDayAfterInstallTimestamp, installTimestamp)
    }

    // MARK: - recordActiveToday

    func testRecordActiveToday_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordActiveToday(now: installTimestamp)

        XCTAssertTrue(dataManager.activeDayIndices.isEmpty)
    }

    func testRecordActiveToday_insertsDayIndexZeroOnInstallDay() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordActiveToday(now: installTimestamp)

        XCTAssertEqual(dataManager.activeDayIndices, [0])
    }

    func testRecordActiveToday_insertsCorrectDayIndexForLaterDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let day5 = installTimestamp + (OneDayInMilliseconds * 5)
        let subject = createSubject()

        subject.recordActiveToday(now: day5)

        XCTAssertEqual(dataManager.activeDayIndices, [5])
    }

    func testRecordActiveToday_dedupesSameDay() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordActiveToday(now: installTimestamp)
        subject.recordActiveToday(now: installTimestamp + (OneDayInMilliseconds / 4))

        XCTAssertEqual(dataManager.activeDayIndices, [0])
    }

    func testRecordActiveToday_accumulatesDistinctDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordActiveToday(now: installTimestamp)
        subject.recordActiveToday(now: installTimestamp + (OneDayInMilliseconds * 2))
        subject.recordActiveToday(now: installTimestamp + (OneDayInMilliseconds * 6))

        XCTAssertEqual(dataManager.activeDayIndices, [0, 2, 6])
    }

    // MARK: - recordSearchedToday

    func testRecordSearchedToday_isNoOpWhenInstallTimestampMissing() {
        let subject = createSubject()

        subject.recordSearchedToday(now: installTimestamp)

        XCTAssertTrue(dataManager.searchedDayIndices.isEmpty)
    }

    func testRecordSearchedToday_insertsDayIndex() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let day3 = installTimestamp + (OneDayInMilliseconds * 3)
        let subject = createSubject()

        subject.recordSearchedToday(now: day3)

        XCTAssertEqual(dataManager.searchedDayIndices, [3])
    }

    func testRecordSearchedToday_doesNotAffectActiveDays() {
        dataManager.firstDayAfterInstallTimestamp = installTimestamp
        let subject = createSubject()

        subject.recordSearchedToday(now: installTimestamp)

        XCTAssertEqual(dataManager.searchedDayIndices, [0])
        XCTAssertTrue(dataManager.activeDayIndices.isEmpty)
    }

    // MARK: - Helper

    @MainActor
    private func createSubject() -> ConversionActivityLogger {
        let logger = ConversionActivityLogger(dataManager: dataManager)
        trackForMemoryLeaks(logger)
        return logger
    }
}
