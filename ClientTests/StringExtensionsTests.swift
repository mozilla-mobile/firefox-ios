/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
}
