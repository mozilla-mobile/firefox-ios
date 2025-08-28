// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class GCDThrottlerTests: XCTestCase {
    struct Timing {
        static let veryLongDelay: Double = 100_000
        static let defaultTestMaxWaitTime: Double = 2
    }

    private var testQueue: DispatchQueue!

    override func setUp() {
        super.setUp()
        testQueue = DispatchQueue(label: "tests.gcdthrottler.serial")
    }

    override func tearDown() {
        testQueue = nil
        super.tearDown()
    }

    func testMultipleFastConsecutiveCallsAreThrottledAndExecutedAtMostOneTime() {
        let throttler = createSubject(timeout: Timing.veryLongDelay)

        let firedOnce = expectation(description: "Throttle completion fired")
        firedOnce.expectedFulfillmentCount = 1
        firedOnce.assertForOverFulfill = true

        throttler.throttle { firedOnce.fulfill() }
        throttler.throttle { firedOnce.fulfill() }
        throttler.throttle { firedOnce.fulfill() }

        wait(for: [firedOnce], timeout: Timing.defaultTestMaxWaitTime)
    }

    func testThrottleZeroSecondThrottleExecutesAllClosures() {
        let throttler = createSubject(timeout: 0)

        let executedFirstThrottle = expectation(description: "First throttle completion fired")
        let executedSecondThrottle = expectation(description: "Second throttle completion fired")

        throttler.throttle { executedFirstThrottle.fulfill() }
        throttler.throttle { executedSecondThrottle.fulfill() }

        wait(for: [executedFirstThrottle, executedSecondThrottle], timeout: Timing.defaultTestMaxWaitTime)
    }

    func testSecondCallAfterDelayThresholdCallsBothClosures() {
        let threshold = 0.5
        let step: Double = (threshold / 2.0)
        let throttler = createSubject(timeout: threshold)

        // Send one call to throttler
        let executedFirstThrottle = expectation(description: "First throttle completion fired")
        let executedSecondThrottle = expectation(description: "Second throttle completion fired")

        throttler.throttle { executedFirstThrottle.fulfill() }

        // Wait briefly after our threshold and send another call
        DispatchQueue.main.asyncAfter(deadline: .now() + threshold + step) {
            throttler.throttle { executedSecondThrottle.fulfill() }
        }

        wait(for: [executedFirstThrottle, executedSecondThrottle], timeout: Timing.defaultTestMaxWaitTime)
    }

    // MARK: - Utility
    private func createSubject(timeout: Double) -> GCDThrottler {
        return GCDThrottler(seconds: timeout, on: testQueue)
    }
}
