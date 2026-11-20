// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class TabGroupEditorTests: XCTestCase {
    func testSave_withBlankName_doesNotSave() {
        for name in ["", " ", "\n\t "] {
            let subject = createSubject(name: name) { _, _, _ in
                XCTFail("A group requires a nonblank name")
            }

            subject.save()
        }
    }

    func testSave_trimsNameAndPreservesCustomIconAndColor() {
        let icon = TabGroupIcon.sfSymbol("sun.max.fill")
        let color = CodableColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)
        var savedName: String?
        var savedIcon: TabGroupIcon?
        var savedColor: CodableColor?
        let subject = createSubject(name: " \nRoad Trip\t ", icon: icon, color: color) {
            savedName = $0
            savedIcon = $1
            savedColor = $2
        }

        subject.save()

        XCTAssertEqual(savedName, "Road Trip")
        XCTAssertEqual(savedIcon, icon)
        XCTAssertEqual(savedColor, color)
    }

    func testSave_withLegacyPaletteColor_preservesStoredColor() throws {
        let legacy = try XCTUnwrap(CodableColor(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? 0xff8090 : 0xc52d4f)
        }))
        var savedColor: CodableColor?
        let subject = createSubject(name: "Work", color: legacy) { _, _, color in savedColor = color }

        subject.save()

        XCTAssertEqual(savedColor, legacy)
        XCTAssertEqual(TabGroupColorPalette.optionID(for: legacy), "red")
    }

    func testIconOptions_matchApprovedOrderAndHaveAccessibleNames() {
        let options = TabGroupEditorView.iconOptions

        XCTAssertEqual(options.map(\.id), [
            "rectangle.portrait.on.rectangle.portrait.angled.fill", "list.bullet", "flame.fill", "star.fill", "bolt.fill",
            "heart.fill", "sparkles", "lightbulb.fill", "cloud.fill", "face.smiling.fill",
            "pawprint.fill", "house.fill", "briefcase.fill", "graduationcap.fill", "book.closed.fill",
            "airplane", "car.fill", "map.fill", "cart.fill", "wallet.bifold.fill",
            "popcorn.fill", "sportscourt.fill", "dumbbell.fill", "gamecontroller.fill", "headphones",
            "paintpalette.fill", "photo.fill", "camera.macro", "hammer.fill", "person.2.fill",
            "bed.double.fill", "gift.fill", "party.popper.fill", "waveform.path.ecg", "chart.bar.fill"
        ])
        XCTAssertTrue(options.allSatisfy { !$0.localizedName.isEmpty })
        XCTAssertEqual(Set(options.map(\.localizedName)).count, options.count)
        for option in options {
            XCTAssertNotNil(UIImage(systemName: option.id), option.id)
        }
    }

    func testColorOptions_matchApprovedOrderAndLocalizedNames() {
        let options = TabGroupEditorView.colorOptions

        XCTAssertEqual(options.map(\.id), [
            "default", "red", "orange", "yellow", "green", "cyan", "blue", "purple", "pink", "gray"
        ])
        XCTAssertEqual(options.map(\.localizedName), [
            String.TabGroups.ColorNames.Default, String.TabGroups.ColorNames.Red, String.TabGroups.ColorNames.Orange,
            String.TabGroups.ColorNames.Yellow, String.TabGroups.ColorNames.Green, String.TabGroups.ColorNames.Cyan,
            String.TabGroups.ColorNames.Blue, String.TabGroups.ColorNames.Purple, String.TabGroups.ColorNames.Pink,
            String.TabGroups.ColorNames.Gray
        ])
    }

    func testColorOptions_roundTripWithLightAndDarkThemeTokens() throws {
        let tokens: [KeyPath<ThemeColourPalette, UIColor>] = [
            \.tabGroupNoColor, \.tabGroupRed, \.tabGroupOrange, \.tabGroupYellow, \.tabGroupGreen,
            \.tabGroupCyan, \.tabGroupBlue, \.tabGroupPurple, \.tabGroupPink, \.tabGroupGrey
        ]

        for (option, token) in zip(TabGroupEditorView.colorOptions, tokens) {
            let encoded = try JSONEncoder().encode(option.color)
            let restored = try JSONDecoder().decode(CodableColor.self, from: encoded)
            let light = restored.uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let dark = restored.uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

            XCTAssertEqual(CodableColor(uiColor: light), CodableColor(uiColor: NovaLightTheme().colors[keyPath: token]))
            XCTAssertEqual(CodableColor(uiColor: dark), CodableColor(uiColor: NovaDarkTheme().colors[keyPath: token]))
            XCTAssertNotEqual(CodableColor(uiColor: light), CodableColor(uiColor: dark), option.id)
        }
    }

    func testBadgeImage_withAdaptiveColor_preservesBothAppearances() throws {
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .cyan : .red
        }

        let image = TabGroupIcon.sfSymbol("house.fill").badgeImage(color: color)
        let asset = try XCTUnwrap(image.imageAsset)
        let light = asset.image(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = asset.image(with: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertEqual(image.size, CGSize(width: 20, height: 20))
        XCTAssertEqual(image.renderingMode, .alwaysOriginal)
        XCTAssertNotEqual(light.pngData(), dark.pngData())
    }

    func testBadgeImage_withColoredPresets_usesWhiteGlyphInBothAppearances() throws {
        for option in TabGroupColorPalette.options where option.id != "default" {
            let image = TabGroupIcon.sfSymbol("square.fill").badgeImage(color: option.color.uiColor)
            let asset = try XCTUnwrap(image.imageAsset)

            for style in [UIUserInterfaceStyle.light, .dark] {
                try assertBadgeGlyph(asset.image(with: UITraitCollection(userInterfaceStyle: style)), equals: 255)
            }
        }
    }

    func testBadgeImage_withOpaqueColors_choosesContrastingGlyph() throws {
        for (background, expected) in [(UIColor.black, UInt8(255)), (.white, 0), (.blue, 255), (.yellow, 0)] {
            let image = TabGroupIcon.sfSymbol("square.fill").badgeImage(color: background)

            try assertBadgeGlyph(image, equals: expected)
        }
    }

    func testBadgeImage_withDefaultColor_choosesContrastingGlyphInBothAppearances() throws {
        let image = TabGroupIcon.sfSymbol("square.fill").badgeImage(color: TabGroupEditorView.defaultColor.uiColor)
        let asset = try XCTUnwrap(image.imageAsset)

        try assertBadgeGlyph(asset.image(with: UITraitCollection(userInterfaceStyle: .light)), equals: 0)
        try assertBadgeGlyph(asset.image(with: UITraitCollection(userInterfaceStyle: .dark)), equals: 255)
    }

    func testBadgeImage_withTranslucentColor_accountsForBackdrop() throws {
        let color = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.3)
                : UIColor.black.withAlphaComponent(0.3)
        }
        let image = TabGroupIcon.sfSymbol("square.fill").badgeImage(color: color)
        let asset = try XCTUnwrap(image.imageAsset)

        try assertBadgeGlyph(asset.image(with: UITraitCollection(userInterfaceStyle: .light)), equals: 0)
        try assertBadgeGlyph(asset.image(with: UITraitCollection(userInterfaceStyle: .dark)), equals: 255)
    }

    private func assertBadgeGlyph(_ image: UIImage,
                                  equals value: UInt8,
                                  file: StaticString = #filePath,
                                  line: UInt = #line) throws {
        let cgImage = try XCTUnwrap(image.cgImage, file: file, line: line)
        let center = CGRect(x: cgImage.width / 2, y: cgImage.height / 2, width: 1, height: 1)
        let cropped = try XCTUnwrap(cgImage.cropping(to: center), file: file, line: line)
        var pixel = [UInt8](repeating: 0, count: 4)
        try pixel.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress,
                                                  width: 1,
                                                  height: 1,
                                                  bitsPerComponent: 8,
                                                  bytesPerRow: 4,
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                                                    | CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        XCTAssertEqual(Array(pixel.prefix(3)), [value, value, value], file: file, line: line)
        XCTAssertEqual(pixel[3], 255, file: file, line: line)
    }

    private func createSubject(name: String = "",
                               icon: TabGroupIcon = .sfSymbol("rectangle.portrait.on.rectangle.portrait.angled.fill"),
                               color: CodableColor = TabGroupEditorView.defaultColor,
                               onSave: @escaping (String, TabGroupIcon, CodableColor) -> Void = { _, _, _ in },
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabGroupEditorView {
        let themeManager = MockThemeManager(currentTheme: NovaLightTheme())
        trackForMemoryLeaks(themeManager, file: file, line: line)
        return TabGroupEditorView(windowUUID: .XCTestDefaultUUID,
                                  themeManager: themeManager,
                                  name: name,
                                  icon: icon,
                                  color: color,
                                  onCancel: {},
                                  onSave: onSave)
    }
}
