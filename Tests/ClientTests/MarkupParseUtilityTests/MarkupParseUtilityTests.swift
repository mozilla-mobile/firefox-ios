// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MarkupParseUtilityTests: XCTestCase {
    func testEmptyText_returnsPlainText() {
        let input = ""
        let expected: [MarkupNode] = []

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testPlainText_returnsPlainText() {
        let input = "I just wanna $.tell;' ya"
        let expected: [MarkupNode] = [.text("I just wanna $.tell;' ya")]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testPlainTextWithSpecialCharacters_returnsPlainText() {
        let input = "How *_I'm feeling"
        let expected: [MarkupNode] = [
            .text("How "),
            .text("*"),
            .text("_"),
            .text("I'm feeling")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testLeftBoldDelimiterWithoutRightDelimiter_returnsPlainText() {
        let input = "Gotta make *you understand"
        let expected: [MarkupNode] = [
            .text("Gotta make "),
            .text("*"),
            .text("you understand")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testLeftItalicsDelimiterWithoutRightDelimiter_returnsPlainText() {
        let input = "Never gonna give _you up"
        let expected: [MarkupNode] = [
            .text("Never gonna give "),
            .text("_"),
            .text("you up")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testDelimitersEnclosedByPunctuation_returnsFormattedText() {
        let input = "Never gonna let you:*down*!"
        let expected: [MarkupNode] = [
            .text("Never gonna let you:"),
            .bold([.text("down")]),
            .text("!")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testDelimitersEnclosedByWhitespace_returnsFormattedText() {
        let input = "Never gonna run *around* "
        let expected: [MarkupNode] = [
            .text("Never gonna run "),
            .bold([.text("around")]),
            .text(" ")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testDelimitersEnclosedByNewlines_returnsFormattedText() {
        let input = "And desert:\n*you*\n"
        let expected: [MarkupNode] = [
            .text("And desert:\n"),
            .bold([.text("you")]),
            .text("\n")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testDelimitersAtBounds_returnsFormattedText() {
        let input = "*Never gonna make you cry*"
        let expected: [MarkupNode] = [
            .bold([
                .text("Never gonna make you cry")
            ])
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testOpeningDelimiterEnclosedByDelimiters_returnsFormattedText() {
        let input = "Never gonna say *_goodbye*_"
        let expected: [MarkupNode] = [
            .text("Never gonna say "),
            .bold([
                .text("_"),
                .text("goodbye")
            ]),
            .text("_")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testIntrawordDelimiters_intrawordDelimitersAreIgnored() {
        let input = "_never_gonna_tell_a_lie_"
        let expected: [MarkupNode] = [
            .italics([
                .text("never"),
                .text("_"),
                .text("gonna"),
                .text("_"),
                .text("tell"),
                .text("_"),
                .text("a"),
                .text("_"),
                .text("lie")
            ])
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }

    func testNestedDelimiters_returnsNestedMarkup() {
        let input = "and *_hurt you_*!"
        let expected: [MarkupNode] = [
            .text("and "),
            .bold([
                .italics([
                    .text("hurt you")
                ])
            ]),
            .text("!")
        ]

        let result = MarkupParsingUtility().parse(text: input)

        XCTAssertEqual(result, expected)
    }
}
