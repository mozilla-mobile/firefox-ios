// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class WebviewTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func testLoadMeasurement() throws {
        let subject = createSubject()
        let metric = GleanMetrics.Webview.pageLoad

        subject.start()
        subject.stop()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? TimingDistributionMetricType
        )
        XCTAssertEqual(mockGleanWrapper.startTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.stopAndAccumulateCalled, 1)
        XCTAssertEqual(mockGleanWrapper.cancelTimingCalled, 0)
        XCTAssert(savedMetric === metric, "Received \(savedMetric) instead of \(metric)")
    }

    func testCancelLoadMeasurement() throws {
        let subject = createSubject()
        let metric = GleanMetrics.Webview.pageLoad

        subject.start()
        subject.cancel()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? TimingDistributionMetricType
        )
        XCTAssertEqual(mockGleanWrapper.startTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.cancelTimingCalled, 1)
        XCTAssertEqual(mockGleanWrapper.stopAndAccumulateCalled, 0)
        XCTAssert(savedMetric === metric, "Received \(savedMetric) instead of \(metric)")
    }

    private func createSubject() -> WebViewLoadMeasurementTelemetry {
        return WebViewLoadMeasurementTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
