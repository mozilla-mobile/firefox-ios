// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class HomepageTelemetryTests: XCTestCase {
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    func testPrivateModeShortcutToggleTappedInNormalMode() throws {
        let subject = HomepageTelemetry(gleanWrapper: gleanWrapper)

        subject.sendMaskToggleTappedTelemetry(enteringPrivateMode: true)

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.Homepage.PrivateModeToggleExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Homepage.PrivateModeToggleExtra
        )

        let expectedMetricType = type(of: GleanMetrics.Homepage.privateModeToggle)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.isPrivateMode, true)
    }

    func testPrivateModeShortcutToggleTappedInPrivateMode() throws {
        let subject = HomepageTelemetry(gleanWrapper: gleanWrapper)

        subject.sendMaskToggleTappedTelemetry(enteringPrivateMode: false)

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.Homepage.PrivateModeToggleExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.Homepage.PrivateModeToggleExtra
        )

        let expectedMetricType = type(of: GleanMetrics.Homepage.privateModeToggle)
        let resultMetricType = type(of: savedEvent)
        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.isPrivateMode, false)
    }
}
