// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

// TODO: FXIOS-13742 - Migrate ShareTelemetryTests to use mock telemetry or GleanWrapper
@MainActor
final class ShareTelemetryTests: XCTestCase {
    private let testWebURL = URL(string: "https://mozilla.org")!
    var gleanWrapper: MockGleanWrapper!
    typealias EventExtrasType = GleanMetrics.ShareSheet.SharedToExtra

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"
    let hasIsEnrolledInSentFromFirefoxKey = "is_enrolled_in_sent_from_firefox"
    let hasIsOptedInSentFromFirefoxKey = "is_opted_in_sent_from_firefox"

    override func setUp() async throws {
        try await super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() async throws {
        gleanWrapper = nil
        try await super.tearDown()
    }

    func testSharedTo_withNoActivityType() throws {
        Self.setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let event = GleanMetrics.ShareSheet.sharedTo
        let testActivityType: UIActivity.ActivityType? = nil
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true
        let testIsEnrolledInSentFromFirefox = false
        let testIsOptedInSentFromFirefox = false

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.activityIdentifier, "unknown")
        XCTAssertEqual(savedExtras.shareType, testShareType.typeName)
        XCTAssertEqual(savedExtras.hasShareMessage, testHasShareMessage)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        // let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        // XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], "unknown")
        // XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        // XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        // XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        // XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
    }

    func testSharedTo_withActivityType() throws {
        Self.setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let event = GleanMetrics.ShareSheet.sharedTo
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true
        let testIsEnrolledInSentFromFirefox = false
        let testIsOptedInSentFromFirefox = false

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.activityIdentifier, testActivityType.rawValue)
        XCTAssertEqual(savedExtras.shareType, testShareType.typeName)
        XCTAssertEqual(savedExtras.hasShareMessage, testHasShareMessage)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")

        // let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        // XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        // XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        // XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        // XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        // XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
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
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage,
            isEnrolledInSentFromFirefox: testIsEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: testIsOptedInSentFromFirefox
        )

        try testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(resultValue[0].extra?[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(resultValue[0].extra?[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
    }

    // MARK: - Deeplink test
    func testRecordOpenDeeplinkTime_whenSendRecord_returnTimeGreaterThenZero() async throws {
        let subject = createSubject()
        subject.recordOpenDeeplinkTime()
        // simulate startup time
        try await Task.sleep(nanoseconds: 1_000)
        subject.sendOpenDeeplinkTimeRecord()

        let event = GleanMetrics.Share.deeplinkOpenUrlStartupTime
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.last as? TimingDistributionMetricType)

        XCTAssertEqual(gleanWrapper.stopAndAccumulateCalled, 1)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testRecordOpenDeeplinkTime_whenRecordCancelled_returnNilMetric() async throws {
        let subject = createSubject()

        subject.recordOpenDeeplinkTime()
        // simulate startup time
        try await Task.sleep(nanoseconds: 1_000)
        subject.cancelOpenURLTimeRecord()

        let event = GleanMetrics.Share.deeplinkOpenUrlStartupTime
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.last as? TimingDistributionMetricType)

        XCTAssertEqual(gleanWrapper.cancelTimingCalled, 1)
        XCTAssertEqual(gleanWrapper.savedEvents.count, 2)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func createSubject() -> ShareTelemetry {
        let subject = ShareTelemetry(gleanWrapper: gleanWrapper)
        trackForMemoryLeaks(subject)
        return subject
    }
}
