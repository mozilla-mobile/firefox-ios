// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class SettingsTelemetryTests: XCTestCase {
    // For telemetry extras
    let optionIdentifierKey = "option"

    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
    }

    func testOptionSelected_recordsData() throws {
        // The event and event extras type under test
        let event = GleanMetrics.Settings.optionSelected
        typealias EventExtrasType = GleanMetrics.Settings.OptionSelectedExtra

        let expectedOption = SettingsTelemetry.OptionIdentifiers.AppIconSelection
        let expectedMetricType = type(of: event)

        let subject = createSubject()
        subject.optionSelected(option: .AppIconSelection)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?.first as? EventMetricType<EventExtrasType>
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption.rawValue)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func createSubject() -> SettingsTelemetry {
        return SettingsTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
