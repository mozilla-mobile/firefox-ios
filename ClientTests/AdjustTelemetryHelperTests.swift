// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class AdjustTelemetryHelperTests: XCTestCase {

    var telemetryHelper: AdjustTelemetryHelper!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()

        // Setup mock profile
        profile = MockProfile(databasePrefix: "adjust-helper-test")
        telemetryHelper = AdjustTelemetryHelper()
    }

    override func tearDown() {
        super.tearDown()

        self.profile._shutdown()
        self.profile = nil
    }

    func testShouldSetAttribution() {
        telemetryHelper.hasSetAttributionData = false
        telemetryHelper.setAttribution(MockAdjustTelemetryData())
        XCTAssertTrue(telemetryHelper.hasSetAttributionData)
    }

    func testFailSetAttribution_WithNilData() {
        telemetryHelper.hasSetAttributionData = false
        let attribution = MockAdjustTelemetryData(campaign: nil)
        telemetryHelper.setAttribution(attribution)
        XCTAssertFalse(telemetryHelper.hasSetAttributionData)
    }

    func testHandleDeeplink() {
        if let url = URL(string: "https://testurl.com") {
            telemetryHelper.sendDeeplinkTelemetry(url: url)
            testEventMetricRecordingSuccess(metric: GleanMetrics.Adjust.deeplinkReceived)
        }
    }
}
