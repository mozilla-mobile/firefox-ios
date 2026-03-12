// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// MARK: - Model

struct CustomThemeColors: Decodable {
    let accent: String
    let background: String
    let toolbar: String

    var accentColor: UIColor { UIColor(hex: accent) ?? .systemBlue }
    var backgroundColor: UIColor { UIColor(hex: background) ?? .systemBackground }
    var toolbarColor: UIColor { UIColor(hex: toolbar) ?? .secondarySystemBackground }
}

struct CustomThemeEntry: Decodable, Identifiable {
    let id: String
    let name: String
    let dark: CustomThemeColors
    let light: CustomThemeColors

    func colors(for style: UIUserInterfaceStyle) -> CustomThemeColors {
        style == .dark ? dark : light
    }
}

// MARK: - Catalog

enum CustomThemeCatalog {
    static var themes: [CustomThemeEntry] {
        // Try loading from bundle first (preferred)
        if let url = Bundle.main.url(forResource: "CustomThemes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(ThemeList.self, from: data),
           !decoded.themes.isEmpty {
            return decoded.themes
        }
        // Fallback: hardcoded themes so the section always renders
        return Self.builtInThemes
    }

    private struct ThemeList: Decodable {
        let themes: [CustomThemeEntry]
    }

    // swiftlint:disable line_length
    private static let builtInThemes: [CustomThemeEntry] = [
        CustomThemeEntry(id: "ocean", name: "Ocean",
                         dark:  CustomThemeColors(accent: "#4FC3F7", background: "#0D1B2A", toolbar: "#1A2F45"),
                         light: CustomThemeColors(accent: "#0288D1", background: "#E3F2FD", toolbar: "#BBDEFB")),
        CustomThemeEntry(id: "forest", name: "Forest",
                         dark:  CustomThemeColors(accent: "#81C784", background: "#1B2A1E", toolbar: "#2A3D2E"),
                         light: CustomThemeColors(accent: "#388E3C", background: "#E8F5E9", toolbar: "#C8E6C9")),
        CustomThemeEntry(id: "sunset", name: "Sunset",
                         dark:  CustomThemeColors(accent: "#FF8A65", background: "#2A1A0D", toolbar: "#3D2A1A"),
                         light: CustomThemeColors(accent: "#E64A19", background: "#FBE9E7", toolbar: "#FFCCBC")),
        CustomThemeEntry(id: "lavender", name: "Lavender",
                         dark:  CustomThemeColors(accent: "#CE93D8", background: "#1E1A2A", toolbar: "#2D2840"),
                         light: CustomThemeColors(accent: "#8E24AA", background: "#F3E5F5", toolbar: "#E1BEE7")),
        CustomThemeEntry(id: "midnight", name: "Midnight",
                         dark:  CustomThemeColors(accent: "#90CAF9", background: "#0A0A14", toolbar: "#14141F"),
                         light: CustomThemeColors(accent: "#1565C0", background: "#E8EAF6", toolbar: "#C5CAE9")),
        CustomThemeEntry(id: "rose", name: "Rose",
                         dark:  CustomThemeColors(accent: "#F48FB1", background: "#2A0D1A", toolbar: "#3D1A2A"),
                         light: CustomThemeColors(accent: "#C2185B", background: "#FCE4EC", toolbar: "#F8BBD9")),
        CustomThemeEntry(id: "slate", name: "Slate",
                         dark:  CustomThemeColors(accent: "#90A4AE", background: "#131A1E", toolbar: "#1F2A30"),
                         light: CustomThemeColors(accent: "#455A64", background: "#ECEFF1", toolbar: "#CFD8DC"))
    ]
    // swiftlint:enable line_length
}

// MARK: - UIColor hex init

private extension UIColor {
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let red   = CGFloat((value & 0xFF0000) >> 16) / 255
        let green = CGFloat((value & 0x00FF00) >>  8) / 255
        let blue  = CGFloat( value & 0x0000FF)        / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
