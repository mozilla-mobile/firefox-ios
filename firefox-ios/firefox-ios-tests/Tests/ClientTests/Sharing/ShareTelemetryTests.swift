// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class ShareTelemetryTests: XCTestCase {
    private let testFileURL = URL(string: "file://some/file/url")!
    private let testWebURL = URL(string: "https://mozilla.org")!

    // For telemetry extras
    let activityIdentifierKey = "activity_identifier"
    let shareTypeKey = "share_type"
    let hasShareMessageKey = "has_share_message"

    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
    }

    func testSharedTo_withNoActivityType() throws {
        let subject = createSubject()
        let testActivityType: UIActivity.ActivityType? = nil
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(activityType: testActivityType, shareType: testShareType, hasShareMessage: testHasShareMessage)
        testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], "unknown")
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
    }

    func testSharedTo_withActivityType() throws {
        let subject = createSubject()
        let testActivityType = UIActivity.ActivityType("com.some.activity.identifier")
        let testShareType: ShareType = .site(url: testWebURL)
        let testHasShareMessage = true

        subject.sharedTo(activityType: testActivityType, shareType: testShareType, hasShareMessage: testHasShareMessage)
        testEventMetricRecordingSuccess(metric: GleanMetrics.ShareSheet.sharedTo)

        let resultValue = try XCTUnwrap(GleanMetrics.ShareSheet.sharedTo.testGetValue())
        XCTAssertEqual(resultValue[0].extra?[activityIdentifierKey], testActivityType.rawValue)
        XCTAssertEqual(resultValue[0].extra?[shareTypeKey], testShareType.typeName)
        XCTAssertEqual(resultValue[0].extra?[hasShareMessageKey], String(testHasShareMessage))
    }

    func createSubject() -> ShareTelemetry {
        return DefaultShareTelemetry()
    }
}
