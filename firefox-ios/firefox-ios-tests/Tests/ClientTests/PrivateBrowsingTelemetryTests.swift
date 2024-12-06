// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class PrivateBrowsingTelemetryTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    func testDataClearanceConfirmed() throws {
        let subject = PrivateBrowsingTelemetry()

        subject.sendDataClearanceTappedTelemetry(didConfirm: true)

        testEventMetricRecordingSuccess(metric: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.PrivateBrowsing.dataClearanceIconTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["did_confirm"], "true")
    }

    func testDataClearanceCancelled() throws {
        let subject = PrivateBrowsingTelemetry()

        subject.sendDataClearanceTappedTelemetry(didConfirm: false)

        testEventMetricRecordingSuccess(metric: GleanMetrics.PrivateBrowsing.dataClearanceIconTapped)

        let resultValue = try XCTUnwrap(GleanMetrics.PrivateBrowsing.dataClearanceIconTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["did_confirm"], "false")
    }
}
