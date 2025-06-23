// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class JSAlertThrottlerTests: XCTestCase {
    private var throttler: JSAlertThrottler!

    override func setUp() {
        super.setUp()
        throttler = JSAlertThrottler()
    }

    override func tearDown() {
        throttler = nil
        super.tearDown()
    }

    func testThatRapidAlertsUnderLimitDoNotPreventAddtlAlerts() {
        let threshold = JSAlertThrottler.Thresholds.maxConsecutiveAlerts
        // Show alerts up to but not over threshold
        for _ in 0..<(threshold - 1) {
            throttler.willShowJSAlert()
        }
        XCTAssertTrue(throttler.canShowAlert())
    }

    func testThatRapidAlertsExceedingLimitPreventAddtlAlerts() {
        let threshold = JSAlertThrottler.Thresholds.maxConsecutiveAlerts
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            throttler.willShowJSAlert()
        }
        XCTAssertFalse(throttler.canShowAlert())
    }

    func testThatAlertsShownAfterSufficientDelayDoNotPreventAddtlAlerts() {
        let customThrottler = JSAlertThrottler(resetTime: 1.0)
        let threshold = JSAlertThrottler.Thresholds.maxConsecutiveAlerts
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            customThrottler.willShowJSAlert()
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(customThrottler.canShowAlert())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testThatAlertsShownAfterSufficientDelayResetAlertCount() {
        let customThrottler = JSAlertThrottler(resetTime: 1.0)
        let threshold = JSAlertThrottler.Thresholds.maxConsecutiveAlerts
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            customThrottler.willShowJSAlert()
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(customThrottler.canShowAlert())
            // Now make sure that any immediate alerts are also allowed
            customThrottler.willShowJSAlert()
            XCTAssertTrue(customThrottler.canShowAlert())
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
}
