// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Common

class NovaTabGroupTokenTests: XCTestCase {
    private struct ColorMapping {
        let key: KeyPath<ThemeColourPalette, UIColor>
        let light: UIColor
        let dark: UIColor
    }

    private let light = NovaLightTheme().colors
    private let dark = NovaDarkTheme().colors
    private let privateMode = NovaPrivateTheme().colors
    private let night = NovaNightModeTheme().colors

    func testPrimaryColorsMatchTheTheme() {
        let colors = [
            ColorMapping(key: \.tabGroupYellow, light: NovaColors.Yellow50, dark: NovaColors.Yellow30),
            ColorMapping(key: \.tabGroupOrange, light: NovaColors.Orange50, dark: NovaColors.Orange30),
            ColorMapping(key: \.tabGroupRed, light: NovaColors.Red50, dark: NovaColors.Red30),
            ColorMapping(key: \.tabGroupPink, light: NovaColors.Pink50, dark: NovaColors.Pink30),
            ColorMapping(key: \.tabGroupPurple, light: NovaColors.Violet50, dark: NovaColors.Violet30),
            ColorMapping(key: \.tabGroupBlue, light: NovaColors.Blue50, dark: NovaColors.Blue30),
            ColorMapping(key: \.tabGroupCyan, light: NovaColors.Cyan50, dark: NovaColors.Cyan30),
            ColorMapping(key: \.tabGroupGreen, light: NovaColors.Green50, dark: NovaColors.Green30),
            ColorMapping(key: \.tabGroupGrey, light: NovaColors.Gray50, dark: NovaColors.Gray40)
        ]

        for color in colors {
            XCTAssertEqual(light[keyPath: color.key], color.light, "\(color.key) in Light")
            XCTAssertEqual(dark[keyPath: color.key], color.dark, "\(color.key) in Dark")
            XCTAssertEqual(privateMode[keyPath: color.key], color.dark, "\(color.key) in Private")
            XCTAssertEqual(night[keyPath: color.key], color.dark, "\(color.key) in Night")
        }
    }

    func testTabBorderGradientsUseTheSameStopsInEachTheme() {
        let gradients: [(key: KeyPath<ThemeColourPalette, Gradient>, stops: [UIColor])] = [
            (\.gradientTabBorderYellow, [NovaColors.Yellow30, NovaColors.Yellow70]),
            (\.gradientTabBorderOrange, [NovaColors.Orange30, NovaColors.Orange70]),
            (\.gradientTabBorderRed, [NovaColors.Red30, NovaColors.Red70]),
            (\.gradientTabBorderPink, [NovaColors.Pink30, NovaColors.Pink70]),
            (\.gradientTabBorderPurple, [NovaColors.Violet30, NovaColors.Violet70]),
            (\.gradientTabBorderBlue, [NovaColors.Blue30, NovaColors.Blue70]),
            (\.gradientTabBorderCyan, [NovaColors.Cyan30, NovaColors.Cyan70]),
            (\.gradientTabBorderGreen, [NovaColors.Green30, NovaColors.Green70]),
            (\.gradientTabBorderGrey, [NovaColors.Gray40, NovaColors.Gray60])
        ]

        for gradient in gradients {
            XCTAssertEqual(light[keyPath: gradient.key].colors, gradient.stops, "\(gradient.key) in Light")
            XCTAssertEqual(dark[keyPath: gradient.key].colors, gradient.stops, "\(gradient.key) in Dark")
            XCTAssertEqual(privateMode[keyPath: gradient.key].colors, gradient.stops, "\(gradient.key) in Private")
            XCTAssertEqual(night[keyPath: gradient.key].colors, gradient.stops, "\(gradient.key) in Night")
        }
    }

    func testGlassTintMatchesTheTheme() {
        XCTAssertEqual(light.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.95))
        XCTAssertEqual(dark.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.85))
        XCTAssertEqual(privateMode.layerTabGroupGlassTint, .clear)
        XCTAssertEqual(night.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.85))
    }
}
