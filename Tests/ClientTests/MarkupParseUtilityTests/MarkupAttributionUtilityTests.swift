// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MarkupAttributionUtilityTests: XCTestCase {
    let baseFont = UIFont.systemFont(ofSize: 16)
    var subject: MarkupAttributeUtility!

    override func setUp() {
        super.setUp()
        subject = MarkupAttributeUtility(baseFont: baseFont)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testPlainText_render_rendersPlainText() {
        let input = "Hello there!"
        let expected = NSAttributedString(
            string: "Hello there!",
            attributes: [NSAttributedString.Key.font: baseFont])

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testStrongText_render_rendersBoldText() {
        let input = "General kenobi. *You are a bold one!*"
        let boldFont = baseFont.boldFont()!
        let expected = [
            NSAttributedString(string: "General kenoby. ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "You are a bold one!",
                               attributes: [NSAttributedString.Key.font: boldFont])
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testEmphasizedText_render_rendersItalicText() {
        let input = "Back away. I will deal with this _jedi slime_ myself."
        let italicFont = baseFont.italicFont()!
        let expected = [
            NSAttributedString(string: "Back away. I will deal with this ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "jedi slime ",
                               attributes: [NSAttributedString.Key.font: italicFont]),
            NSAttributedString(string: "myself.",
                               attributes: [NSAttributedString.Key.font: baseFont]),
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }

    func testStrongEmphasizedText_render_rendersBoldItalicText() {
        let input = "You *_fool._* I've been trained in your Jedi arts by _*Count Dooku._*"
        let boldItalicFont = baseFont.boldFont()!.italicFont()!
        let expected = [
            NSAttributedString(string: "You ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "fool.",
                               attributes: [NSAttributedString.Key.font: boldItalicFont]),
            NSAttributedString(string: " I've been trained in your Jedi arts by ",
                               attributes: [NSAttributedString.Key.font: baseFont]),
            NSAttributedString(string: "Count Dooku.",
                               attributes: [NSAttributedString.Key.font: boldItalicFont])
        ].joined()

        let result = subject.addAttributesTo(text: input)

        XCTAssertEqual(result, expected)
    }
}
