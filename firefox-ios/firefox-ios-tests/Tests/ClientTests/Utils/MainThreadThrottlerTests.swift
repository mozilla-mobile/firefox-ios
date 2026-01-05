// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MainThreadThrottlerTests: XCTestCase {
    struct Timing {
        static let veryLongDelay: Double = 100_000
        static let defaultTestMaxWaitTime: Double = 2
        static let shortenTestMaxWaitTime = 0.5
    }

    func testMultipleFastConsecutiveCallsAreThrottledAndExecutedAtMostOneTime() {
        let throttler = createSubject(timeout: Timing.veryLongDelay)

        let executedFirstThrottle = expectation(description: "Throttle completion fired")
        let executedSecondThrottle = expectation(description: "Second throttle completion fired")
        executedSecondThrottle.isInverted = true
        let executedThirdThrottle = expectation(description: "Third throttle completion fired")
        executedThirdThrottle.isInverted = true

        throttler.throttle { executedFirstThrottle.fulfill() }
        throttler.throttle { executedSecondThrottle.fulfill() }
        throttler.throttle { executedThirdThrottle.fulfill() }

        // Note: Timeout is based on average time it takes to run the three throttles without time delay
        // with a bit of buffer. To avoid tests taking too long, but also to confirm that we triggered 3 throttle calls
        let expectations = [executedFirstThrottle, executedSecondThrottle, executedThirdThrottle]
        wait(for: expectations, timeout: Timing.shortenTestMaxWaitTime)
    }

    func testThrottleZeroSecondThrottleExecutesAllClosures() {
        let throttler = createSubject(timeout: 0)

        let executedFirstThrottle = expectation(description: "First throttle completion fired")
        let executedSecondThrottle = expectation(description: "Second throttle completion fired")
        let executedThirdThrottle = expectation(description: "Third throttle completion fired")

        throttler.throttle { executedFirstThrottle.fulfill() }
        throttler.throttle { executedSecondThrottle.fulfill() }
        throttler.throttle { executedThirdThrottle.fulfill() }

        let expectations = [executedFirstThrottle, executedSecondThrottle, executedThirdThrottle]
        wait(for: expectations, timeout: Timing.defaultTestMaxWaitTime)
    }

    func testSecondCallAfterDelayThresholdCallsBothClosures() {
        let threshold = 0.5
        let step: Double = (threshold / 2.0)
        nonisolated(unsafe) let throttler = createSubject(timeout: threshold)

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
    private func createSubject(timeout: Double) -> MainThreadThrottler {
        return MainThreadThrottler(seconds: timeout)
    }
}
