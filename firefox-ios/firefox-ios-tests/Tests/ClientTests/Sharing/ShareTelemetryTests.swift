// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

// TODO: FXIOS-TODO Laurie - Migrate ShareTelemetryTests to use mock telemetry or GleanWrapper
final class ShareTelemetryTests: XCTestCase {
    private let testWebURL = URL(string: "https://mozilla.org")!
    var gleanWrapper: MockGleanWrapper!
    typealias EventExtrasType = GleanMetrics.ShareSheet.SharedToExtra

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func testSharedTo_withNoActivityType() throws {
        setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let event = GleanMetrics.ShareSheet.sharedTo
        let testActivityType: UIActivity.ActivityType? = nil
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage
        )

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.activityIdentifier, "unknown")
        XCTAssertEqual(savedExtras.shareType, testShareType.typeName)
        XCTAssertEqual(savedExtras.hasShareMessage, testHasShareMessage)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func testSharedTo_withActivityType() throws {
        setupTelemetry(with: MockProfile())
        let subject = createSubject()
        let event = GleanMetrics.ShareSheet.sharedTo
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(
            activityType: testActivityType,
            shareTypeName: testShareType.typeName,
            hasShareMessage: testHasShareMessage
        )

        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(savedExtras.activityIdentifier, testActivityType.rawValue)
        XCTAssertEqual(savedExtras.shareType, testShareType.typeName)
        XCTAssertEqual(savedExtras.hasShareMessage, testHasShareMessage)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
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
