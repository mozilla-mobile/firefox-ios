// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class URLFormatterTests: XCTestCase {
    // MARK: - Valid cases

    func testGetURLGivenInternalURLThenValidURL() {
        let initialUrl = "internal://example.com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenStandardURLThenValidInitialURL() {
        let initialUrl = "http://www.mozilla.org"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenAboutConfigURLThenValidInitialURL() {
        let initialUrl = "about:config"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenAboutConfigSpaceURLThenValidEscapedURL() {
        let initialUrl = "about: config"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "about:%20config")
    }

    func testGetURLGivenFileURLThenValidInitialURL() {
        let initialUrl = "file:///f/o/o"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenFtpURLThenValidInitialURL() {
        let initialUrl = "ftp://ftp.mozilla.org"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenNoHttpsURLThenValidURL() {
        let initialUrl = "foo.bar"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenNoHttpsURLWithCapitalLetterThenValidURL() {
        let initialUrl = "foo.Bar"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenNoHttpsWithSpaceURLThenValidURL() {
        let initialUrl = "foo.bar"
        let givenURL = " \(initialUrl)"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: givenURL)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenDotURLThenValidURL() {
        let initialUrl = "1.2.3"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenIconicSydneyThenValidURL() {
        let initialUrl = "iconic.sydney"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenLocalHostHtmlThenValidURL() {
        let initialUrl = "localhost:4242/test-fixture/test-example.html"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenLocalHostOnlyThenValidURL() {
        let initialUrl = "localhost"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenLocalHostWithPathAndCapitalLettersThenValidURL() {
        let initialUrl = "LoCalhOsT/foo"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, "http://\(initialUrl)")
    }

    func testGetURLGivenMailtoSchemeURLThenValidURL() {
        let initialUrl = "mailto:jsmith@example.com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    func testGetURLGivenDNSSchemeURLThenValidURL() {
        let initialUrl = "dns://192.168.1.1/ftp.example.org?type=A"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertEqual(result?.absoluteString, initialUrl)
    }

    // MARK: - Invalid cases

    func testGetURLGivenEmptyURLThenInvalidURL() {
        let initialUrl = ""
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenFooBarURLThenInvalidURL() {
        let initialUrl = "foobar"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenFooSpaceBarURLThenInvalidURL() {
        let initialUrl = "foo bar"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenURLWithSpaceBeforeTLDThenInvalidURL() {
        let initialUrl = "mozilla. org"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenNumbersThenInvalidURL() {
        let initialUrl = "123"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenPathThenInvalidURL() {
        let initialUrl = "a/b"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenChineseCharactersThenInvalidURL() {
        let initialUrl = "创业咖啡"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenChineseCharactersWithSpaceThenInvalidURL() {
        let initialUrl = "创业咖啡 中国"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenChineseCharactersWithDotAndSpaceThenInvalidURL() {
        let initialUrl = "创业咖啡. 中国"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenAboutSchemeThenInvalidURL() {
        let initialUrl = "about:"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenJavascriptSchemeThenInvalidURL() {
        let initialUrl = "javascript:"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenJavascriptAlertThenInvalidURL() {
        let initialUrl = "javascript:alert(%22hi%22)"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenFtpSchemeThenInvalidURL() {
        let initialUrl = "ftp:"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenNumberWithDotNumberThenInvalidURL() {
        let initialUrl = "127.1"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenNumberEndingWithDotThenInvalidURL() {
        let initialUrl = "999."
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenNegativeDecimalNumberThenInvalidURL() {
        let initialUrl = "-.05"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenPositiveDotsNumbersThenInvalidURL() {
        let initialUrl = "+2.1.0"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenSuffixNotPublicSuffixThenInvalidURL() {
        let initialUrl = "apple.iphone"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenUrlWithSpaceThenInvalidURL() {
        let initialUrl = "http:// shouldfail.com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenURLWithNumbersNoTLDThenInvalidURL() {
        let initialUrl = "http://0123456789"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenSpaceInDomainThenInvalidURL() {
        let initialUrl = "mo zilla.com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenSpaceBeforeTLDThenInvalidURL() {
        let initialUrl = "www.firefox .com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenHTTPURLWithSpaceInDomainThenInvalidURL() {
        let initialUrl = "http://fire fox.com"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenWordThenInvalidURL() {
        let initialUrl = "mozilla"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenAddressWithBracketsThenInvalidURL() {
        let initialUrl = "http://[2001:db8:85a3::8a2e:370:7334]"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenSpecialCharsThenInvalidURL() {
        let initialUrl = ":/#?&@%+~"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenFirefoxSchemeThenInvalidURL() {
        let initialUrl = "firefox://"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenFeedSchemeURLThenInvalidURL() {
        let initialUrl = "feed://example.com/rss.xml"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenGitSchemeURLThenInvalidURL() {
        let initialUrl = "git://github.com/user/project-name.git"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenSmbSchemeURLThenInvalidURL() {
        let initialUrl = "smb://workgroup;user:password@server/share/folder/file.txt"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenViewSourceSchemeURLThenInvalidURL() {
        let initialUrl = "view-source:http://en.wikipedia.org/wiki/URI_scheme"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }

    func testGetURLGivenNoTLDThenInvalidURL() {
        let initialUrl = "http://mozilla"
        let subject = DefaultURLFormatter()

        let result = subject.getURL(entry: initialUrl)

        XCTAssertNil(result)
    }
}
