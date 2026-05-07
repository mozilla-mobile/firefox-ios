// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class WorldCupTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        super.tearDown()
    }

    func test_closeButtonTapped_recordsEvent() throws {
        let subject = createSubject()

        subject.closeButtonTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupCountdownWidget.closeButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_viewScheduleTapped_recordsEvent() throws {
        let subject = createSubject()

        subject.viewScheduleTapped()

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.WorldCupCountdownWidget.viewSchedule)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_multipleEvents_recordedIndependently() {
        let subject = createSubject()

        subject.closeButtonTapped()
        subject.viewScheduleTapped()

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 2)
        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
    }

    // MARK: - Helpers

    private func createSubject() -> WorldCupTelemetry {
        return WorldCupTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
