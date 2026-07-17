// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class SystemPhotoPickerTelemetryTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func testShown_recordsEventAndReason() throws {
        typealias EventExtrasType = GleanMetrics.SystemPhotoPicker.ShownExtra
        let event = GleanMetrics.SystemPhotoPicker.shown
        let subject = SystemPhotoPickerTelemetry(gleanWrapper: gleanWrapper)

        subject.shown(reason: .googleLens)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.reason, PhotoPickerReason.googleLens.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testClosed_recordsEventAndExtras() throws {
        typealias EventExtrasType = GleanMetrics.SystemPhotoPicker.ClosedExtra
        let event = GleanMetrics.SystemPhotoPicker.closed
        let subject = SystemPhotoPickerTelemetry(gleanWrapper: gleanWrapper)

        subject.closed(reason: .googleLens, photoSelected: true)

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.photoSelected, true)
        XCTAssertEqual(savedExtras.reason, PhotoPickerReason.googleLens.rawValue)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }
}
