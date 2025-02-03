// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class PrivateBrowsingTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    func testDataClearanceConfirmed() throws {
        let subject = PrivateBrowsingTelemetry(gleanWrapper: gleanWrapper)

        subject.sendDataClearanceTappedTelemetry(didConfirm: true)

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, true)
    }

    func testDataClearanceCancelled() throws {
        let subject = PrivateBrowsingTelemetry(gleanWrapper: gleanWrapper)

        subject.sendDataClearanceTappedTelemetry(didConfirm: false)

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.PrivateBrowsing.DataClearanceIconTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.didConfirm, false)
    }
}
