// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
@testable import Client

final class ShareManagerTests: XCTestCase {
    let testMessage = "Test message"
    let testSubtitle = "Test subtitle"
    let testFileURL = URL(string: "file://some/file/url")!
    let testWebURL = URL(string: "https://mozilla.org")!
    let testWebpageDisplayTitle = "Mozilla"
    var testTab: (any ShareTab)!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        testTab = MockShareTab(title: testWebpageDisplayTitle, url: testWebURL, canonicalURL: testWebURL)
    }

    override func tearDown() {
        testTab = nil
        super.tearDown()
    }

    // MARK: - Test sharing a file

    func testGetActivityItems_forFileURL_withNoShareText() throws {
        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testFileURL),
            withExplicitShareMessage: nil
        )

        XCTAssertEqual(activityItems.count, 1)

        let urlActivityItemProvider = try XCTUnwrap(activityItems.first as? URLActivityItemProvider)
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType.message
        )

        XCTAssertEqual(itemForActivity as? URL, testFileURL)
    }

    func testGetActivityItems_forFileURL_withShareText() throws {
        let testMessage = "Test message"
        let testSubtitle = "Test subtitle"
        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testFileURL),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        // Test that we get back a URL provider and a title and subject provider with the correct content:
        XCTAssertEqual(activityItems.count, 2)

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: .mail
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType.message
        )
        let titleSubjectActivityItemProvider = try XCTUnwrap(
            activityItems[safe: 1] as? TitleSubtitleActivityItemProvider
        )
        let titleSubjectSubject = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: .mail
        )
        let titleSubjectDataIdentifier = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: .mail
        )

        XCTAssertEqual(urlDataIdentifier, UTType.fileURL.identifier)
        XCTAssertEqual(itemForActivity as? URL, testFileURL)
        XCTAssertEqual(titleSubjectActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(titleSubjectSubject, testSubtitle)
        XCTAssertEqual(titleSubjectDataIdentifier, UTType.text.identifier)
    }

    // MARK: - Test sharing a website

    func testGetActivityItems_forWebsiteURL_withNoShareText() throws {
        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testWebURL),
            withExplicitShareMessage: nil
        )

        XCTAssertEqual(activityItems.count, 1)

        let urlActivityItemProvider = try XCTUnwrap(activityItems.first as? URLActivityItemProvider)
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType.message
        )

        XCTAssertEqual(itemForActivity as? URL, testWebURL)
    }

    func testGetActivityItems_forWebsiteURL_withShareText() throws {
        let testMessage = "Test message"
        let testSubtitle = "Test subtitle"
        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testWebURL),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        // Test that we get back a URL provider and a title and subject provider with the correct content:
        XCTAssertEqual(activityItems.count, 2)

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: .mail
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType.message
        )
        let titleSubjectActivityItemProvider = try XCTUnwrap(
            activityItems[safe: 1] as? TitleSubtitleActivityItemProvider
        )
        let titleSubjectSubject = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: .mail
        )
        let titleSubjectDataIdentifier = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: .mail
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForActivity as? URL, testWebURL)
        XCTAssertEqual(titleSubjectActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(titleSubjectSubject, testSubtitle)
        XCTAssertEqual(titleSubjectDataIdentifier, UTType.text.identifier)
    }

    // MARK: - Test sharing a website with a related Tab and webview

    func testGetActivityItems_forTab_withNoShareText_sharedToMail() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: nil
        )

        // Check we get all 4 types of share items for tabs below
        XCTAssertEqual(activityItems.count, 4)

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForUrlActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForUrlActivity as? URL, testWebURL)

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? TabWebView)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleActivityItemProvider)
        let itemForTitleActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        XCTAssertTrue(
            itemForTitleActivity is NSNull,
            "We don't share a message for Mail, Messages, and Pasteboard when ShareMessage is not explicitly set"
        )
    }

    func testGetActivityItems_forTab_withNoShareText_sharedToNonExcludedActivity() throws {
        let testActivityType = UIActivity.ActivityType(rawValue: "com.random.non-excluded.activity")
        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: nil
        )

        // Check we get all 4 types of share items for tabs below
        XCTAssertEqual(activityItems.count, 4)

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testActivityType
        )
        let itemForUrlActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForUrlActivity as? URL, testWebURL)

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? TabWebView)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleActivityItemProvider)
        let itemForTitleActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )
        XCTAssertEqual(
            itemForTitleActivity as? String,
            testWebpageDisplayTitle,
            "When no explicit ShareMessage is set, we expect to see the webpage's title for non-excluded activities."
        )
    }

    func testGetActivityItems_forTab_withShareText() throws {
        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        // Check we get all 4 types of share items for tabs below
        XCTAssertEqual(activityItems.count, 4)

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: .mail
        )
        let itemForActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: UIActivity.ActivityType.message
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForActivity as? URL, testWebURL)

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? TabWebView)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleSubtitleActivityItemProvider)
        XCTAssertEqual(
            titleActivityItemProvider.item as? String,
            testMessage,
            "When an explicit share message is set, we expect to see that message, not the webpage's title."
        )
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
