// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

final class URLActivityItemProviderTests: XCTestCase {
    let testFileURL = URL(string: "file://some/file/url")!
    let testWebURL = URL(string: "https://mozilla.org")!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    func testWebURL_forMailActivity() {
        let testActivityType = UIActivity.ActivityType.mail

        let urlActivityItemProvider = URLActivityItemProvider(url: testWebURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForActivity as? URL, testWebURL)
    }

    func testWebURL_forMessagesActivity() {
        let testActivityType = UIActivity.ActivityType.message

        let urlActivityItemProvider = URLActivityItemProvider(url: testWebURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForActivity as? URL, testWebURL)
    }

    func testFileURL_forMailActivity() {
        let testActivityType = UIActivity.ActivityType.mail

        let urlActivityItemProvider = URLActivityItemProvider(url: testFileURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.fileURL.identifier)
        XCTAssertEqual(itemForActivity as? URL, testFileURL)
    }

    func testFileURL_forMessagesActivity() {
        let testActivityType = UIActivity.ActivityType.message

        let urlActivityItemProvider = URLActivityItemProvider(url: testFileURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.fileURL.identifier)
        XCTAssertEqual(itemForActivity as? URL, testFileURL)
    }

    func testWebURL_forExcludedActivity() {
        let testActivityType = UIActivity.ActivityType.addToReadingList

        let urlActivityItemProvider = URLActivityItemProvider(url: testWebURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertTrue(itemForActivity is NSNull)
    }

    func testFileURL_forExcludedActivity() {
        let testActivityType = UIActivity.ActivityType.addToReadingList

        let urlActivityItemProvider = URLActivityItemProvider(url: testFileURL)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.fileURL.identifier)
        XCTAssertTrue(itemForActivity is NSNull)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
