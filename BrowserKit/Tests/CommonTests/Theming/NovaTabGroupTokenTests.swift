// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Common

final class NovaTabGroupTokenTests: XCTestCase {
    private struct ColorMapping {
        let key: KeyPath<ThemeColourPalette, UIColor>
        let light: UIColor
        let dark: UIColor
    }

    private struct GradientMapping {
        let key: KeyPath<ThemeColourPalette, Gradient>
        let light: [UIColor]
        let dark: [UIColor]
    }

    private let light = NovaLightTheme().colors
    private let dark = NovaDarkTheme().colors
    private let privateMode = NovaPrivateTheme().colors
    private let night = NovaNightModeTheme().colors

    func testPrimaryColorsMatchTheTheme() {
        let colors = [
            ColorMapping(key: \.tabGroupYellow, light: NovaColors.Yellow40, dark: NovaColors.Yellow30),
            ColorMapping(key: \.tabGroupOrange, light: NovaColors.Orange40, dark: NovaColors.Orange30),
            ColorMapping(key: \.tabGroupRed, light: NovaColors.Red40, dark: NovaColors.Red30),
            ColorMapping(key: \.tabGroupPink, light: NovaColors.Pink40, dark: NovaColors.Pink30),
            ColorMapping(key: \.tabGroupPurple, light: NovaColors.Violet40, dark: NovaColors.Violet30),
            ColorMapping(key: \.tabGroupBlue, light: NovaColors.Blue40, dark: NovaColors.Blue30),
            ColorMapping(key: \.tabGroupCyan, light: NovaColors.Cyan40, dark: NovaColors.Cyan30),
            ColorMapping(key: \.tabGroupGreen, light: NovaColors.Green40, dark: NovaColors.Green30),
            ColorMapping(key: \.tabGroupGrey, light: NovaColors.Gray50, dark: NovaColors.Gray40),
            ColorMapping(key: \.tabGroupNoColor, light: NovaColors.Gray5, dark: NovaColors.Gray75)
        ]

        for color in colors {
            XCTAssertEqual(light[keyPath: color.key], color.light, "\(color.key) in Light")
            XCTAssertEqual(dark[keyPath: color.key], color.dark, "\(color.key) in Dark")
            XCTAssertEqual(privateMode[keyPath: color.key], color.dark, "\(color.key) in Private")
            XCTAssertEqual(night[keyPath: color.key], color.dark, "\(color.key) in Night")
        }
    }

    func testTabBorderGradientStopsMatchTheTheme() {
        let shared: [(key: KeyPath<ThemeColourPalette, Gradient>, stops: [UIColor])] = [
            (\.gradientTabBorderYellow, [NovaColors.Yellow40, NovaColors.Yellow50]),
            (\.gradientTabBorderOrange, [NovaColors.Orange40, NovaColors.Orange50]),
            (\.gradientTabBorderRed, [NovaColors.Red40, NovaColors.Red50]),
            (\.gradientTabBorderPink, [NovaColors.Pink40, NovaColors.Pink50]),
            (\.gradientTabBorderPurple, [NovaColors.Violet40, NovaColors.Violet50]),
            (\.gradientTabBorderBlue, [NovaColors.Blue40, NovaColors.Blue50]),
            (\.gradientTabBorderCyan, [NovaColors.Cyan40, NovaColors.Cyan50]),
            (\.gradientTabBorderGreen, [NovaColors.Green40, NovaColors.Green50])
        ]
        let lightNeutralStop = NovaColors.VioletDesaturated90.withAlphaComponent(0.7)
        let darkNeutralStop = NovaColors.VioletDesaturated0.withAlphaComponent(0.7)
        let themeSpecific = [
            GradientMapping(key: \.gradientTabBorderGrey,
                            light: [lightNeutralStop, NovaColors.Gray50],
                            dark: [darkNeutralStop, NovaColors.Gray40]),
            GradientMapping(key: \.gradientTabBorderNoColor,
                            light: [lightNeutralStop, NovaColors.VioletDesaturated90],
                            dark: [darkNeutralStop, NovaColors.VioletDesaturated0])
        ]
        let gradients = shared.map { GradientMapping(key: $0.key, light: $0.stops, dark: $0.stops) } + themeSpecific

        for gradient in gradients {
            XCTAssertEqual(light[keyPath: gradient.key].colors, gradient.light, "\(gradient.key) in Light")
            XCTAssertEqual(dark[keyPath: gradient.key].colors, gradient.dark, "\(gradient.key) in Dark")
            XCTAssertEqual(privateMode[keyPath: gradient.key].colors, gradient.dark, "\(gradient.key) in Private")
            XCTAssertEqual(night[keyPath: gradient.key].colors, gradient.dark, "\(gradient.key) in Night")
        }
    }

    func testAccentGradientStopsMatchTheTheme() {
        let accentStops = [NovaColors.Violet30, NovaColors.Orange30]
        XCTAssertEqual(light.gradientAccent.colors, accentStops)
        XCTAssertEqual(dark.gradientAccent.colors, accentStops)
        XCTAssertEqual(privateMode.gradientAccent.colors, [NovaColors.Violet30, NovaColors.Violet50])
        XCTAssertEqual(night.gradientAccent.colors, accentStops)
    }

    func testGlassTintMatchesTheTheme() {
        XCTAssertEqual(light.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.95))
        XCTAssertEqual(dark.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.85))
        XCTAssertEqual(privateMode.layerTabGroupGlassTint, .clear)
        XCTAssertEqual(night.layerTabGroupGlassTint, NovaColors.White.withAlphaComponent(0.85))
    }
}
