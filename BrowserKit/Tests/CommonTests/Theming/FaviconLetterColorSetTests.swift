// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class FaviconLetterColorSetTests: XCTestCase {
    func testPalettes_have42ColorsAndDiffer() {
        let nova = NovaFaviconColorSet()
        let standard = StandardFaviconColorSet()

        XCTAssertEqual(nova.backgroundColors.count, 42)
        XCTAssertEqual(standard.backgroundColors.count, 42)
        XCTAssertNotEqual(nova.backgroundColors, standard.backgroundColors)
    }

    func testNovaLetters_useTextOnLightForLightShades_textOnDarkForDarkShades() {
        let palette = NovaFaviconColorSet()

        for (index, letter) in palette.letterColors.enumerated() {
            let expected = (index % 7) < 4 ? NovaColors.VioletDesaturated90 : NovaColors.VioletDesaturated0
            XCTAssertEqual(letter, expected, "letter at index \(index)")
        }
    }

    func testStandardLetters_areAllWhite() {
        XCTAssertTrue(StandardFaviconColorSet().letterColors.allSatisfy { $0 == .white })
    }

    func testPalettes_areWiredToThemes() {
        XCTAssertEqual(LightTheme().colors.faviconLetterColorSet.backgroundColors,
                       StandardFaviconColorSet().backgroundColors)
        XCTAssertEqual(NovaLightTheme().colors.faviconLetterColorSet.backgroundColors,
                       NovaFaviconColorSet().backgroundColors)
    }
}
