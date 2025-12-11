// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UniformTypeIdentifiers

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

    func testBuildFirefoxURL_WithShareItem_ReturnsCorrectURL() throws {
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

    func testBuildFirefoxURL_WithRawText_ReturnsSearchURL() throws {
        let text = "search query"
        let extractedItem = ExtractedShareItem.rawText(text)

        let result = try XCTUnwrap(subject.buildFirefoxURL(from: extractedItem))
        XCTAssertTrue(result.absoluteString.contains("open-text") == true)
        XCTAssertTrue(result.absoluteString.contains("search%20query") == true)
    }

    func testBuildFirefoxURL_WithSpecialCharacters_EncodesCorrectly() throws {
        let shareItem = ActionShareItem(url: "https://example.com/path?query=test&value=hello world", title: nil)
        let extractedItem = ExtractedShareItem.shareItem(shareItem)

        let result = try XCTUnwrap(subject.buildFirefoxURL(from: extractedItem))
        // URL should be properly encoded
        XCTAssertTrue(result.absoluteString.contains("open-url") == true)
    }

    // MARK: - convertTextToURL Tests

    func testConvertTextToURL_WithValidDomain_ReturnsURL() throws {
        let text = "example.com"

        let result = try XCTUnwrap(subject.convertTextToURL(text))
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "example.com")
    }

    func testConvertTextToURL_WithHTTPPrefix_ReturnsURL() throws {
        let text = "http://example.com"

        let result = try XCTUnwrap(subject.convertTextToURL(text))
        XCTAssertEqual(result.scheme, "http")
        XCTAssertEqual(result.host, "example.com")
    }

    func testConvertTextToURL_WithHTTPSPrefix_ReturnsURL() throws {
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
}
