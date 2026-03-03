// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Represents the user's chosen accent color for theming.
/// Accent colors tint interactive elements (buttons, links, icons)
/// on top of the base Light/Dark theme.
public enum AccentColor: Equatable, Sendable {
    case blue       // Default — matches existing Firefox blue
    case red
    case green
    case purple
    case orange
    case custom(hex: String)  // e.g. "#FF5733"

    // MARK: - Persistence

    /// String value used for UserDefaults persistence.
    public var persistenceValue: String {
        switch self {
        case .blue: return "blue"
        case .red: return "red"
        case .green: return "green"
        case .purple: return "purple"
        case .orange: return "orange"
        case .custom(let hex): return hex
        }
    }

    /// Reconstruct an AccentColor from its persisted string value.
    public static func from(persistenceValue: String) -> AccentColor {
        switch persistenceValue {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        default:
            if persistenceValue.hasPrefix("#") {
                return .custom(hex: persistenceValue)
            }
            return .blue
        }
    }

    // MARK: - Color Resolution

    /// Returns the primary accent UIColor appropriate for the given base theme type.
    /// Light themes use deeper/saturated colors; dark themes use lighter/brighter variants.
    public func color(for baseTheme: ThemeType) -> UIColor {
        switch self {
        case .blue:
            return baseTheme == .light ? FXColors.Blue50 : FXColors.Blue30
        case .red:
            return baseTheme == .light ? FXColors.Red60 : FXColors.Red30
        case .green:
            return baseTheme == .light ? FXColors.Green60 : FXColors.Green30
        case .purple:
            return baseTheme == .light ? FXColors.Violet60 : FXColors.Violet30
        case .orange:
            return baseTheme == .light ? FXColors.Orange60 : FXColors.Orange30
        case .custom(let hex):
            let base = UIColor(accentHex: hex) ?? FXColors.Blue50
            if baseTheme != .light {
                return base.accentAdjustedForDarkMode()
            }
            return base
        }
    }

    /// A display swatch color (always the light-mode variant, used in the picker UI).
    public var swatchColor: UIColor {
        return color(for: .light)
    }

    /// Whether this is the default accent (no tinting needed).
    public var isDefault: Bool {
        return self == .blue
    }

    /// All preset options (excluding custom).
    public static var presets: [AccentColor] {
        return [.blue, .red, .green, .purple, .orange]
    }
}

// MARK: - UIColor Accent Helpers

extension UIColor {
    /// Initialize from a hex string like "#FF5733" or "FF5733".
    public convenience init?(accentHex hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6,
              let rgbValue = UInt64(hexSanitized, radix: 16)
        else { return nil }
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }

    /// Convert this color to a hex string like "#RRGGBB".
    public func accentHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(round(r * 255)),
                      Int(round(g * 255)),
                      Int(round(b * 255)))
    }

    /// Lightens a color for dark mode readability if its brightness is too low.
    public func accentAdjustedForDarkMode() -> UIColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0
        var brightness: CGFloat = 0, alpha: CGFloat = 0
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        if brightness < 0.5 {
            return UIColor(
                hue: hue,
                saturation: max(saturation - 0.1, 0),
                brightness: min(brightness + 0.4, 1.0),
                alpha: alpha
            )
        }
        return self
    }

    /// Returns a darker variant of this color.
    public func accentDarker(by percentage: CGFloat = 0.1) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h,
                       saturation: s,
                       brightness: max(b - percentage, 0),
                       alpha: a)
    }

    /// Returns a lighter variant of this color.
    public func accentLighter(by percentage: CGFloat = 0.1) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h,
                       saturation: s,
                       brightness: min(b + percentage, 1),
                       alpha: a)
    }
}
