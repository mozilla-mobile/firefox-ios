// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

final class ShareTelemetryActivityItemProviderTests: XCTestCase {
    let testMessage = "Test message"
    let testSubtitle = "Test subtitle"
    private let testFileURL = URL(string: "file://some/file/url")!
    private let testWebURL = URL(string: "https://mozilla.org")!

    func testWithShareType_noShareMessage_callTelemetryOnly() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage: ShareMessage? = nil
        let mockShareTelemetry = MockShareTelemetry()

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
    }

    func testWithShareType_hasShareMessage_callTelemetryOnly() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
