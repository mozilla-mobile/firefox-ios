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

    func testTappedAppIconSetting_firesOptionSelected() throws {
        // The event and event extras type under test
        let event = GleanMetrics.SettingsMainMenu.optionSelected
        typealias EventExtrasType = GleanMetrics.SettingsMainMenu.OptionSelectedExtra

        let subject = createSubject()
        let expectedOption = SettingsTelemetry.MainMenuOption.AppIcon
        let expectedMetricType = type(of: event)

        subject.tappedAppIconSetting()

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
