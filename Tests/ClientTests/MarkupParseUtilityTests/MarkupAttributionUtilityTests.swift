// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MarkupAttributionUtilityTests: XCTestCase {
    let baseFont = Font.systemFont(ofSize: 16)
    var subject: MarkupAttributeUtility!

    override func setUp() {
        super.setUp()
        subject = MarkupAttributeUtility(baseFont: baseFont)
    }

    func testPlainText_render_rendersPlainText() {
        let input = "hello there"
        let expected = NSAttributedString(
            string: "hello there",
            attributes: [NSAttributedString.Key.font: baseFont])

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testStrongText_render_rendersBoldText() {
        let input = "hello *there*"
        let boldFont = baseFont.boldFont()!
        let expected = [
            NSAttributedString(string: "hello ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "there",
                               attributes: [NSAttributedString.Key.font: boldFont])
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testEmphasizedText_render_rendersItalicText() {
        let input = "hello _there_"
        let italicFont = baseFont.italicFont()!
        let expected = [
            NSAttributedString(string: "hello ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "there",
                               attributes: [NSAttributedString.Key.font: italicFont])
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testStrongEmphasizedText_render_rendersBoldItalicText() {
        let input = "hello *_there_* _*there*_"
        let boldItalicFont = baseFont.boldFont()!.italicFont()!
        let expected = [
            NSAttributedString(string: "hello ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "there",
                               attributes: [NSAttributedString.Key.font: boldItalicFont]),
            NSAttributedString(string: " ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "there",
                               attributes: [NSAttributedString.Key.font: boldItalicFont])
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }
}
