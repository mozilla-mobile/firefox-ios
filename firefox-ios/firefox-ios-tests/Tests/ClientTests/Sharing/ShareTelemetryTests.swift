// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareTelemetryTests: XCTestCase {
    private let testWebURL = URL(string: "https://mozilla.org")!
    var mockGleanWrapper: MockGleanWrapper!

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"
    let hasIsEnrolledInSentFromFirefoxKey = "is_enrolled_in_sent_from_firefox"
    let hasIsOptedInSentFromFirefoxKey = "is_opted_in_sent_from_firefox"

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
    }

    func testSharedTo_withNoActivityType() throws {
        let subject = createSubject()
        let testActivityType: UIActivity.ActivityType? = nil
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true
        let testIsEnrolledInSentFromFirefox = false
        let testIsOptedInSentFromFirefox = false

        subject.sharedTo(
            activityType: testActivityType,
            shareType: testShareType,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], "unknown")
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
    }

    func testSharedTo_withActivityType() throws {
        let subject = createSubject()
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true
        let testIsEnrolledInSentFromFirefox = false
        let testIsOptedInSentFromFirefox = false

        subject.sharedTo(
            activityType: testActivityType,
            shareType: testShareType,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
    }

    func testSharedTo_enrolledAndOptedInSentFromFirefox() throws {
        let subject = createSubject()
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true
        let testIsEnrolledInSentFromFirefox = true
        let testIsOptedInSentFromFirefox = true

        subject.sharedTo(
            activityType: testActivityType,
            shareType: testShareType,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
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
        return ShareTelemetry(gleanWrapper: mockGleanWrapper)
    }
}
