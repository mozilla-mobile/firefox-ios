// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@MainActor
class PopupThrottlerTests: XCTestCase {
    private let popupType: PopupType = .alert

    func testThatRapidAlertsUnderLimitDoNotPreventAddtlAlerts() {
        let throttler = createSubject()
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to but not over threshold
        for _ in 0..<(threshold - 1) {
            throttler.willShowAlert(type: .alert)
        }
        XCTAssertTrue(throttler.canShowAlert(type: .alert))
    }

    func testThatRapidAlertsExceedingLimitPreventAddtlAlerts() {
        let throttler = createSubject()
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            throttler.willShowAlert(type: .alert)
        }
        XCTAssertFalse(throttler.canShowAlert(type: .alert))
    }

    func testThatAlertsShownAfterSufficientDelayDoNotPreventAddtlAlerts() {
        let throttler = createSubject(resetTime: [.alert: 0.1, .popupWindow: 0.1])
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            throttler.willShowAlert(type: .alert)
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(throttler.canShowAlert(type: .alert))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testThatAlertsShownAfterSufficientDelayResetAlertCount() {
        let throttler = createSubject(resetTime: [.alert: 0.1, .popupWindow: 0.1])
        let threshold = popupType.maxPopupThreshold
        // Show alerts up to the max threshold
        for _ in 0..<threshold {
            XCTAssertTrue(throttler.canShowAlert(type: .alert))
            throttler.willShowAlert(type: .alert)
        }

        // Wait longer than the necessary threshold, and then make sure alerts are allowed
        let expectation = XCTestExpectation(description: "Throttle expectation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(throttler.canShowAlert(type: .alert))
            // Now make sure that any immediate alerts are also allowed
            throttler.willShowAlert(type: .alert)
            XCTAssertTrue(throttler.canShowAlert(type: .alert))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    private func createSubject(resetTime: [PopupType: TimeInterval] = PopupType.defaultResetTimes) -> DefaultPopupThrottler {
        let throttler = DefaultPopupThrottler(resetTime: resetTime)
        trackForMemoryLeaks(throttler)
        return throttler
    }
}
