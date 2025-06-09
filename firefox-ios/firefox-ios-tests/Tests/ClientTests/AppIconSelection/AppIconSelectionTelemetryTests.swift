// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class AppIconSelectionTelemetryTests: XCTestCase {
    // For telemetry extras
    let nameIdentifierKey = "name"

    var mockGleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()

        mockGleanWrapper = MockGleanWrapper()
    }

    func testSelectedIcon_firesSelected() throws {
        // The event and event extras type under test
        let event = GleanMetrics.SettingsAppIcon.selected
        typealias EventExtrasType = GleanMetrics.SettingsAppIcon.SelectedExtra

        let subject = createSubject()
        let expectedNewAppIcon = AppIcon.darkPurple
        let expectedOldAppIcon = AppIcon.regular
        let expectedMetricType = type(of: event)

        subject.selectedIcon(expectedNewAppIcon, previousIcon: expectedOldAppIcon)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.newName, expectedNewAppIcon.telemetryName)
        XCTAssertEqual(savedExtras.oldName, expectedOldAppIcon.telemetryName)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func createSubject() -> AppIconSelectionTelemetry {
        return AppIconSelectionTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
