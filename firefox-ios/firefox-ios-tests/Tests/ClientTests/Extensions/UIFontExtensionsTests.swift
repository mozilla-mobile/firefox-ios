// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class UIFontExtensionsTests: XCTestCase {

    // MARK: - bolded()
    func testBolded_addsTraitBold() {
        let font = UIFont.systemFont(ofSize: 16)
        let boldFont = font.bolded()

        guard let boldFont else {
            XCTFail("Expected valid bold font")
            return
        }

        XCTAssertTrue(boldFont.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    func testBolded_preservesFontSize() {
        let originalSize: CGFloat = 24
        let font = UIFont.systemFont(ofSize: originalSize)

        guard let boldFont = font.bolded() else {
            XCTFail("Expected valid bold font")
            return
        }

        XCTAssertEqual(boldFont.pointSize, originalSize)
    }

    func testBolded_onAlreadyBoldFont_maintainsBold() {
        let boldFont = UIFont.boldSystemFont(ofSize: 16)

        guard let doubleBoldFont = boldFont.bolded() else {
            XCTFail("Expected valid bold font")
            return
        }
        XCTAssertTrue(doubleBoldFont.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    // MARK: - italicized()
    func testItalicized_addsTraitItalic() {
        let font = UIFont.systemFont(ofSize: 16)

        guard let italicFont = font.italicized() else {
            XCTFail("Expected valid italic font")
            return
        }

        XCTAssertTrue(italicFont.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    func testItalicized_preservesFontSize() {
        let originalSize: CGFloat = 18
        let font = UIFont.systemFont(ofSize: originalSize)

        guard let italicFont = font.italicized() else {
            XCTFail("Expected valid italic font")
            return
        }

        XCTAssertEqual(italicFont.pointSize, originalSize)
    }

    func testItalicized_onAlreadyItalicFont_maintainsItalic() {
        let italicFont = UIFont.italicSystemFont(ofSize: 16)
        guard let doubleItalicFont = italicFont.italicized() else {
            XCTFail("Expected valid italic font")
            return
        }

        XCTAssertTrue(doubleItalicFont.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    // MARK: - Combined traits
    func testBolded_thenItalicized_hasBothTraits() {
        let font = UIFont.systemFont(ofSize: 16)

        guard  let boldFont = font.bolded(),
                   let boldItalicFont = boldFont.italicized() else {
            XCTFail("Expected valid bold and italic font")
            return
        }

        let traits = boldItalicFont.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits.contains(.traitBold))
        XCTAssertTrue(traits.contains(.traitItalic))
    }

    func testItalicized_thenBolded_hasBothTraits() {
        let font = UIFont.systemFont(ofSize: 16)

        guard let italicFont = font.italicized(),
              let italicBoldFont = italicFont.bolded() else {
            XCTFail("Expected valid bold and italic font")
            return
        }

        let traits = italicBoldFont.fontDescriptor.symbolicTraits
        XCTAssertTrue(traits.contains(.traitItalic))
        XCTAssertTrue(traits.contains(.traitBold))

    }

    func testCombinedTraits_preserveOriginalSize() {
        let originalSize: CGFloat = 20
        let font = UIFont.systemFont(ofSize: originalSize)

        let styledFont = font.bolded()?.italicized()
        XCTAssertNotNil(styledFont, "Expected valid bold and italic font")
        XCTAssertEqual(styledFont?.pointSize, originalSize)
    }
}
