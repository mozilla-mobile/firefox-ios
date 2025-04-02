// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class HistoryDeletionUtilityTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
    }

    func testHistoryDeletedTelemetry() throws {
        // The event and event extras type under test
        let event = GleanMetrics.LibraryHistoryPanel.clearedHistory
        typealias EventExtrasType = GleanMetrics.LibraryHistoryPanel.ClearedHistoryExtra

        let subject = createSubject()
        let expectedDateOption = HistoryDeletionUtilityDateOptions.lastHour
        let expectedMetricType = type(of: event)

        subject.clearedHistory(expectedDateOption)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?.first as? EventMetricType<EventExtrasType>
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.timeframe, expectedDateOption.rawValue)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func createSubject() -> HistoryDeletionUtilityTelemetry {
        return HistoryDeletionUtilityTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
