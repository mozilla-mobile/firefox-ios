// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import XCTest

class WebviewTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
    }

    func testLoadMeasurement() throws {
        let subject = WebViewLoadMeasurementTelemetry()

        subject.start()
        subject.stop()

        let resultValue = try XCTUnwrap(GleanMetrics.Webview.pageLoad.testGetValue())
        XCTAssertEqual(1, resultValue.count, "Should have been measured once")
        XCTAssertEqual(0, GleanMetrics.Webview.pageLoad.testGetNumRecordedErrors(.invalidValue))
    }

    func testCancelLoadMeasurement() {
        let subject = WebViewLoadMeasurementTelemetry()

        subject.start()
        subject.cancel()

        XCTAssertNil(GleanMetrics.Webview.pageLoad.testGetValue(), "Should not have been measured")
        XCTAssertEqual(0, GleanMetrics.Webview.pageLoad.testGetNumRecordedErrors(.invalidValue))
    }
}
