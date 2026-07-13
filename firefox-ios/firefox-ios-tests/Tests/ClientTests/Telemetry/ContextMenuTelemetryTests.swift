// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ContextMenuTelemetryTests: XCTestCase {
    let x = BookmarksTelemetry()
    var subject: ContextMenuTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = ContextMenuTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_OptionSelected() throws {
        let event = GleanMetrics.ContextMenu.optionSelected
        typealias EventExtrasType = GleanMetrics.ContextMenu.OptionSelectedExtra

        let expectedOption = ContextMenuTelemetry.OptionExtra.openInNewTab
        let expectedOrigin = ContextMenuTelemetry.OriginExtra.webLink

        subject?.optionSelected(option: expectedOption, origin: expectedOrigin)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.option, expectedOption.rawValue)
        XCTAssertEqual(savedExtras.origin, expectedOrigin.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_Shown() throws {
        let event = GleanMetrics.ContextMenu.shown
        typealias EventExtrasType = GleanMetrics.ContextMenu.ShownExtra

        let expectedOrigin = ContextMenuTelemetry.OriginExtra.webLink

        subject?.shown(origin: expectedOrigin)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.origin, expectedOrigin.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_Dismissed() throws {
        let event = GleanMetrics.ContextMenu.dismissed
        typealias EventExtrasType = GleanMetrics.ContextMenu.DismissedExtra

        let expectedOrigin = ContextMenuTelemetry.OriginExtra.webLink

        subject?.dismissed(origin: expectedOrigin)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.origin, expectedOrigin.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }
}
