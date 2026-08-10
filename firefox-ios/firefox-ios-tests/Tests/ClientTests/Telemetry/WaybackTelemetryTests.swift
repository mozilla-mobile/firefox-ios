// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class WaybackTelemetryTests: XCTestCase {
    var subject: WaybackTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        subject = WaybackTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        subject = nil
        gleanWrapper = nil
        super.tearDown()
    }

    func testRecordEvent_WhenSearchForArchiveTapped_ThenGleanIsCalled() throws {
        let event = GleanMetrics.WebviewErrorPageWaybackMachine.checkArchiveButtonTapped

        subject?.checkArchiveButtonTapped()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenFoundArchive_ThenGleanIsCalled() throws {
        let event = GleanMetrics.WebviewErrorPageWaybackMachine.archiveFound

        subject?.foundArchive()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordEvent_WhenSearchTheWebTapped_ThenGleanIsCalled() throws {
        let event = GleanMetrics.WebviewErrorPageWaybackMachine.searchTheWebButtonTapped

        subject?.searchTheWebButtonTapped()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }
}
