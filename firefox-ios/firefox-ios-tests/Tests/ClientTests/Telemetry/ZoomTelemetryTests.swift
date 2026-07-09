// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ZoomTelemetryTests: XCTestCase {
    var subject: ZoomTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = ZoomTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenZoomIn_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ZoomBar.zoomInButtonTapped
        typealias EventExtrasType = GleanMetrics.ZoomBar.ZoomInButtonTappedExtra
        let expectedZoomLevel = ZoomLevel(from: 110)

        subject?.zoomIn(zoomLevel: expectedZoomLevel)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.level, expectedZoomLevel.telemetryQuantity)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenZoomOut_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ZoomBar.zoomOutButtonTapped
        typealias EventExtrasType = GleanMetrics.ZoomBar.ZoomOutButtonTappedExtra
        let expectedZoomLevel = ZoomLevel(from: 75)

        subject?.zoomOut(zoomLevel: expectedZoomLevel)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.level, expectedZoomLevel.telemetryQuantity)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenReset_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ZoomBar.resetButtonTapped

        subject?.resetZoomLevel()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenCloseBar_ThenGleanIsCalled() throws {
        let event = GleanMetrics.ZoomBar.closeButtonTapped

        subject?.closeZoomBar()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenDefaultZoomChanges_ThenGleanIsCalled() throws {
        let event = GleanMetrics.Preferences.changed
        typealias EventExtrasType = GleanMetrics.Preferences.ChangedExtra
        let expectedZoomLevel = ZoomLevel(from: 110)

        subject?.updateDefaultZoomLevel(zoomLevel: expectedZoomLevel)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.changedTo, expectedZoomLevel.displayName)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenSpecificZoomIsDeleted_ThenGleanIsCalled() throws {
        let event = GleanMetrics.SettingsZoomBar.domainListItemSwipedToDelete
        typealias EventExtrasType = GleanMetrics.SettingsZoomBar.DomainListItemSwipedToDeleteExtra
        let expectedIndex: Int32 = 1

        subject?.deleteZoomDomainLevel(value: expectedIndex)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.index, expectedIndex)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenSpecificZoomResets_ThenGleanIsCalled() throws {
        let event = GleanMetrics.SettingsZoomBar.domainListResetButtonTapped

        subject?.resetDomainZoomLevel()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }
}
