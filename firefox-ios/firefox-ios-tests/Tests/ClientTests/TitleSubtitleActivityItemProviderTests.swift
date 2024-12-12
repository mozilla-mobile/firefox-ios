// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

final class TitleSubtitleActivityItemProviderTests: XCTestCase {
    let testMessage = "Test message"
    let testSubtitle = "Test subtitle"
    let testFileURL = URL(string: "file://some/file/url")!
    let testWebURL = URL(string: "https://mozilla.org")!

    func testShareMessage_forMailActivity_noSubtitle() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareMessage = ShareMessage(message: testMessage, subtitle: nil)

        let titleSubtitleActivityItemProvider = TitleSubtitleActivityItemProvider(shareMessage: testShareMessage)
        let dataIdentifier = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let subtitle = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertEqual(dataIdentifier, UTType.text.identifier)
        XCTAssertEqual(titleSubtitleActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(subtitle, testMessage, "If no subtitle set, should repeat title")
    }

    func testShareMessage_forMailActivity_withSubtitle() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)

        let titleSubtitleActivityItemProvider = TitleSubtitleActivityItemProvider(shareMessage: testShareMessage)
        let dataIdentifier = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let subtitle = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertEqual(dataIdentifier, UTType.text.identifier)
        XCTAssertEqual(titleSubtitleActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(subtitle, testSubtitle)
    }

    func testShareMessage_forMessagesActivity_noSubtitle() throws {
        let testActivityType = UIActivity.ActivityType.message
        let testShareMessage = ShareMessage(message: testMessage, subtitle: nil)

        let titleSubtitleActivityItemProvider = TitleSubtitleActivityItemProvider(shareMessage: testShareMessage)
        let dataIdentifier = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let subtitle = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertEqual(dataIdentifier, UTType.text.identifier)
        XCTAssertEqual(titleSubtitleActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(subtitle, testMessage, "If no subtitle set, should repeat title")
    }

    func testShareMessage_forMessagesActivity_withSubtitle() throws {
        let testActivityType = UIActivity.ActivityType.message
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)

        let titleSubtitleActivityItemProvider = TitleSubtitleActivityItemProvider(shareMessage: testShareMessage)
        let dataIdentifier = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let subtitle = titleSubtitleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertEqual(dataIdentifier, UTType.text.identifier)
        XCTAssertEqual(titleSubtitleActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(subtitle, testSubtitle)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
