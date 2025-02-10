// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

extension UIColor {
    private struct ColorComponents {
        public var red: CGFloat
        public var green: CGFloat
        public var blue: CGFloat
        public var alpha: CGFloat
    }

    public convenience init(colorString: String) {
        var colorInt: UInt64 = 0
        Scanner(string: colorString).scanHexInt64(&colorInt)
        self.init(rgb: (Int) (colorInt))
    }

    public var hexString: String {
        let colorRef = cgColor.components
        let r = colorRef?[0] ?? 0
        let g = colorRef?[1] ?? 0
        let b = ((colorRef?.count ?? 0) > 2 ? colorRef?[2] : g) ?? 0
        let a = cgColor.alpha

        var color = String(format: "#%02lX%02lX%02lX",
                           lroundf(Float(r * 255)),
                           lroundf(Float(g * 255)),
                           lroundf(Float(b * 255)))
        if a < 1 {
            color += String(format: "%02lX", lroundf(Float(a)))
        }

        return color
    }

    private var components: ColorComponents {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return ColorComponents(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var color: Color {
        return Color(self)
    }

    /// Converts a normalized sRGB component to its linear value as defined by the WCAG 2.2 spec for relative luminance.
    /// See: https://www.w3.org/TR/WCAG22/#dfn-relative-luminance
    ///
    /// For values ≤ 0.04045, the component is divided by 12.92;
    /// otherwise, it is adjusted using an exponent of 2.4.
    func linearizeChannel(_ channel: CGFloat) -> CGFloat {
        return channel <= 0.04045
            ? channel / 12.92
            : pow((channel + 0.055) / 1.055, 2.4)
    }

    /// Computes the relative luminance of the color as defined in WCAG 2.2.
    /// See: https://www.w3.org/TR/WCAG22/#dfn-relative-luminance
    ///
    /// The relative luminance is a measure of the perceived brightness of a color,
    /// normalized to 0 for the darkest black and 1 for the lightest white.
    ///
    /// The color's sRGB components are extracted and linearized with the WCAG formula,
    /// then combined using the coefficients 0.2126 (red), 0.7152 (green), and 0.0722 (blue).
    private var relativeLuminance: CGFloat {
        let linearRed = linearizeChannel(self.components.red)
        let linearGreen = linearizeChannel(self.components.green)
        let linearBlue = linearizeChannel(self.components.blue)

        return 0.2126 * linearRed + 0.7152 * linearGreen + 0.0722 * linearBlue
    }

    public var isDark: Bool {
        return relativeLuminance < 0.5
    }
}
