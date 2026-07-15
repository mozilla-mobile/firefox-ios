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

        let subject = createSubject()
        subject.optionSelected(option: .AppIconSelection)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSettingChanged_recordsData() throws {
        // The event and event extras type under test
        let event = GleanMetrics.Settings.changed
        typealias EventExtrasType = GleanMetrics.Settings.ChangedExtra

        let expectedOption = "someUniqueSettingIdentifier"
        let expectedNewValue = "Input"
        let expectedOldValue = "Output"

        let subject = createSubject()
        subject.changedSetting(expectedOption, to: expectedNewValue, from: expectedOldValue)

        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras[safe: 0] as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>
        )

        // When `preferences.changed` is fully deprecated, this will record only 1 event.
        // For now, this old event shadows the new `settings.changed`.
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(savedExtras.setting, expectedOption)
        XCTAssertEqual(savedExtras.changedTo, expectedNewValue)
        XCTAssertEqual(savedExtras.changedFrom, expectedOldValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // This test can be deleted once `preferences.changed` is expired and fully deprecated.
    func testSettingChanged_recordsLegacyPreferencesChangedData() throws {
        // The event and event extras type under test
        let event = GleanMetrics.Preferences.changed
        typealias EventExtrasType = GleanMetrics.Preferences.ChangedExtra

        let expectedOption = "someUniqueSettingIdentifier"
        let expectedNewValue = "Input"
        let expectedOldValue = "Output"

        let subject = createSubject()
        subject.changedSetting(expectedOption, to: expectedNewValue, from: expectedOldValue)

        // `preferences.changed` is recorded after `settings.changed`
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras[safe: 1] as? EventExtrasType
        )
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents[safe: 1] as? EventMetricType<EventExtrasType>
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(savedExtras.preference, expectedOption)
        XCTAssertEqual(savedExtras.changedTo, expectedNewValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func createSubject() -> SettingsTelemetry {
        return SettingsTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
