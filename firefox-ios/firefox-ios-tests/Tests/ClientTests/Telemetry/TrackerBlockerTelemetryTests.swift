// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class TrackerBlockerTelemetryTests: XCTestCase {
    var subject: TrackerBlockerTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = TrackerBlockerTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenLifetimeThresholdReached_ThenGleanIsCalled() throws {
        let event = GleanMetrics.TrackerBlocker.lifetimeThresholdReached
        typealias EventExtrasType = GleanMetrics.TrackerBlocker.LifetimeThresholdReachedExtra
        let expectedFigures: Int32 = 5

        subject?.lifetimeThresholdReached(figures: 5)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.figures, expectedFigures)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }
}
