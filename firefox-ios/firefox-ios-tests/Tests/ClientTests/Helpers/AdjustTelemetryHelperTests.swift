// swiftlint:disable comment_spacing file_header
//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import XCTest
//
//@testable import Client
//
//class AdjustTelemetryHelperTests: XCTestCase {
//    var telemetryWrapper: MockAdjustWrapper!
//    var gleanWrapper: MockGleanWrapper!
//
//    override func setUp() {
//        super.setUp()
//
//        telemetryWrapper = MockAdjustWrapper()
//        gleanWrapper = MockGleanWrapper()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//
//        telemetryWrapper = nil
//        gleanWrapper = nil
//    }
//
//    func testFailSetAttribution_WithAllNilData() {
//        let subject = createSubject()
//        let attribution = MockAdjustTelemetryData(campaign: nil,
//                                                  adgroup: nil,
//                                                  creative: nil,
//                                                  network: nil)
//        subject.setAttributionData(attribution)
//
//        XCTAssertEqual(telemetryWrapper.recordDeeplinkCalled, 0)
//        XCTAssertEqual(telemetryWrapper.recordCampaignCalled, 0)
//        XCTAssertEqual(telemetryWrapper.recordNetworkCalled, 0)
//        XCTAssertEqual(telemetryWrapper.recordCreativeCalled, 0)
//        XCTAssertEqual(telemetryWrapper.recordAdGroupCalled, 0)
//        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
//    }
//
//    func testSetAttribution_WithSomeNilData() {
//        let subject = createSubject()
//        let attribution = MockAdjustTelemetryData(campaign: nil)
//
//        subject.setAttributionData(attribution)
//
//        XCTAssertEqual(telemetryWrapper.recordCampaignCalled, 0)
//        XCTAssertEqual(telemetryWrapper.savedNetwork, "test_network")
//        XCTAssertEqual(telemetryWrapper.recordNetworkCalled, 1)
//        XCTAssertEqual(telemetryWrapper.savedCreative, "test_creative")
//        XCTAssertEqual(telemetryWrapper.recordCreativeCalled, 1)
//        XCTAssertEqual(telemetryWrapper.savedAdGroup, "test_adgroup")
//        XCTAssertEqual(telemetryWrapper.recordAdGroupCalled, 1)
//        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
//    }
//
//    func testDeeplinkHandleEvent_GleanCalled() {
//        let subject = createSubject()
//        let url = URL(string: "https://testurl.com")!
//        let mockData = MockAdjustTelemetryData()
//
//        subject.sendDeeplinkTelemetry(url: url, attribution: mockData)
//
//        XCTAssertEqual(telemetryWrapper.savedDeeplink, url)
//        XCTAssertEqual(telemetryWrapper.recordDeeplinkCalled, 1)
//        XCTAssertEqual(telemetryWrapper.savedCampaign, mockData.campaign!)
//        XCTAssertEqual(telemetryWrapper.savedNetwork, mockData.network!)
//        XCTAssertEqual(telemetryWrapper.savedCreative, mockData.creative!)
//        XCTAssertEqual(telemetryWrapper.savedAdGroup, mockData.adgroup!)
//        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
//    }
//
    // MARK: - Helper
//
//    func createSubject() -> AdjustTelemetryHelper {
//        let subject = AdjustTelemetryHelper(gleanWrapper: gleanWrapper,
//                                            telemetry: telemetryWrapper)
//        trackForMemoryLeaks(subject)
//        return subject
//    }
//}
// swiftlint:enable comment_spacing file_header
