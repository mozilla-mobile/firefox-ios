// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class ThrottlerTests: XCTestCase {
    func testThrottle_1000SecondsThrottle_doesntCall() {
        let subject = Throttler(seconds: 100000, on: DispatchQueue.global())
        var throttleCalled = 0
        subject.throttle {
            throttleCalled += 1
        }

        subject.throttle {
            throttleCalled += 1
        }

        XCTAssertEqual(throttleCalled, 0, "Throttle isn't called since delay is high")
    }

    func testThrottle_zeroSecondThrottle_callsTwice() {
        let subject = Throttler(seconds: 0, on: MockDispatchQueue())
        var throttleCalled = 0
        subject.throttle {
            throttleCalled += 1
        }

        subject.throttle {
            throttleCalled += 1
        }

        XCTAssertEqual(throttleCalled, 2, "Throttle twice is called since delay is zero")
    }

    func testThrottle_oneSecondThrottle_callsOnce() {
        let subject = Throttler(seconds: 0.2, on: DispatchQueue.global())
        var throttleCalled = 0
        subject.throttle {
            throttleCalled += 1
        }

        subject.throttle {
            throttleCalled += 1
        }
        wait(0.5)

        XCTAssertEqual(throttleCalled, 1, "Throttle is called once, one got canceled")
    }
}
