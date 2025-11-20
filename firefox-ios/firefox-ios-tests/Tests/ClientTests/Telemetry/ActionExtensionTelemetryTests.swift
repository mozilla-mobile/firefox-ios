// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ActionExtensionTelemetryTests: XCTestCase {
    var subject: ActionExtensionTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = ActionExtensionTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenShareURL_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.urlShared
        let expectedMetricType = type(of: event)

        subject?.shareURL()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType === expectedMetricType, debugMessage.text)
    }

    func testRecordEvent_WhenShareText_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.textShared
        let expectedMetricType = type(of: event)

        subject?.shareText()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType === expectedMetricType, debugMessage.text)
    }
}
