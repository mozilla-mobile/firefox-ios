// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class WebCompatReportRecorderTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func testSubmit_recordsEveryPopulatedFieldOnce() {
        createSubject().submit(makeFullPayload())

        XCTAssertEqual(gleanWrapper.recordStringCalled, 4)
        XCTAssertEqual(gleanWrapper.recordTextCalled, 3)
        XCTAssertEqual(gleanWrapper.recordStringListCalled, 3)
        XCTAssertEqual(gleanWrapper.setBooleanCalled, 7)
        XCTAssertEqual(gleanWrapper.recordQuantityCalled, 1)
        XCTAssertEqual(gleanWrapper.recordUrlCalled, 1)
        XCTAssertEqual(gleanWrapper.recordObjectCalled, 1)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 20)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
    }

    func testSubmit_recordsEachExperimentAsAnObjectItem() {
        var payload = WebCompatReportPayload()
        payload.experiments = [
            WebCompatExperiment(branch: "treatment", slug: "an-experiment", kind: .rollout)
        ]

        createSubject().submit(payload)

        let recorded = gleanWrapper.savedValues.last as? [GleanMetrics.BrokenSiteReportBrowserInfo.ExperimentsObjectItem]
        XCTAssertEqual(recorded, [
            GleanMetrics.BrokenSiteReportBrowserInfo.ExperimentsObjectItem(
                branch: "treatment",
                slug: "an-experiment",
                kind: WebCompatExperiment.Kind.rollout.rawValue
            )
        ])
    }

    // `savedEvents` is `[Any]`, so nothing type-checks which boolean went to which metric.
    func testSubmit_recordsTheAntitrackingBooleansInOrder() {
        var payload = WebCompatReportPayload()
        payload.isPrivateBrowsing = false
        payload.hasTrackingContentBlocked = true

        createSubject().submit(payload)

        XCTAssertEqual(gleanWrapper.savedBooleans, [false, true])
    }

    func testSubmit_recordsTheValuesItWasGiven() {
        var payload = WebCompatReportPayload()
        payload.breakageCategory = "media"
        payload.description = "Video does not play"
        payload.languages = ["en-CA", "fr"]
        payload.memory = 4096
        payload.isPrivateBrowsing = true

        createSubject().submit(payload)

        XCTAssertEqual(gleanWrapper.savedValues.count, 3)
        XCTAssertEqual(gleanWrapper.savedValues[0] as? String, "media")
        XCTAssertEqual(gleanWrapper.savedValues[1] as? String, "Video does not play")
        XCTAssertEqual(gleanWrapper.savedValues[2] as? [String], ["en-CA", "fr"])
        XCTAssertEqual(gleanWrapper.savedBooleans, [true])
        XCTAssertEqual(gleanWrapper.savedQuantities, [4096])
    }

    func testSubmit_withSchemelessURL_skipsTheURLButStillSubmits() {
        var payload = WebCompatReportPayload()
        payload.url = "asdf"
        payload.breakageCategory = "media"

        createSubject().submit(payload)

        XCTAssertEqual(gleanWrapper.recordUrlCalled, 0)
        XCTAssertEqual(gleanWrapper.recordStringCalled, 1)
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatReportRecorder {
        return WebCompatReportRecorder(gleanWrapper: gleanWrapper)
    }

    private func makeFullPayload() -> WebCompatReportPayload {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        payload.breakageCategory = "media"
        payload.description = "Video does not play"
        payload.languages = ["en-CA"]
        payload.userAgentString = "page UA"
        payload.blockList = "strict"
        payload.blockedOrigins = ["tracker.example"]
        payload.etpCategory = "strict"
        payload.isPrivateBrowsing = false
        payload.hasTrackingContentBlocked = true
        payload.fastclick = true
        payload.marfeel = false
        payload.mobify = false
        payload.experiments = [
            WebCompatExperiment(branch: "treatment", slug: "an-experiment", kind: .experiment)
        ]
        payload.defaultLocales = ["en-CA"]
        payload.defaultUserAgentString = "app UA"
        payload.devicePixelRatio = "3"
        payload.hasTouchScreen = true
        payload.isTablet = false
        payload.memory = 4096
        return payload
    }
}
