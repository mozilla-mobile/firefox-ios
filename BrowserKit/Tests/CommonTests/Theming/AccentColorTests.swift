// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class AccentColorTests: XCTestCase {
    // MARK: - Persistence

    func testPresetPersistenceRoundTrip() {
        let presets: [(AccentColor, String)] = [
            (.blue, "blue"),
            (.red, "red"),
            (.green, "green"),
            (.purple, "purple"),
            (.orange, "orange")
        ]
        for (accent, expectedString) in presets {
            XCTAssertEqual(
                accent.persistenceValue,
                expectedString,
                "\(accent) should serialize to \"\(expectedString)\""
            )
            XCTAssertEqual(
                AccentColor.from(persistenceValue: expectedString),
                accent,
                "\"\(expectedString)\" should deserialize to \(accent)"
            )
        }
    }

    func testCustomHexPersistenceRoundTrip() {
        let hex = "#FF5733"
        let accent = AccentColor.custom(hex: hex)
        XCTAssertEqual(accent.persistenceValue, hex)
        XCTAssertEqual(AccentColor.from(persistenceValue: hex), accent)
    }

    func testUnknownStringDefaultsToBlue() {
        let result = AccentColor.from(persistenceValue: "banana")
        XCTAssertEqual(result, .blue, "Unknown persistence value should default to .blue")
    }

    // MARK: - Default

    func testDefaultAccentIsBlue() {
        XCTAssertTrue(AccentColor.blue.isDefault, ".blue should be the default accent")
        XCTAssertFalse(AccentColor.red.isDefault, ".red should not be the default accent")
    }

    // MARK: - Presets

    func testPresetsContainsFiveColors() {
        XCTAssertEqual(AccentColor.presets.count, 5, "presets should contain exactly 5 colors")
    }

    // MARK: - Color Resolution

    func testColorResolutionLightMode() {
        let color = AccentColor.red.color(for: .light)
        XCTAssertNotNil(color, ".red should resolve to a non-nil UIColor for .light")
    }

    func testColorResolutionDarkMode() {
        let color = AccentColor.red.color(for: .dark)
        XCTAssertNotNil(color, ".red should resolve to a non-nil UIColor for .dark")
    }

    func testCustomColorDarkModeAdjustment() {
        // A very dark custom color (#000000) should be lightened for dark mode
        let darkAccent = AccentColor.custom(hex: "#000000")
        let originalColor = UIColor(accentHex: "#000000")!
        let adjustedColor = darkAccent.color(for: .dark)

        var origH: CGFloat = 0, origS: CGFloat = 0, origBrightness: CGFloat = 0, origA: CGFloat = 0
        var adjH: CGFloat = 0, adjS: CGFloat = 0, adjBrightness: CGFloat = 0, adjA: CGFloat = 0
        originalColor.getHue(&origH, saturation: &origS, brightness: &origBrightness, alpha: &origA)
        adjustedColor.getHue(&adjH, saturation: &adjS, brightness: &adjBrightness, alpha: &adjA)

        XCTAssertGreaterThan(
            adjBrightness,
            origBrightness,
            "Dark custom color should be lightened for dark mode"
        )
    }

    func testSwatchColorUsesLightVariant() {
        let accent = AccentColor.red
        XCTAssertEqual(
            accent.swatchColor,
            accent.color(for: .light),
            "swatchColor should match color(for: .light)"
        )
    }

    // MARK: - UIColor Hex Helpers

    func testHexInit() {
        XCTAssertNotNil(UIColor(accentHex: "#FF5733"), "Valid hex should produce a UIColor")
        XCTAssertNotNil(UIColor(accentHex: "FF5733"), "Hex without # should also work")
        XCTAssertNil(UIColor(accentHex: "invalid"), "Invalid hex should return nil")
        XCTAssertNil(UIColor(accentHex: "#GGG"), "Non-hex characters should return nil")
    }

    func testHexRoundTrip() {
        let hex = "#FF5733"
        guard let color = UIColor(accentHex: hex) else {
            XCTFail("Should be able to create UIColor from \(hex)")
            return
        }
        let roundTripped = color.accentHexString()
        XCTAssertEqual(
            roundTripped,
            hex,
            "Hex round-trip should produce the same string"
        )
    }
}
