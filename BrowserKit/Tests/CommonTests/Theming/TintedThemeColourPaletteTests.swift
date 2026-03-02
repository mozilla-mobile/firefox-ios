// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class TintedThemeColourPaletteTests: XCTestCase {
    private var basePalette: ThemeColourPalette!

    override func setUp() {
        super.setUp()
        basePalette = LightTheme().colors
    }

    override func tearDown() {
        basePalette = nil
        super.tearDown()
    }

    // MARK: - Accent Overrides

    func testTintedPaletteOverridesActionPrimary() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertNotEqual(tinted.actionPrimary, basePalette.actionPrimary,
                          "actionPrimary should be overridden by the red accent")
        XCTAssertEqual(tinted.actionPrimary, accent,
                       "actionPrimary should equal the red accent color")
    }

    func testTintedPaletteOverridesTextAccent() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertNotEqual(tinted.textAccent, basePalette.textAccent,
                          "textAccent should be overridden by the red accent")
        XCTAssertEqual(tinted.textAccent, accent,
                       "textAccent should equal the red accent color")
    }

    func testTintedPaletteOverridesIconAccent() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertNotEqual(tinted.iconAccent, basePalette.iconAccent,
                          "iconAccent should be overridden by the red accent")
        XCTAssertEqual(tinted.iconAccent, accent,
                       "iconAccent should equal the red accent color")
    }

    // MARK: - Delegation

    func testTintedPaletteDelegatesLayer1() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertEqual(tinted.layer1, basePalette.layer1,
                       "layer1 should be delegated from the base palette")
    }

    func testTintedPaletteDelegatesTextPrimary() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertEqual(tinted.textPrimary, basePalette.textPrimary,
                       "textPrimary should be delegated from the base palette")
    }

    func testTintedPaletteDelegatesShadowDefault() {
        let accent = AccentColor.red.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertEqual(tinted.shadowDefault, basePalette.shadowDefault,
                       "shadowDefault should be delegated from the base palette")
    }

    // MARK: - Blue Accent (Default)

    func testBlueAccentMatchesBase() {
        // Blue is the default Firefox accent, so tinting with blue should produce the
        // same actionPrimary as the base LightTheme palette.
        let accent = AccentColor.blue.color(for: .light)
        let tinted = TintedThemeColourPalette(base: basePalette, accent: accent, themeType: .light)

        XCTAssertEqual(tinted.actionPrimary, basePalette.actionPrimary,
                       "Blue accent actionPrimary should match LightTheme's default actionPrimary")
    }
}
