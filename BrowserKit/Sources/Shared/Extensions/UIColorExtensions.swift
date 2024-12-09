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
}
