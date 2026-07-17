// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class GoogleLensTelemetryTests: XCTestCase {
    var subject: GoogleLensTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = GoogleLensTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_SearchCompleted() throws {
        let event = GleanMetrics.GoogleLens.searchCompleted
        typealias EventExtrasType = GleanMetrics.GoogleLens.SearchCompletedExtra

        subject?.searchCompleted(source: .camera, succeeded: true, httpStatusCode: 200)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.source, GoogleLensTelemetry.Source.camera.rawValue)
        XCTAssertEqual(savedExtras.succeeded, true)
        XCTAssertEqual(savedExtras.httpStatus, 200)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSetBoolean_GoogleLensEnabled() throws {
        let metric = GleanMetrics.UserSearch.googleLensEnabled

        subject?.googleLensEnabled(true)

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? BooleanMetricType)

        XCTAssertEqual(gleanWrapper.setBooleanCalled, 1)
        XCTAssert(savedMetric === metric, "Received \(savedMetric) instead of \(metric)")
    }

    func testRecordEvent_SearchCompleted_withoutStatusCode() throws {
        typealias EventExtrasType = GleanMetrics.GoogleLens.SearchCompletedExtra

        subject?.searchCompleted(source: .contextMenu, succeeded: false, httpStatusCode: nil)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)

        XCTAssertEqual(savedExtras.source, GoogleLensTelemetry.Source.contextMenu.rawValue)
        XCTAssertEqual(savedExtras.succeeded, false)
        XCTAssertNil(savedExtras.httpStatus)
    }

    func testToolbarButtonSearchTime_whenStartedThenStopped_accumulatesTiming() throws {
        let metric = GleanMetrics.GoogleLens.toolbarButtonSearchTime

        let timerId = try XCTUnwrap(subject?.startToolbarButtonSearch())
        subject?.stopToolbarButtonSearch(timerId: timerId)

        let savedMetrics = gleanWrapper.savedEvents.compactMap { $0 as? TimingDistributionMetricType }
        XCTAssertEqual(gleanWrapper.startTimingCalled, 1)
        XCTAssertEqual(gleanWrapper.stopAndAccumulateCalled, 1)
        XCTAssertEqual(savedMetrics.count, 2)
        XCTAssertTrue(savedMetrics.allSatisfy { $0 === metric })
    }
}
