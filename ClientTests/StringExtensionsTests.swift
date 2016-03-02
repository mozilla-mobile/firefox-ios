/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class StringExtensionsTests: XCTestCase {
    func testContains() {
        XCTAssertTrue("abcde".contains("abcde"))
        XCTAssertTrue("abcde".contains(""))
        XCTAssertTrue("abcde".contains("a"))
        XCTAssertTrue("abcde".contains("e"))
        XCTAssertFalse("abcde".contains("f"))
        XCTAssertFalse("abcde".contains("fa"))
        XCTAssertFalse("abcde".contains("ef"))
    }

    func testStartsWith() {
        XCTAssertTrue("abcde".startsWith("abcde"))
        XCTAssertTrue("abcde".startsWith(""))
        XCTAssertTrue("abcde".startsWith("a"))
        XCTAssertTrue("abcdea".startsWith("a"))
        XCTAssertFalse("abcde".startsWith("fa"))
        XCTAssertFalse("abcde".startsWith("af"))
        XCTAssertFalse("abcde".startsWith("b"))
    }

    func testEndsWith() {
        XCTAssertTrue("abcde".endsWith("abcde"))
        XCTAssertTrue("abcde".endsWith(""))
        XCTAssertTrue("abcde".endsWith("e"))
        XCTAssertTrue("abcdea".endsWith("a"))
        XCTAssertFalse("abcde".endsWith("fe"))
        XCTAssertFalse("abcde".endsWith("ef"))
        XCTAssertFalse("abcde".endsWith("d"))
    }

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
        XCTAssertEqual("foo   ", "   foo   ".stringByTrimmingLeadingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()))
        XCTAssertEqual("foo456", "123foo456".stringByTrimmingLeadingCharactersInSet(NSCharacterSet.decimalDigitCharacterSet()))
        XCTAssertEqual("", "123456".stringByTrimmingLeadingCharactersInSet(NSCharacterSet.decimalDigitCharacterSet()))
    }
}
