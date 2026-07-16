// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Shared

final class MainActorCachedValueTests: XCTestCase {
    @MainActor private final class Counter { var value = 0 }

    private func testCounter(_ counter: Counter, expectedValue: Int) {
        MainActor.assumeIsolated {
            XCTAssertEqual(counter.value, expectedValue)
        }
    }

    func testMainActorCachedValue_repeatedCalls_onlyEvaluateValueOnce() {
        let counter = Counter()

        let evaluation: @MainActor @Sendable () -> String = {
            counter.value += 1
            return "value"
        }

        let cachedValue = MainActorCachedValue(evaluation)

        testCounter(counter, expectedValue: 0)
        XCTAssertEqual(cachedValue.value, "value")
        testCounter(counter, expectedValue: 1)
        XCTAssertEqual(cachedValue.value, "value")
        testCounter(counter, expectedValue: 1)
    }

    func testMainActorCachedValue_multipleAsyncCalls_doNotDeadlock() {
        let expectation = XCTestExpectation(description: "Completed")
        let delay: TimeInterval = 0.25
        let evaluation: @MainActor @Sendable () -> String = {
            // For this test, delay evaluation to coerce
            // multiple async evaluations to overlap
            Thread.sleep(forTimeInterval: delay)
            return "value"
        }

        let cachedValue = MainActorCachedValue(evaluation)

        let callCount = 5
        let lock = NSLock()
        nonisolated(unsafe) var resolved = 0
        for _ in 0..<callCount {
            DispatchQueue.global().async {
                XCTAssertEqual(cachedValue.value, "value")
                lock.lock()
                resolved += 1
                if resolved == callCount {
                    expectation.fulfill()
                }
                lock.unlock()
            }
        }

        wait(for: [expectation], timeout: delay * Double(callCount + 1))
    }
}
