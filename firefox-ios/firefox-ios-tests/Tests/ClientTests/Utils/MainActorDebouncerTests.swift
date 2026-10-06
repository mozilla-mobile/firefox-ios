// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
class MainActorDebouncerTests: XCTestCase {
    func testDebouncer_subSecondDelay_doesNotExecuteBeforeDelayElapses() {
        let expectation = XCTestExpectation(description: "action does not execute before a sub-second delay elapses")
        expectation.isInverted = true
        let subject = MainActorDebouncer(delay: 0.5)

        subject.call { expectation.fulfill() }

        wait(for: [expectation], timeout: 0.2)
        // The action is still pending; cancel so it can't fulfill after this test ends
        subject.cancel()
    }

    func testDebouncer_subSecondDelay_executesAfterDelayElapses() {
        let expectation = XCTestExpectation(description: "action executes once a sub-second delay elapses")
        let subject = MainActorDebouncer(delay: 0.1)

        subject.call { expectation.fulfill() }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncer_zeroDelay_executes() {
        let expectation = XCTestExpectation(description: "action executes when the delay is zero")
        let subject = MainActorDebouncer(delay: 0)

        subject.call { expectation.fulfill() }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncer_negativeDelay_executesWithoutTrapping() {
        let expectation = XCTestExpectation(description: "action executes when the delay is negative")
        let subject = MainActorDebouncer(delay: -1.0)

        subject.call { expectation.fulfill() }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncer_cancel_preventsPendingAction() {
        let expectation = XCTestExpectation(description: "cancelled action does not execute")
        expectation.isInverted = true
        let subject = MainActorDebouncer(delay: 0.1)

        subject.call { expectation.fulfill() }
        subject.cancel()

        wait(for: [expectation], timeout: 0.5)
    }

    func testDebouncer_callAfterCancel_executes() {
        let expectation = XCTestExpectation(description: "action scheduled after a cancel executes")
        let subject = MainActorDebouncer(delay: 0.1)

        subject.call { XCTFail("the cancelled action should not execute") }
        subject.cancel()
        subject.call { expectation.fulfill() }

        wait(for: [expectation], timeout: 1.0)
    }

    func testDebouncer_multipleCalls_executesOnlyTheMostRecentAction() {
        let supersededAction = XCTestExpectation(description: "superseded action does not execute")
        supersededAction.isInverted = true
        let latestAction = XCTestExpectation(description: "most recent action executes")
        let subject = MainActorDebouncer(delay: 0.1)

        subject.call { supersededAction.fulfill() }
        subject.call { latestAction.fulfill() }

        wait(for: [supersededAction, latestAction], timeout: 0.5)
    }

    // MARK: - TimeInterval.nanoseconds

    func testSubSecondInterval_convertsWithoutTruncating() {
        let interval: TimeInterval = 0.5

        XCTAssertEqual(interval.nanoseconds, 500_000_000)
    }

    func testFractionalInterval_converts() {
        let interval: TimeInterval = 0.1

        XCTAssertEqual(interval.nanoseconds, 100_000_000)
    }

    func testWholeSecondInterval_converts() {
        let interval: TimeInterval = 5

        XCTAssertEqual(interval.nanoseconds, 5_000_000_000)
    }

    func testZeroInterval_returnsZero() {
        let interval: TimeInterval = 0

        XCTAssertEqual(interval.nanoseconds, 0)
    }

    func testNegativeInterval_clampsToZero() {
        let interval: TimeInterval = -1

        XCTAssertEqual(interval.nanoseconds, 0)
    }

    func testNotANumberInterval_clampsToZero() {
        let interval = TimeInterval.nan

        XCTAssertEqual(interval.nanoseconds, 0)
    }
}
