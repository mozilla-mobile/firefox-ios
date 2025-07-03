// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UniformTypeIdentifiers
import XCTest
import Shared

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
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
        super.tearDown()
    }

    // MARK: - Test sharing a file

    func testGetActivityItems_forFileURL_withNoShareText() throws {
        let testShareActivityType = UIActivity.ActivityType.message

        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testFileURL),
            withExplicitShareMessage: nil
        )

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let itemForURLActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 1] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 2)
        XCTAssertEqual(itemForURLActivity as? URL, testFileURL)
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    func testGetActivityItems_forFileURL_withShareText() throws {
        let testShareActivityType = UIActivity.ActivityType.mail
        let testMessage = "Test message"
        let testSubtitle = "Test subtitle"
        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testFileURL),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
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
            subjectForActivityType: testShareActivityType
        )
        let titleSubjectDataIdentifier = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 2] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 3)
        XCTAssertEqual(urlDataIdentifier, UTType.fileURL.identifier)
        XCTAssertEqual(itemForActivity as? URL, testFileURL)
        XCTAssertEqual(titleSubjectActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(titleSubjectSubject, testSubtitle)
        XCTAssertEqual(titleSubjectDataIdentifier, UTType.text.identifier)
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    // MARK: - Test sharing a website

    func testGetActivityItems_forWebsiteURL_withNoShareText() throws {
        let testShareActivityType = UIActivity.ActivityType.message

        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testWebURL),
            withExplicitShareMessage: nil
        )

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let itemForURLActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 1] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 2)
        XCTAssertEqual(itemForURLActivity as? URL, testWebURL)
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    func testGetActivityItems_forWebsiteURL_withShareText() throws {
        let testShareActivityType = UIActivity.ActivityType.message
        let testMessage = "Test message"
        let testSubtitle = "Test subtitle"

        let activityItems = ShareManager.getActivityItems(
            forShareType: .file(url: testWebURL),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )
        let itemForURLActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        let titleSubjectActivityItemProvider = try XCTUnwrap(
            activityItems[safe: 1] as? TitleSubtitleActivityItemProvider
        )
        let titleSubjectSubject = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            subjectForActivityType: testShareActivityType
        )
        let titleSubjectDataIdentifier = titleSubjectActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 2] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 3)
        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForURLActivity as? URL, testWebURL)
        XCTAssertEqual(titleSubjectActivityItemProvider.item as? String, testMessage)
        XCTAssertEqual(titleSubjectSubject, testSubtitle)
        XCTAssertEqual(titleSubjectDataIdentifier, UTType.text.identifier)
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    // MARK: - Test sharing a website with a related Tab and webview

    func testGetActivityItems_forTab_withNoShareText_sharedToMail() throws {
        let testShareActivityType = UIActivity.ActivityType.mail

        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: nil
        )

        // Check we get all types of share items for tabs below:
        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )
        let itemForUrlActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? HomePageActivity)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleActivityItemProvider)
        let itemForTitleActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 4] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 5)
        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForUrlActivity as? URL, testWebURL)
        XCTAssertTrue(
            itemForTitleActivity is NSNull,
            "We don't share a message for Mail, Messages, and Pasteboard when ShareMessage is not explicitly set"
        )
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    func testGetActivityItems_forTab_withNoShareText_sharedToNonExcludedActivity() throws {
        let testShareActivityType = UIActivity.ActivityType(rawValue: "com.random.non-excluded.activity")

        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: nil
        )

        // Check we get all types of share items for tabs below:
        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )
        let itemForUrlActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? HomePageActivity)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleActivityItemProvider)
        let itemForTitleActivity = titleActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 4] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(activityItems.count, 5)
        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForUrlActivity as? URL, testWebURL)
        XCTAssertEqual(
            itemForTitleActivity as? String,
            testWebpageDisplayTitle,
            "When no explicit ShareMessage is set, we expect to see the webpage's title for non-excluded activities."
        )
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    func testGetActivityItems_forTab_withShareText() throws {
        let testShareActivityType = UIActivity.ActivityType(rawValue: "com.random.non-excluded.activity")

        let activityItems = ShareManager.getActivityItems(
            forShareType: .tab(url: testWebURL, tab: testTab),
            withExplicitShareMessage: ShareMessage(message: testMessage, subtitle: testSubtitle)
        )

        // Check we get all types of share items for tabs below:
        let urlActivityItemProvider = try XCTUnwrap(activityItems[safe: 0] as? URLActivityItemProvider)
        let urlDataIdentifier = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            dataTypeIdentifierForActivityType: testShareActivityType
        )
        let itemForURLActivity = urlActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        _ = try XCTUnwrap(activityItems[safe: 1] as? TabPrintPageRenderer)

        _ = try XCTUnwrap(activityItems[safe: 2] as? HomePageActivity)

        let titleActivityItemProvider = try XCTUnwrap(activityItems[safe: 3] as? TitleSubtitleActivityItemProvider)

        let telemetryActivityItemProvider = try XCTUnwrap(activityItems[safe: 4] as? ShareTelemetryActivityItemProvider)
        let itemForShareActivity = telemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testShareActivityType
        )

        XCTAssertEqual(urlDataIdentifier, UTType.url.identifier)
        XCTAssertEqual(itemForURLActivity as? URL, testWebURL)
        XCTAssertEqual(activityItems.count, 5)
        XCTAssertEqual(
            titleActivityItemProvider.item as? String,
            testMessage,
            "When an explicit share message is set, we expect to see that message, not the webpage's title."
        )
        XCTAssertTrue(itemForShareActivity is NSNull)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }
}
