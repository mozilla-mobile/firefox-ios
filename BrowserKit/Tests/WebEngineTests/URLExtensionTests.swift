// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class URLExtensionTests: XCTestCase {
    private let webserverPort = 6571

    // MARK: isReaderModeURL tests

    func testIsReaderModeURLGivenGoogleURLThenFalse() {
        let url = URL(string: "https://google.com")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenHTTPSchemeURLThenFalse() {
        let url = URL(string: "http://google.com")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenLocalHostURLThenFalse() {
        let url = URL(string: "http://localhost")!
        XCTAssertFalse(url.isReaderModeURL)
    }

    func testIsReaderModeURLGivenReaderModeURLThenTrue() {
        let url = URL(string: "http://localhost:\(webserverPort)/reader-mode/page")!
        XCTAssertTrue(url.isReaderModeURL)
    }

    // MARK: isSyncedReaderModeURL tests

    func testIsSyncedReaderModeURLWhenEmptyURLThenIsTrue() {
        let url = "about:reader?url="
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenSimpleURLThenIsTrue() {
        let url = "about:reader?url=http://example.com"
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenComplicatedURLThenIsTrue() {
        let url = "about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage"
        XCTAssertTrue(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenGoogleURLThenIsFalse() {
        let url = "http://google.com"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenLocalHostURLThenIsFalse() {
        let url = "http://localhost:\(webserverPort)/sessionrestore.html"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    func testIsSyncedReaderModeURLWhenAboutURLThenIsFalse() {
        let url = "about:reader"
        XCTAssertFalse(URL(string: url)!.isSyncedReaderModeURL)
    }

    // MARK: decodeReaderModeURL tests

    func testDecodeReaderModeURLWhenLocalReaderModeThenGivesWikiPage() {
        let readerModeURL = "http://localhost:\(webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA"
        let url = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLWhenReaderModeThenGivesWikiPage() {
        let readerModeURL = "about:reader?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage&uuidkey=AAAAA"
        let url = URL(string: "https://en.m.wikipedia.org/wiki/Main_Page")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLWhenParameterURLThenGivesCorrectParameterURL() {
        let readerModeURL = "about:reader?url=http%3A%2F%2Fexample%2Ecom%3Furl%3Dparam%26key%3Dvalue&uuidkey=AAAAA"
        let url = URL(string: "http://example.com?url=param&key=value")

        XCTAssertEqual(URL(string: readerModeURL)!.decodeReaderModeURL, url)
    }

    func testDecodeReaderModeURLGivenNotAReaderModeURLThenNil() {
        let url = "http://google.com"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalHostSessionRestoreURLThenNil() {
        let url = "http://localhost:\(webserverPort)/sessionrestore.html"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalAboutHomeURLThenNil() {
        let url = "http://localhost:1234/about/home/#panel=0"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenLocalHostReaderModePageThenNil() {
        let url = "http://localhost:\(webserverPort)/reader-mode/page"
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    func testDecodeReaderModeURLWhenAboutReaderURLThenNil() {
        let url = "about:reader?url="
        XCTAssertNil(URL(string: url)!.decodeReaderModeURL)
    }

    // MARK: encodeReaderModeURL tests

    func testEncodeReaderModeURLGivenReaderAndURLThenEncodeReaderURL() {
        let readerURL = "http://localhost:\(webserverPort)/reader-mode/page"
        let stringURL = "https://en.m.wikipedia.org/wiki/Main_Page"
        let expectedReaderModeURL = URL(string: "http://localhost:\(webserverPort)/reader-mode/page?url=https%3A%2F%2Fen%2Em%2Ewikipedia%2Eorg%2Fwiki%2FMain%5FPage")

        XCTAssertEqual(URL(string: stringURL)!.encodeReaderModeURL(readerURL), expectedReaderModeURL)
    }

    // MARK: safeEncodedUrl tests

    func testSafeEncodedUrlGivenJavaScriptSanitization() {
        // reader mode generic url sanitized JS to prevent XSS alert
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:alert('ALERT')")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:alert(%26%2339;ALERT%26%2339;)")
        )
    }

    func testSafeEncodedUrlGivenScriptInnerHtmlTextSanitization() {
        // reader mode generic url script tags are sanitized to prevent body change
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:document.body.innerText='Hello';")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:document.body.innerText%3D%26%2339;Hello%26%2339;;")
        )
    }

    func testSafeEncodedUrlGivenHTMLFontSanitization() {
        // reader mode generic url with HTML is sanitized
        let url = URL(string: "http://localhost:1234/reader-mode/page?url=javascript:document.body.style.fontSize='50px';")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(
            genericUrl!.absoluteString.contains("javascript:document.body.style.fontSize%3D%26%2339;50px%26%2339;;")
        )
    }

    func testSafeEncodedUrlGivenJavaScriptSanitizationNonLocalhost() {
        // Check if JavaScript code in a non-localhost URL is sanitized
        let url = URL(string: "http://example.com/reader-mode/page?url=javascript:alert('XSS')")!
        let genericUrl = url.safeEncodedUrl
        XCTAssertNotNil(genericUrl)
        XCTAssertTrue(genericUrl!.absoluteString.contains("javascript:alert(%26%2339;XSS%26%2339;)"))
    }

    func testSafeEncodedUrlGivenEmptyPath() {
        let url = URL(string: "http://localhost:1234")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNotNil(safeUrl)
    }

    func testSafeEncodedUrlGivenEmptyScheme() {
        let url = URL(string: "//localhost:1234/page")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testSafeEncodedUrlGivenMissingComponentsJS() {
        let url = URL(string: "javascript:blob")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testSafeEncodedUrlGivenMissingComponents() {
        let url = URL(string: "/page?url=javascript")!
        let safeUrl = url.safeEncodedUrl
        XCTAssertNil(safeUrl)
    }

    func testFaviconRootDirectoryURL() {
        let url1 = URL(string: "https://some.domain.com/path/subpath")
        let favicon1 = url1?.faviconUrl()
        XCTAssertEqual(favicon1, URL(string: "https://some.domain.com/favicon.ico")!)

        let url2 = URL(string: "http://website.org////")
        let favicon2 = url2?.faviconUrl()
        XCTAssertEqual(favicon2, URL(string: "http://website.org/favicon.ico")!)

        let url3 = URL(string: "scheme://another.website.net/path/")
        let favicon3 = url3?.faviconUrl()
        XCTAssertEqual(favicon3, URL(string: "scheme://another.website.net/favicon.ico")!)
    }
}
