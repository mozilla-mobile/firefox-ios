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
        let savedAttribution = telemetryHelper.setAttributionData(MockAdjustTelemetryData())
        XCTAssertTrue(savedAttribution)
    }

    func testFailSetAttribution_WithNilData() {
        let attribution = MockAdjustTelemetryData(campaign: nil)
        let savedAttribution = telemetryHelper.setAttributionData(attribution)
        XCTAssertFalse(savedAttribution)
    }

    func testFirstSessionPing() {
        let expectation = expectation(description: "The first session ping was sent")

        GleanMetrics.Pings.shared.firstSession.testBeforeNextSubmit { _ in
            XCTAssert(GleanMetrics.Adjust.campaign.testHasValue())
            XCTAssert(GleanMetrics.Adjust.adGroup.testHasValue())
            XCTAssert(GleanMetrics.Adjust.creative.testHasValue())
            XCTAssert(GleanMetrics.Adjust.network.testHasValue())
            expectation.fulfill()
        }

        // Submit the ping.
        let attributionSet = telemetryHelper.setAttributionData(MockAdjustTelemetryData())
        XCTAssertTrue(attributionSet)
        waitForExpectations(timeout: 5.0)
    }

    func testDeeplinkHandleEvent_GleanCalled() {
        guard let url = URL(string: "https://testurl.com") else {
            XCTFail("Url should be build correctly")
            return
        }

        let mockData = MockAdjustTelemetryData()
        let campaign = mockData.campaign ?? ""
        let adGroup = mockData.adgroup ?? ""
        let creative = mockData.creative ?? ""
        let network = mockData.network ?? ""

        let expectation = expectation(description: "The first session ping was sent")
        GleanMetrics.Pings.shared.firstSession.testBeforeNextSubmit { _ in

            self.testEventMetricRecordingSuccess(metric: GleanMetrics.Adjust.deeplinkReceived)

            self.testStringMetricSuccess(metric: GleanMetrics.Adjust.campaign,
                                         expectedValue: campaign,
                                         failureMessage: "Should have adjust campaign of \(campaign)")

            self.testStringMetricSuccess(metric: GleanMetrics.Adjust.adGroup,
                                         expectedValue: adGroup,
                                         failureMessage: "Should have adjust adGroup of \(adGroup)")

            self.testStringMetricSuccess(metric: GleanMetrics.Adjust.creative,
                                         expectedValue: creative,
                                         failureMessage: "Should have adjust creative of \(creative)")

            self.testStringMetricSuccess(metric: GleanMetrics.Adjust.network,
                                         expectedValue: network,
                                         failureMessage: "Should have adjust network of \(network)")

            expectation.fulfill()
        }

        telemetryHelper.sendDeeplinkTelemetry(url: url, attribution: mockData)
        waitForExpectations(timeout: 5.0)
    }
}
