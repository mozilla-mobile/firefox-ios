// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareTelemetryTests: XCTestCase {
    private let testWebURL = URL(string: "https://mozilla.org")!
    var gleanWrapper: MockGleanWrapper!

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"
    let hasIsEnrolledInSentFromFirefoxKey = "is_enrolled_in_sent_from_firefox"
    let hasIsOptedInSentFromFirefoxKey = "is_opted_in_sent_from_firefox"

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
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

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.ShareSheet.SharedToExtra>
        )

        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.ShareSheet.SharedToExtra
        )

        let extraRecord = savedExtras.toExtraRecord()

        let expectedMetricType = type(of: GleanMetrics.ShareSheet.sharedTo)
        let resultMetricType = type(of: savedEvent)

        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(extraRecord[activityIdentifierKey], "unknown")
        XCTAssertEqual(extraRecord[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(extraRecord[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(extraRecord[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(extraRecord[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
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

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.ShareSheet.SharedToExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.ShareSheet.SharedToExtra
        )
        let extraRecord = savedExtras.toExtraRecord()

        let expectedMetricType = type(of: GleanMetrics.ShareSheet.sharedTo)
        let resultMetricType = type(of: savedEvent)

        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(extraRecord[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(extraRecord[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(extraRecord[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(extraRecord[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(extraRecord[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
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

        let savedEvent = try XCTUnwrap(
            gleanWrapper.savedEvent as? EventMetricType<GleanMetrics.ShareSheet.SharedToExtra>
        )
        let savedExtras = try XCTUnwrap(
            gleanWrapper.savedExtras as? GleanMetrics.ShareSheet.SharedToExtra
        )

        let extraRecord = savedExtras.toExtraRecord()

        let expectedMetricType = type(of: GleanMetrics.ShareSheet.sharedTo)
        let resultMetricType = type(of: savedEvent)

        let message = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)
        XCTAssert(resultMetricType == expectedMetricType, message.text)
        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(extraRecord[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(extraRecord[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(extraRecord[hasShareMessageKey], String(testHasShareMessage))
        XCTAssertEqual(extraRecord[hasIsEnrolledInSentFromFirefoxKey], String(testIsEnrolledInSentFromFirefox))
        XCTAssertEqual(extraRecord[hasIsOptedInSentFromFirefoxKey], String(testIsOptedInSentFromFirefox))
    }

    func createSubject() -> ShareTelemetry {
        return DefaultShareTelemetry(gleanWrapper: gleanWrapper)
    }
}
