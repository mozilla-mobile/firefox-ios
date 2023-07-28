// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import XCTest
@testable import Client

class StringExtensionsTests: XCTestCase {
    func testEllipsize() {
        // Odd maxLength. Note that we ellipsize with a Unicode join character to avoid wrapping.
        XCTAssertEqual("abcd…\u{2060}fgh", "abcdefgh".ellipsize(maxLength: 7))

        // Even maxLength.
        XCTAssertEqual("abcd…\u{2060}ijkl", "abcdefghijkl".ellipsize(maxLength: 8))

        // String shorter than maxLength.
        XCTAssertEqual("abcd", "abcd".ellipsize(maxLength: 7))

        // Empty String.
        XCTAssertEqual("", "".ellipsize(maxLength: 8))

        // maxLength < 2.
        XCTAssertEqual("abcdefgh", "abcdefgh".ellipsize(maxLength: 0))
    }

    func testStringByTrimmingLeadingCharactersInSet() {
        XCTAssertEqual("foo   ", "   foo   ".stringByTrimmingLeadingCharactersInSet(.whitespaces))
        XCTAssertEqual("foo456", "123foo456".stringByTrimmingLeadingCharactersInSet(.decimalDigits))
        XCTAssertEqual("", "123456".stringByTrimmingLeadingCharactersInSet(.decimalDigits))
    }

    func testStringSplitWithNewline() {
        XCTAssertEqual("", "".stringSplitWithNewline())
        XCTAssertEqual("foo", "foo".stringSplitWithNewline())
        XCTAssertEqual("aaa\n bbb", "aaa bbb".stringSplitWithNewline())
        XCTAssertEqual("Mark as\n Read", "Mark as Read".stringSplitWithNewline())
        XCTAssertEqual("aa\n bbbbbb", "aa bbbbbb".stringSplitWithNewline())
    }

    func testPercentEscaping() {
        func roundtripTest(_ input: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
            let observed = input.escape()!
            XCTAssertEqual(observed, expected, "input is \(input)", file: file, line: line)
            let roundtrip = observed.unescape()
            XCTAssertEqual(roundtrip, input, "encoded is \(observed)", file: file, line: line)
        }

        roundtripTest("https://mozilla.com", "https://mozilla.com")
        roundtripTest("http://www.cnn.com/2017/09/25/politics/north-korea-fm-us-bombers/index.html", "http://www.cnn.com/2017/09/25/politics/north-korea-fm-us-bombers/index.html")
        roundtripTest("http://mozilla.com/?a=foo&b=bar", "http://mozilla.com/%3Fa%3Dfoo%26b%3Dbar")
    }

    func testRemoveUnicodeFromFilename() {
        let file = "foo-\u{200F}cod.jpg" // Unicode RTL-switch code, becomes "foo-gpj.doc"
        let nounicode = "foo-cod.jpg"
        XCTAssert(file != nounicode)
        let strip = HTTPDownload.stripUnicode(fromFilename: file)
        XCTAssert(strip == nounicode)
    }

    func testBoldString() {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let text = "abcdefbcde"
        // The source string contains the substring twice;
        // `attributedText(boldString:font:)` should only bold the first
        // occurrence.
        let attributedText = text.attributedText(boldString: "bcde", font: font)
        var effectiveRange = NSRange()

        XCTAssertEqual(attributedText.attribute(.font, at: 0, effectiveRange: &effectiveRange) as? UIFont, font)
        XCTAssertEqual(effectiveRange, NSRange(location: 0, length: 1))

        XCTAssertEqual(
            attributedText.attribute(.font, at: 1, effectiveRange: &effectiveRange) as? UIFont,
            DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: font.pointSize)
        )
        XCTAssertEqual(effectiveRange, NSRange(location: 1, length: 4))

        XCTAssertEqual(attributedText.attribute(.font, at: 5, effectiveRange: &effectiveRange) as? UIFont, font)
        XCTAssertEqual(effectiveRange, NSRange(location: 5, length: 5))
    }

    func testBoldInRange() {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let text = "abcdefbcde"
        let attributedText = text.attributedText(boldIn: text.index(text.endIndex, offsetBy: -4)..<text.endIndex, font: font)
        var effectiveRange = NSRange()

        XCTAssertEqual(attributedText.attribute(.font, at: 0, effectiveRange: &effectiveRange) as? UIFont, font)
        XCTAssertEqual(effectiveRange, NSRange(location: 0, length: 6))

        XCTAssertEqual(
            attributedText.attribute(.font, at: 6, effectiveRange: &effectiveRange) as? UIFont,
            DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .body, size: font.pointSize)
        )
        XCTAssertEqual(effectiveRange, NSRange(location: 6, length: 4))
    }

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

    // MARK: - Tests for match method

    // Helper method
    func getResultFrom(inputString: String,
                       andRegex pattern: String,
                       file: StaticString = #file,
                       line: UInt = #line) throws -> String {
        try XCTUnwrap(inputString.match(pattern), "Failed to extract the matching group.")
    }

    func testMatchRegex_withValidInput() {
        let expectedResult = "1234567"
        let result = try? getResultFrom(inputString: "https://www.example.com/product/1234567/item",
                                        andRegex: "\\/product\\/(\\d+)\\/item")
        XCTAssertEqual(result, expectedResult)
    }

    func testMatchRegex_withInvalidInput() {
        let inputString = "This is not a valid URL string"
        let regexPattern = "\\d+" // Invalid pattern, should fail

        XCTAssertNil(inputString.match(regexPattern))
    }

    func testMatchRegex_withNoMatchingGroup() {
        let inputString = "https://www.example.com"
        let regexPattern = "\\/product\\/(\\d+)\\/item"
        XCTAssertNil(inputString.match(regexPattern))
    }

    func testMatchRegex_withMultipleMatches() {
        let expectedResult = "123" // Only the first match is returned
        let result = try? getResultFrom(inputString: "https://www.example.com/product/123/item/product/456/item",
                                        andRegex: "\\/product\\/(\\d+)\\/item")
        XCTAssertEqual(result, expectedResult)
    }

    func testMatchRegex_withCaptureGroupAtDifferentIndex() {
        let expectedResult = "123"
        let result = try? getResultFrom(inputString: "https://www.example.com/product/123/item",
                                        andRegex: "\\/product\\/(\\d+)(\\/item)")
        XCTAssertEqual(result, expectedResult)
    }
}
