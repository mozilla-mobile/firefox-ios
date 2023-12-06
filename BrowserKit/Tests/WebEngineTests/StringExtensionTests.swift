// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class StringExtensionTests: XCTestCase {
    // MARK: Tests for HtmlEntityEncoding string
    func testHtmlEntityEncoding_noSpecialCharacters() {
        let input = "John Doe"
        XCTAssertEqual(input.htmlEntityEncodedString, "John Doe")
    }

    func testHtmlEntityEncoding_withSpecialCharacters() {
        let input = "<John Doe>"
        XCTAssertEqual(input.htmlEntityEncodedString, "&lt;John Doe&gt;")
    }

    func testHtmlEntityEncoding_withXssPayload() {
        let input = "<script>alert('XSS')</script>"
        XCTAssertEqual(input.htmlEntityEncodedString, "&lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;")
    }

    func testHtmlEntityEncoding_withHtmlEntities() {
        let input = "&quot;John Doe&quot;"
        XCTAssertEqual(input.htmlEntityEncodedString, "&amp;quot;John Doe&amp;quot;")
    }

    func testHtmlEntityEncoding_withMultipleSpecialCharacters() {
        let input = "<John & 'Doe'>"
        XCTAssertEqual(input.htmlEntityEncodedString, "&lt;John &amp; &#39;Doe&#39;&gt;")
    }

    func testHtmlEntityEncoding_withUnicodeCharacters() {
        let input = "Mëtàl Hëàd"
        XCTAssertEqual(input.htmlEntityEncodedString, "Mëtàl Hëàd")
    }

    func testHtmlEntityEncoding_withNumbers() {
        let input = "12345"
        XCTAssertEqual(input.htmlEntityEncodedString, "12345")
    }

    func testHtmlEntityEncoding_withEmptyString() {
        let input = ""
        XCTAssertEqual(input.htmlEntityEncodedString, "")
    }
}
