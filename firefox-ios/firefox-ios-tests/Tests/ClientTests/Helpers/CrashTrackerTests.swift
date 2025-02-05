// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class CrashTrackerTests: XCTestCase {
    var logger: CrashingMockLogger!
    var userDefaults: MockUserDefaults!

    override func setUp() {
        super.setUp()

        userDefaults = MockUserDefaults()
        logger = CrashingMockLogger()
    }

    override func tearDown() {
        userDefaults = nil
        logger = nil

        super.tearDown()
    }

    func testHasCrashedInLast3Days_whenDidNotUpdateData_thenDidNotCrash() {
        let subject = createSubject()
        XCTAssertFalse(subject.hasCrashedInLast3Days)
    }

    func testHasCrashedInLast3Days_whenLoggerHasCrashedInLastSession_thenCrash() {
        logger?.enableCrashOnLastLaunch = true
        let subject = createSubject()
        subject.updateData()

        XCTAssertTrue(subject.hasCrashedInLast3Days)
    }

    func testHasCrashedInLast3Days_whenLoggerHasCrashedYesterday_thenCrash() {
        logger?.enableCrashOnLastLaunch = true
        let subject = createSubject()
        subject.updateData(currentDate: Date().dayBefore)

        XCTAssertTrue(subject.hasCrashedInLast3Days)
    }

    func testHasCrashedInLast3Days_loggerHasCrashedLastWeek_thenDidNotCrash() {
        logger?.enableCrashOnLastLaunch = true
        let subject = createSubject()
        subject.updateData(currentDate: Date().lastWeek)

        XCTAssertFalse(subject.hasCrashedInLast3Days)
    }

    // MARK: Helpers

    func createSubject() -> CrashTracker {
        return DefaultCrashTracker(logger: logger, userDefaults: userDefaults)
    }
}
