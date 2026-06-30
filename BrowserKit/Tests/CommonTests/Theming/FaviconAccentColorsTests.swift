// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class FaviconAccentColorsTests: XCTestCase {
    override func tearDown() {
        FaviconLetterColorSet.isNovaDesignEnabled = { false }
        super.tearDown()
    }

    func testCurrent_followsNovaDesignFlag() {
        FaviconLetterColorSet.isNovaDesignEnabled = { false }
        XCTAssertEqual(FaviconLetterColorSet.current.backgroundColors,
                       StandardFaviconAccentColors.palette.backgroundColors)

        FaviconLetterColorSet.isNovaDesignEnabled = { true }
        XCTAssertEqual(FaviconLetterColorSet.current.backgroundColors,
                       NovaFaviconAccentColors.palette.backgroundColors)
    }

    func testPalettes_have42ColorsAndDiffer() {
        XCTAssertEqual(NovaFaviconAccentColors.palette.backgroundColors.count, 42)
        XCTAssertEqual(StandardFaviconAccentColors.palette.backgroundColors.count, 42)
        XCTAssertNotEqual(NovaFaviconAccentColors.palette.backgroundColors,
                          StandardFaviconAccentColors.palette.backgroundColors)
    }

    func testNovaLetters_useTextOnLightForLightShades_textOnDarkForDarkShades() {
        let palette = NovaFaviconAccentColors.palette
        let nova = NovaLightTheme().colors

        for (index, letter) in palette.letterColors.enumerated() {
            let expected = (index % 7) < 4 ? nova.textOnLight : nova.textOnDark
            XCTAssertEqual(letter, expected, "letter at index \(index)")
        }
    }

    func testStandardLetters_areAllWhite() {
        XCTAssertTrue(StandardFaviconAccentColors.palette.letterColors.allSatisfy { $0 == .white })
    }
}
