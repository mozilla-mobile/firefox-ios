// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class ThrottlerTests: XCTestCase {
    struct Timing {
        static let veryLongDelay: Double = 100_000
        static let defaultTestMaxWaitTime: Double = 2
    }

    private var testQueue: DispatchQueue!
    private var throttler: Throttler!
    private var expectation: XCTestExpectation!
    private var testValue = 0

    override func setUp() {
        super.setUp()
        testQueue = DispatchQueue.global()
    }

    override func tearDown() {
        throttler = nil
        expectation = nil
        testQueue = nil
        super.tearDown()
    }

    func testMultipleFastConsecutiveCallsAreThrottledAndExecutedAtMostOneTime() {
        prepareTest(timeout: Timing.veryLongDelay)

        throttler.throttle { self.testValue += 1 }
        throttler.throttle { self.testValue += 1 }
        throttler.throttle { self.testValue += 1 }

        expect(value: 1)
    }

    func testThrottleZeroSecondThrottleExecutesAllClosures() {
        prepareTest(timeout: 0)

        throttler.throttle { self.testValue += 1 }
        throttler.throttle { self.testValue += 1 }

        expect(value: 2)
    }

    func testSecondCallAfterDelayThresholdCallsBothClosures() {
        let threshold: Double = 0.5
        let step: Double = (threshold / 2.0)
        prepareTest(timeout: threshold)

        // Send one call to throttler
        throttler.throttle { self.testValue = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + step) {
            XCTAssertEqual(self.testValue, 1)
        }

        // Wait briefly after our threshold and send another call
        DispatchQueue.main.asyncAfter(deadline: .now() + threshold + step) {
            self.throttler.throttle { self.testValue = 2 }
        }

        // Expect both calls to throttler have executed
        self.expect(value: 2)
    }

    // MARK: - Utility

    private func prepareTest(timeout: Double) {
        testValue = 0
        expectation = XCTestExpectation(description: "Throttle value expectation")
        throttler = Throttler(seconds: timeout, on: testQueue)
    }

    private func expect(value expected: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Timing.defaultTestMaxWaitTime) {
            guard self.testValue == expected else { XCTFail("Expected value \(expected) != \(self.testValue)."); return }
            self.expectation.fulfill()
        }
        wait(for: [expectation], timeout: Timing.defaultTestMaxWaitTime * 2.0)
    }
}
