// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class JSAlertThrottlerTests: XCTestCase {
    private var throttler: PopupThrottler!
    private let popupType: PopupThrottler.PopupType = .alert

    override func setUp() {
        super.setUp()
        throttler = PopupThrottler()
    }

    override func tearDown() {
        throttler = nil
        super.tearDown()
    }

    func testThatRapidAlertsUnderLimitDoNotPreventAddtlAlerts() {
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to but not over threshold
        for _ in 0..<(threshold - 1) {
            throttler.willShowAlert(type: .alert)
        }
        XCTAssertTrue(throttler.canShowAlert(type: .alert))
    }

    func testThatRapidAlertsExceedingLimitPreventAddtlAlerts() {
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            throttler.willShowAlert(type: .alert)
        }
        XCTAssertFalse(throttler.canShowAlert(type: .alert))
    }

    func testThatAlertsShownAfterSufficientDelayDoNotPreventAddtlAlerts() {
        let customThrottler = PopupThrottler(resetTime: [.alert: 1.0, .popupWindow: 1.0])
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            customThrottler.willShowAlert(type: .alert)
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(customThrottler.canShowAlert(type: .alert))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }

    func testThatAlertsShownAfterSufficientDelayResetAlertCount() {
        let customThrottler = PopupThrottler(resetTime: [.alert: 1.0, .popupWindow: 1.0])
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            XCTAssertTrue(customThrottler.canShowAlert(type: .alert))
            customThrottler.willShowAlert(type: .alert)
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertTrue(customThrottler.canShowAlert(type: .alert))
            // Now make sure that any immediate alerts are also allowed
            customThrottler.willShowAlert(type: .alert)
            XCTAssertTrue(customThrottler.canShowAlert(type: .alert))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 4.0)
    }
}
