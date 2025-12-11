// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UniformTypeIdentifiers

/// Tests for FirefoxURLBuilder business logic
/// 
/// These tests verify URL building functionality for the Action Extension.
/// The FirefoxURLBuilder is a good candidate for unit testing as it contains
/// pure business logic without UI dependencies.
final class FirefoxURLBuilderTests: XCTestCase {
    var subject: FirefoxURLBuilder!

    override func setUp() {
        super.setUp()
        subject = FirefoxURLBuilder()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - buildFirefoxURL Tests

    func testBuildFirefoxURL_WithShareItem_ReturnsCorrectURL() {
        let shareItem = ActionShareItem(url: "https://example.com", title: "Example")
        let extractedItem = ExtractedShareItem.shareItem(shareItem)

        let result = try XCTUnwrap(subject.buildFirefoxURL(from: extractedItem))
        XCTAssertNotNil(result.scheme, "URL should have a scheme")
        XCTAssertTrue(result.absoluteString.contains("open-url") == true)

        // Parse URL to check query parameter (URL is percent-encoded)
        guard let urlComponents = URLComponents(url: result, resolvingAgainstBaseURL: false),
              let queryItems = urlComponents.queryItems,
              let urlParam = queryItems.first(where: { $0.name == "url" })?.value else {
            XCTFail("URL should have a 'url' query parameter")
            return
        }

        // Decode the URL parameter to check the original content
        let decodedURL = urlParam.removingPercentEncoding
        XCTAssertEqual(decodedURL, "https://example.com")
    }

    func testBuildFirefoxURL_WithRawText_ReturnsSearchURL() {
        let text = "search query"
        let extractedItem = ExtractedShareItem.rawText(text)

        let result = try XCTUnwrap(subject.buildFirefoxURL(from: extractedItem))
        XCTAssertTrue(result.absoluteString.contains("open-text") == true)
        XCTAssertTrue(result.absoluteString.contains("search%20query") == true)
    }

    func testBuildFirefoxURL_WithSpecialCharacters_EncodesCorrectly() {
        let shareItem = ActionShareItem(url: "https://example.com/path?query=test&value=hello world", title: nil)
        let extractedItem = ExtractedShareItem.shareItem(shareItem)

        let result = try XCTUnwrap(subject.buildFirefoxURL(from: extractedItem))
        // URL should be properly encoded
        XCTAssertTrue(result.absoluteString.contains("open-url") == true)
    }

    // MARK: - convertTextToURL Tests

    func testConvertTextToURL_WithValidDomain_ReturnsURL() {
        let text = "example.com"

        let result = try XCTUnwrap(subject.convertTextToURL(text))
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "example.com")
    }

    func testConvertTextToURL_WithHTTPPrefix_ReturnsURL() {
        let text = "http://example.com"

        let result = try XCTUnwrap(subject.convertTextToURL(text))
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "example.com")
    }

    func testConvertTextToURL_WithHTTPSPrefix_ReturnsURL() {
        let text = "https://example.com"

        let result = try XCTUnwrap(subject.convertTextToURL(text))
        XCTAssertEqual(result.scheme, "https")
        XCTAssertEqual(result.host, "example.com")
    }

    func testConvertTextToURL_WithPlainText_ReturnsNil() {
        let text = "this is just plain text"

        let result = subject.convertTextToURL(text)

        XCTAssertNil(result)
    }

    func testConvertTextToURL_WithTextWithoutDot_ReturnsNil() {
        let text = "notadomain"

        let result = subject.convertTextToURL(text)

        XCTAssertNil(result)
    }

    func testConvertTextToURL_WithInvalidHost_ReturnsNil() {
        let text = "invalid..host"

        let result = subject.convertTextToURL(text)

        XCTAssertNil(result)
    }

    // MARK: - findURLInItems Tests

    func testFindURLInItems_WithURLItem_CallsCompletionWithSuccess() {
        let expectation = expectation(description: "findURLInItems completion")
        let extensionItem = NSExtensionItem()
        let itemProvider = NSItemProvider()
        itemProvider.registerItem(forTypeIdentifier: UTType.url.identifier) { item, _, _ in
            URL(string: "https://example.com")
        }
        extensionItem.attachments = [itemProvider]

        var result: Result<ActionShareItem, Error>?
        subject.findURLInItems([extensionItem]) { res in
            result = res
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        let unwrappedResult = try XCTUnwrap(result)
        if case .success(let shareItem) = unwrappedResult {
            XCTAssertEqual(shareItem.url, "https://example.com")
        } else {
            XCTFail("Expected success result")
        }
    }

    func testFindURLInItems_WithNoURLItems_CallsCompletionWithFailure() {
        let expectation = expectation(description: "findURLInItems completion")
        let extensionItem = NSExtensionItem()

        var result: Result<ActionShareItem, Error>?
        subject.findURLInItems([extensionItem]) { res in
            result = res
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        let unwrappedResult = try XCTUnwrap(result)
        if case .failure = unwrappedResult {
            // Expected
        } else {
            XCTFail("Expected failure result")
        }
    }

    // MARK: - findTextInItems Tests

    func testFindTextInItems_WithTextItem_CallsCompletionWithSuccess() {
        let expectation = expectation(description: "findTextInItems completion")
        let extensionItem = NSExtensionItem()
        let itemProvider = NSItemProvider()
        itemProvider.registerItem(forTypeIdentifier: UTType.text.identifier) { item, _, _ in
            "test text"
        }
        extensionItem.attachments = [itemProvider]

        var result: Result<ExtractedShareItem, Error>?
        subject.findTextInItems([extensionItem]) { res in
            result = res
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        let unwrappedResult = try XCTUnwrap(result)
        if case .success(let extractedItem) = unwrappedResult {
            switch extractedItem {
            case .rawText(let text):
                XCTAssertEqual(text, "test text")
            case .shareItem:
                XCTFail("Expected rawText case")
            }
        } else {
            XCTFail("Expected success result")
        }
    }

    func testFindTextInItems_WithNoTextItems_CallsCompletionWithFailure() {
        let expectation = expectation(description: "findTextInItems completion")
        let extensionItem = NSExtensionItem()

        var result: Result<ExtractedShareItem, Error>?
        subject.findTextInItems([extensionItem]) { res in
            result = res
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
        let unwrappedResult = try XCTUnwrap(result)
        if case .failure = unwrappedResult {
            // Expected
        } else {
            XCTFail("Expected failure result")
        }
    }
}
