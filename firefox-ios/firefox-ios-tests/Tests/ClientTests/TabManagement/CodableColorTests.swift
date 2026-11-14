// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Client

@MainActor
final class CodableColorTests: XCTestCase {
    func testInit_withRGBComponents_defaultsToOpaqueInBothAppearances() {
        let stored = CodableColor(red: 0.13, green: 0.57, blue: 0.82)

        for style in [UIUserInterfaceStyle.light, .dark] {
            let resolved = stored.uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            assertComponents(resolved, red: 0.13, green: 0.57, blue: 0.82, alpha: 1)
        }
    }

    func testEncodeDecode_withRGBAColor_preservesComponents() throws {
        let original = UIColor(red: 0.13, green: 0.57, blue: 0.82, alpha: 0.42)
        let stored = try XCTUnwrap(CodableColor(uiColor: original))
        let data = try JSONEncoder().encode(stored)
        let decoded = try JSONDecoder().decode(CodableColor.self, from: data)

        XCTAssertEqual(decoded, stored)
        for style in [UIUserInterfaceStyle.light, .dark] {
            let resolved = decoded.uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            assertComponents(resolved, red: 0.13, green: 0.57, blue: 0.82, alpha: 0.42)
        }
    }

    func testInit_withGrayscaleColor_preservesWhiteAndAlpha() throws {
        let stored = try XCTUnwrap(CodableColor(uiColor: UIColor(white: 1, alpha: 0.35)))

        assertComponents(stored.uiColor, red: 1, green: 1, blue: 1, alpha: 0.35)
    }

    func testInit_withDisplayP3Color_convertsToSRGB() throws {
        let original = CGColor(srgbRed: 0.25, green: 0.5, blue: 0.75, alpha: 0.65)
        let displayP3 = try XCTUnwrap(CGColorSpace(name: CGColorSpace.displayP3))
        let converted = try XCTUnwrap(original.converted(to: displayP3, intent: .defaultIntent, options: nil))
        let stored = try XCTUnwrap(CodableColor(uiColor: UIColor(cgColor: converted)))

        assertComponents(stored.uiColor, red: 0.25, green: 0.5, blue: 0.75, alpha: 0.65)
    }

    func testEncodeDecode_withAdaptiveColor_preservesBothAppearances() throws {
        let original = UIColor { traits in
            traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 0.5)
            : UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.7)
        }
        let stored = try XCTUnwrap(CodableColor(uiColor: original))
        let data = try JSONEncoder().encode(stored)
        let decoded = try JSONDecoder().decode(CodableColor.self, from: data)
        let restored = decoded.uiColor
        let light = restored.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = restored.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertEqual(decoded, stored)
        assertComponents(light, red: 0.2, green: 0.4, blue: 0.6, alpha: 0.7)
        assertComponents(dark, red: 0.8, green: 0.6, blue: 0.4, alpha: 0.5)
    }

    func testDecode_withVersionOneFixture_preservesBothAppearances() throws {
        let data = Data("""
        {
            "light": {"red": 0.2, "green": 0.4, "blue": 0.6, "alpha": 0.7},
            "dark": {"red": 0.8, "green": 0.6, "blue": 0.4, "alpha": 0.5}
        }
        """.utf8)

        let result = try JSONDecoder().decode(CodableColor.self, from: data).uiColor
        let light = result.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = result.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        assertComponents(light, red: 0.2, green: 0.4, blue: 0.6, alpha: 0.7)
        assertComponents(dark, red: 0.8, green: 0.6, blue: 0.4, alpha: 0.5)
    }

    func testInit_withPatternColor_returnsNil() {
        XCTAssertNil(CodableColor(uiColor: createPatternColor()))
    }

    func testInit_withUnsupportedDarkAppearance_returnsNil() {
        let pattern = createPatternColor()
        let adaptive = UIColor { traits in
            traits.userInterfaceStyle == .dark ? pattern : .red
        }

        XCTAssertNil(CodableColor(uiColor: adaptive))
    }

    private func createPatternColor() -> UIColor {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            context.cgContext.setFillColor(UIColor.red.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return UIColor(patternImage: image)
    }

    private func assertComponents(_ color: UIColor,
                                  red: Double,
                                  green: Double,
                                  blue: Double,
                                  alpha: Double,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) {
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        XCTAssertTrue(color.getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha),
                      file: file,
                      line: line)
        XCTAssertEqual(Double(actualRed), red, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(Double(actualGreen), green, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(Double(actualBlue), blue, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(Double(actualAlpha), alpha, accuracy: 0.0001, file: file, line: line)
    }
}
