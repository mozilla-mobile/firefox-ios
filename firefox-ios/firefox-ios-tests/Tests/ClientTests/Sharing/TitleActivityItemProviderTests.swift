// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

final class TitleActivityItemProviderTests: XCTestCase {
    let testMessage = "Test message"

    func testNoShare_forMailActivity() throws {
        let testActivityType = UIActivity.ActivityType.mail

        let titleActivityItemProvider = TitleActivityItemProvider(title: testMessage)
        let itemForActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        let subtitle = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "No title should be set for Mail")
        XCTAssertEqual(subtitle, testMessage)
    }

    func testNoShare_forMessagesActivity() throws {
        let testActivityType = UIActivity.ActivityType.message

        let titleActivityItemProvider = TitleActivityItemProvider(title: testMessage)
        let itemForActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        let subtitle = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "No title should be set for Messages")
        XCTAssertEqual(subtitle, testMessage)
    }

    func testNoShare_forCopyToPasteboardActivity() throws {
        let testActivityType = UIActivity.ActivityType.copyToPasteboard

        let titleActivityItemProvider = TitleActivityItemProvider(title: testMessage)
        let itemForActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        let subtitle = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "No title should be set for Copy & Pasteboard")
        XCTAssertEqual(subtitle, testMessage)
    }

    func testShares_forNonExcludedActivity() throws {
        let testActivityType = UIActivity.ActivityType(rawValue: "com.random.non-excluded.activity")

        let titleActivityItemProvider = TitleActivityItemProvider(title: testMessage)
        let itemForActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        let subtitle = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testActivityType
        )

        XCTAssertEqual(itemForActivity as? String, testMessage, "Must set title for non-excluded activity")
        XCTAssertEqual(subtitle, testMessage)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
