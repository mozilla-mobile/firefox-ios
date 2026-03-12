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
        guard let url = Bundle.main.url(forResource: "CustomThemes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(ThemeList.self, from: data)
        else { return [] }
        return decoded.themes
    }

    private struct ThemeList: Decodable {
        let themes: [CustomThemeEntry]
    }
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
