/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Shared

class NSMutableAttributedStringExtensionsTests: XCTestCase {
    private func checkCharacterAtPosition(position: Int, isColored color: UIColor, inString string: NSAttributedString) -> Bool {
        let attributes = string.attributesAtIndex(position, effectiveRange: nil)
        if let foregroundColor = attributes[NSForegroundColorAttributeName] as? UIColor {
            if foregroundColor == color {
                return true
            }
        }
        return false
    }

    func testColorsSubstring() {
        let substring = "bc"
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.redColor())

        XCTAssertFalse(checkCharacterAtPosition(0, isColored: UIColor.redColor(), inString: example))
        for position in 1..<3 {
            XCTAssertTrue(checkCharacterAtPosition(position, isColored: UIColor.redColor(), inString: example))
        }
        XCTAssertFalse(checkCharacterAtPosition(3, isColored: UIColor.redColor(), inString: example))
    }

    func testDoesNothingWithEmptySubstring() {
        let substring = ""
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.redColor())
        for position in 0..<example.string.characters.count {
            XCTAssertFalse(checkCharacterAtPosition(position, isColored: UIColor.redColor(), inString: example))
        }
    }

    func testDoesNothingWhenSubstringNotFound() {
        let substring = "yyz"
        let example = NSMutableAttributedString(string: "abcd")
        example.colorSubstring(substring, withColor: UIColor.redColor())
        for position in 0..<example.string.characters.count {
            XCTAssertFalse(checkCharacterAtPosition(position, isColored: UIColor.redColor(), inString: example))
        }
    }
}