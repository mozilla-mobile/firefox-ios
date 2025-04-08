// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import XCTest

@testable import Client

final class ToastTelemetryTests: XCTestCase {
    var mockGleanWrapper: MockGleanWrapper!
    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
    }

    func testClosedSingleTabToastUndoSelected_callsGlean() throws {
        let event = GleanMetrics.ToastsCloseSingleTab.undoTapped
        let expectedMetricType = type(of: event)
        let subject = createSubject()

        subject.undoClosedSingleTab()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?.first as? EventMetricType<NoExtras>
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func testClosedAllTabsToastUndoSelected_callsGlean() throws {
        let event = GleanMetrics.ToastsCloseAllTabs.undoTapped
        let expectedMetricType = type(of: event)
        let subject = createSubject()

        subject.undoClosedAllTabs()

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?.first as? EventMetricType<NoExtras>
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func createSubject() -> ToastTelemetry {
        return ToastTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
