// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Glean
import MozillaAppServices
import XCTest

final class RemoteSettingsGleanTelemetryTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func testReportUptakeForwardsAllExtraFieldsToGlean() {
        let subject = RemoteSettingsGleanTelemetry(gleanWrapper: gleanWrapper)

        subject.reportUptake(extras: UptakeEventExtras(
            value: "success",
            source: "main/search-config-v2",
            age: "12",
            trigger: "startup",
            timestamp: "1717438800",
            duration: "150",
            errorName: nil
        ))

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 1)
        guard let extras = gleanWrapper.savedExtras.first
                as? GleanMetrics.RemoteSettings.UptakeRemotesettingsExtra else {
            XCTFail("Expected UptakeRemotesettingsExtra, got \(String(describing: gleanWrapper.savedExtras.first))")
            return
        }
        XCTAssertEqual(extras.value, "success")
        XCTAssertEqual(extras.source, "main/search-config-v2")
        XCTAssertEqual(extras.age, "12")
        XCTAssertEqual(extras.trigger, "startup")
        XCTAssertEqual(extras.timestamp, "1717438800")
        XCTAssertEqual(extras.duration, "150")
        XCTAssertNil(extras.errorname)
    }

    func testReportUptakeForwardsErrorFields() {
        let subject = RemoteSettingsGleanTelemetry(gleanWrapper: gleanWrapper)

        subject.reportUptake(extras: UptakeEventExtras(
            value: "sync_error",
            source: "main/search-config-v2",
            age: nil,
            trigger: "timer",
            timestamp: nil,
            duration: nil,
            errorName: "NetworkError"
        ))

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        guard let extras = gleanWrapper.savedExtras.first
                as? GleanMetrics.RemoteSettings.UptakeRemotesettingsExtra else {
            XCTFail("Expected UptakeRemotesettingsExtra")
            return
        }
        XCTAssertEqual(extras.trigger, "timer")
        XCTAssertEqual(extras.source, "main/search-config-v2")
        XCTAssertEqual(extras.value, "sync_error")
        XCTAssertEqual(extras.errorname, "NetworkError")
        XCTAssertNil(extras.age)
        XCTAssertNil(extras.timestamp)
        XCTAssertNil(extras.duration)
    }
}
