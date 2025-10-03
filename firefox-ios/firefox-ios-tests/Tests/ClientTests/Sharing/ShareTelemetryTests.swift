// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

// TODO: FXIOS-TODO Laurie - Migrate ShareTelemetryTests to use mock telemetry or GleanWrapper
final class ShareTelemetryTests: XCTestCase {
    private let testWebURL = URL(string: "https://mozilla.org")!

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"

    override func tearDown() {
        tearDownTelemetry()
        super.tearDown()
    }

    func testSharedTo_withNoActivityType() throws {
        setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let testActivityType: UIActivity.ActivityType? = nil
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], "unknown")
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
    }

    func testSharedTo_withActivityType() throws {
        setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
    }

    func testRecordOpenDeeplinkTime_whenSendRecord_returnTimeGreaterThenZero() async throws {
        let subject = createSubject()

        subject.recordOpenDeeplinkTime()
        // simulate startup time
        try await Task.sleep(nanoseconds: 1_000)
        subject.sendOpenDeeplinkTimeRecord()

        let metric = GleanMetrics.Share.deeplinkOpenUrlStartupTime
        let recordedTime = try XCTUnwrap(metric.testGetValue()?.sum)

        XCTAssertGreaterThan(recordedTime, 0)
    }

    func testRecordOpenDeeplinkTime_whenRecordCancelled_returnNilMetric() async throws {
        let subject = createSubject()

        subject.recordOpenDeeplinkTime()
        // simulate startup time
        try await Task.sleep(nanoseconds: 1_000)
        subject.cancelOpenURLTimeRecord()

        let metric = GleanMetrics.Share.deeplinkOpenUrlStartupTime

        XCTAssertNil(metric.testGetValue())
    }

    func createSubject() -> ShareTelemetry {
        return ShareTelemetry()
    }
}
