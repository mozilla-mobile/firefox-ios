// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

final class ConversionDataManagerTests: XCTestCase {
    private var userDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = MockUserDefaults()
    }

    override func tearDown() {
        userDefaults = nil
        super.tearDown()
    }

    // MARK: - firstDayAfterInstallTimestamp

    func testFirstDayAfterInstallTimestamp_isNilByDefault() {
        let subject = createSubject()

        XCTAssertNil(subject.firstDayAfterInstallTimestamp)
    }

    func testFirstDayAfterInstallTimestamp_persistsValueAcrossInstances() {
        let timestamp: Timestamp = 1_700_000_000_000
        var subject = createSubject()
        subject.firstDayAfterInstallTimestamp = timestamp

        let freshSubject = createSubject()
        XCTAssertEqual(freshSubject.firstDayAfterInstallTimestamp, timestamp)
    }

    func testFirstDayAfterInstallTimestamp_settingNilRemovesValue() {
        var subject = createSubject()
        subject.firstDayAfterInstallTimestamp = 1_700_000_000_000
        subject.firstDayAfterInstallTimestamp = nil

        XCTAssertNil(subject.firstDayAfterInstallTimestamp)
    }

    // MARK: - activeDayIndices

    func testActiveDayIndices_isEmptyByDefault() {
        let subject = createSubject()

        XCTAssertTrue(subject.activeDayIndices.isEmpty)
    }

    func testActiveDayIndices_roundTripsValues() {
        var subject = createSubject()
        subject.activeDayIndices = [0, 2, 5]

        let freshSubject = createSubject()
        XCTAssertEqual(freshSubject.activeDayIndices, [0, 2, 5])
    }

    // MARK: - searchedDayIndices

    func testSearchedDayIndices_isEmptyByDefault() {
        let subject = createSubject()

        XCTAssertTrue(subject.searchedDayIndices.isEmpty)
    }

    func testSearchedDayIndices_roundTripsValues() {
        var subject = createSubject()
        subject.searchedDayIndices = [3, 4, 6]

        let freshSubject = createSubject()
        XCTAssertEqual(freshSubject.searchedDayIndices, [3, 4, 6])
    }

    func testIndicesAreIndependent() {
        var subject = createSubject()
        subject.activeDayIndices = [1]
        subject.searchedDayIndices = [5]

        XCTAssertEqual(subject.activeDayIndices, [1])
        XCTAssertEqual(subject.searchedDayIndices, [5])
    }

    // MARK: - Helper

    private func createSubject() -> ConversionDataManager {
        return ConversionDataManager(defaults: userDefaults)
    }
}
