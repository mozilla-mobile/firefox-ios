// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class WebviewTelemetryTests: XCTestCase {
    var mockGlean: MockGleanWrapper!
    var subject: WebViewLoadMeasurementTelemetry!

    override func setUp() {
        super.setUp()
        mockGlean = MockGleanWrapper()
        subject = WebViewLoadMeasurementTelemetry(gleanWrapper: mockGlean)
    }

    func testLoadMeasurement() {
        subject.start()
        subject.stop()

        XCTAssertEqual(mockGlean.startTimingCalled, 1, "Start timer should be called once")
        XCTAssertEqual(mockGlean.stopAndAccumulateCalled, 1, "Stop and accumulate timer should be called once")
    }

    func testCancelLoadMeasurement() {
        subject.start()
        subject.cancel()

        XCTAssertEqual(mockGlean.startTimingCalled, 1, "Start timer should be called once")
        XCTAssertEqual(mockGlean.cancelTimingCalled, 1, "Cancel timer should be called once")
    }
}

