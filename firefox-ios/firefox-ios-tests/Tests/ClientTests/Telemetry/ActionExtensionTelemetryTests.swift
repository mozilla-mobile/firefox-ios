// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ActionExtensionTelemetryTests: XCTestCase {
    var actionExtensionTelemetry: ActionExtensionTelemetry?
    var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
        actionExtensionTelemetry = ActionExtensionTelemetry(gleanWrapper: gleanWrapper)
    }

    override func tearDown() {
        actionExtensionTelemetry = nil
        gleanWrapper = nil
        super.tearDown()
    }

    // MARK: - shareURL Tests

    func testShareURL_RecordsUrlSharedEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.urlShared

        actionExtensionTelemetry?.shareURL()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - shareText Tests

    func testShareText_RecordsTextSharedEvent() throws {
        let event = GleanMetrics.ShareOpenInFirefoxExtension.textShared

        actionExtensionTelemetry?.shareText()

        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    // MARK: - Multiple Events Tests

    func testMultipleEvents_RecordsAllEvents() {
        actionExtensionTelemetry?.shareURL()
        actionExtensionTelemetry?.shareText()

        XCTAssertEqual(gleanWrapper.recordEventNoExtraCalled, 2)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
    }
}
