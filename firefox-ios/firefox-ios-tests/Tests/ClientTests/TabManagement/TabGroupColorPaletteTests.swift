// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class TabGroupColorPaletteTests: XCTestCase {
    private struct Mapping {
        let id: String
        let color: KeyPath<ThemeColourPalette, UIColor>
        let gradient: KeyPath<ThemeColourPalette, Gradient>
    }

    private var mappings: [Mapping] {
        [
            Mapping(id: "default", color: \.tabGroupNoColor, gradient: \.gradientTabBorderNoColor),
            Mapping(id: "red", color: \.tabGroupRed, gradient: \.gradientTabBorderRed),
            Mapping(id: "orange", color: \.tabGroupOrange, gradient: \.gradientTabBorderOrange),
            Mapping(id: "yellow", color: \.tabGroupYellow, gradient: \.gradientTabBorderYellow),
            Mapping(id: "green", color: \.tabGroupGreen, gradient: \.gradientTabBorderGreen),
            Mapping(id: "cyan", color: \.tabGroupCyan, gradient: \.gradientTabBorderCyan),
            Mapping(id: "blue", color: \.tabGroupBlue, gradient: \.gradientTabBorderBlue),
            Mapping(id: "purple", color: \.tabGroupPurple, gradient: \.gradientTabBorderPurple),
            Mapping(id: "pink", color: \.tabGroupPink, gradient: \.gradientTabBorderPink),
            Mapping(id: "gray", color: \.tabGroupGrey, gradient: \.gradientTabBorderGrey)
        ]
    }

    private var themes: [any Theme] {
        [NovaLightTheme(), NovaDarkTheme(), NovaPrivateTheme(), NovaNightModeTheme()]
    }

    func testOptions_useCurrentSolidAndBorderTokensInEveryNovaTheme() {
        let options = TabGroupColorPalette.options
        XCTAssertEqual(options.map(\.id), mappings.map(\.id))

        for (option, mapping) in zip(options, mappings) {
            for theme in themes {
                assertColor(option.color, matches: mapping, in: theme)
            }
        }
    }

    func testDefault_roundTripPreservesNoColorToken() throws {
        let encoded = try JSONEncoder().encode(TabGroupColorPalette.defaultColor)
        let restored = try JSONDecoder().decode(CodableColor.self, from: encoded)
        let mapping = try XCTUnwrap(mappings.first)

        XCTAssertEqual(restored, TabGroupColorPalette.defaultColor)
        XCTAssertTrue(TabGroupColorPalette.isDefault(restored))
        for theme in themes {
            assertColor(restored, matches: mapping, in: theme)
        }
    }

    func testPresetMatching_requiresBothAppearancesToMatch() throws {
        let custom = try adaptiveColor(light: NovaLightTheme().colors.tabGroupRed,
                                       dark: UIColor(red: 0.12, green: 0.23, blue: 0.34, alpha: 0.45))

        XCTAssertNil(TabGroupColorPalette.optionID(for: custom))
        XCTAssertFalse(TabGroupColorPalette.isDefault(custom))
        assertUnchanged(custom, in: NovaLightTheme())
    }

    func testCustomColor_preservesBothAppearancesAndEncodedValues() throws {
        let stored = try adaptiveColor(light: UIColor(red: 0.17, green: 0.43, blue: 0.71, alpha: 0.65),
                                       dark: UIColor(red: 0.63, green: 0.25, blue: 0.88, alpha: 0.31))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(stored)
        let decoded = try JSONDecoder().decode(CodableColor.self, from: encoded)

        XCTAssertNil(TabGroupColorPalette.optionID(for: decoded))
        for theme in themes {
            assertUnchanged(decoded, in: theme)
        }
        XCTAssertEqual(try encoder.encode(decoded), encoded)
    }

    func testClassicTheme_preservesStoredPresetWithoutResolvingNovaTokens() throws {
        let preset = try XCTUnwrap(TabGroupColorPalette.options.first { $0.id == "red" })

        assertUnchanged(preset.color, in: LightTheme())
        assertUnchanged(preset.color, in: DarkTheme())
    }

    func testCustomColorAndGradient_usePassedThemeRegardlessOfCurrentTraits() throws {
        let stored = try adaptiveColor(light: UIColor(red: 0.17, green: 0.43, blue: 0.71, alpha: 0.65),
                                       dark: UIColor(red: 0.63, green: 0.25, blue: 0.88, alpha: 0.31))
        let renderingThemes: [any Theme] = themes + [LightTheme(), DarkTheme()]

        for style in [UIUserInterfaceStyle.light, .dark] {
            UITraitCollection(userInterfaceStyle: style).performAsCurrent {
                for theme in renderingThemes {
                    let traits = UITraitCollection(userInterfaceStyle: theme.type.getInterfaceStyle())
                    let expected = stored.uiColor.resolvedColor(with: traits).cgColor

                    XCTAssertEqual(TabGroupColorPalette.color(for: stored, theme: theme).cgColor, expected)
                    XCTAssertEqual(TabGroupColorPalette.borderGradient(for: stored, theme: theme).cgColors,
                                   [expected, expected])
                }
            }
        }
    }

    private func adaptiveColor(light: UIColor, dark: UIColor) throws -> CodableColor {
        try XCTUnwrap(CodableColor(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }))
    }

    private func assertColor(_ stored: CodableColor,
                             matches mapping: Mapping,
                             in theme: any Theme,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        let color = TabGroupColorPalette.color(for: stored, theme: theme)
        XCTAssertEqual(CodableColor(uiColor: color),
                       CodableColor(uiColor: theme.colors[keyPath: mapping.color]),
                       mapping.id,
                       file: file,
                       line: line)
        XCTAssertEqual(TabGroupColorPalette.borderGradient(for: stored, theme: theme).colors,
                       theme.colors[keyPath: mapping.gradient].colors,
                       mapping.id,
                       file: file,
                       line: line)
    }

    private func assertUnchanged(_ stored: CodableColor,
                                 in theme: any Theme,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) {
        let traits = UITraitCollection(userInterfaceStyle: theme.type.getInterfaceStyle())
        let expected = CodableColor(uiColor: stored.uiColor.resolvedColor(with: traits))
        XCTAssertEqual(CodableColor(uiColor: TabGroupColorPalette.color(for: stored, theme: theme)),
                       expected,
                       file: file,
                       line: line)
        let gradient = TabGroupColorPalette.borderGradient(for: stored, theme: theme)
        XCTAssertEqual(gradient.colors.map { CodableColor(uiColor: $0) }, [expected, expected], file: file, line: line)
    }
}
