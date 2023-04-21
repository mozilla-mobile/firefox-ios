// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Sentry
import XCTest
@testable import Common

class LoggerLevelTests: XCTestCase {
    // MARK: - Sentry level

    func testSentryLevel_debug() {
        let subject = LoggerLevel.debug
        XCTAssertEqual(subject.sentryLevel, SentryLevel.debug)
    }

    func testSentryLevel_info() {
        let subject = LoggerLevel.info
        XCTAssertEqual(subject.sentryLevel, SentryLevel.info)
    }

    func testSentryLevel_warning() {
        let subject = LoggerLevel.warning
        XCTAssertEqual(subject.sentryLevel, SentryLevel.error)
    }

    func testSentryLevel_fatal() {
        let subject = LoggerLevel.fatal
        XCTAssertEqual(subject.sentryLevel, SentryLevel.fatal)
    }

    // MARK: - Greater than or equal

    func testGreaterThan_lessThan() {
        let subject = LoggerLevel.debug
        XCTAssertFalse(subject.isGreaterOrEqualThanLevel(LoggerLevel.info))
    }

    func testGreaterThan_equal() {
        let subject = LoggerLevel.info
        XCTAssertTrue(subject.isGreaterOrEqualThanLevel(LoggerLevel.info))
    }

    func testGreaterThan_greaterThan() {
        let subject = LoggerLevel.fatal
        XCTAssertTrue(subject.isGreaterOrEqualThanLevel(LoggerLevel.warning))
    }
}
