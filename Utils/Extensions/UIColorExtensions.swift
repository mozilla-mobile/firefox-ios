/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private struct Color {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
};

extension UIColor {
    /**
     * Initializes and returns a color object for the given RGB hex integer.
     */
    public convenience init(rgb: Int) {
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8)  / 255.0,
            blue:  CGFloat((rgb & 0x0000FF) >> 0)  / 255.0,
            alpha: 1)
    }

    public func toInt() -> UInt32 {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let r = (UInt32(red) << 24)
        let g = (UInt32(green) << 16)
        let b = (UInt32(blue) << 8)
        let a = (UInt32(alpha) << 0)
        return UInt32(r + g + b + a)
    }

    public func getHue(inout hue: CGFloat, inout saturation: CGFloat, inout lightness: CGFloat, inout alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let maximum = max(r, max(g, b))
        let minimum = min(r, min(g, b))
        let deltaMaxMin = maximum - minimum

        hue = 0.0
        saturation = 0.0
        lightness = (maximum + minimum) / 2.0

        if (maximum == minimum) {
            // Monochromatic
            hue = 0.0
            saturation = 0.0
        } else {
            if (maximum == r) {
                hue = ((g - b) / deltaMaxMin) % 6.0
            } else if (maximum == g) {
                hue = ((b - r) / deltaMaxMin) + 2.0
            } else {
                hue = ((r - g) / deltaMaxMin) + 4.0
            }
            saturation =  deltaMaxMin / (1.0 - abs(2.0 * lightness - 1.0))
        }

        hue = hue * 60 % 360
    }

}
