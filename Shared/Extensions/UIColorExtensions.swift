/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private struct Color {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
}

extension UIColor {
    /**
     * Initializes and returns a color object for the given RGB hex integer.
     */
    public convenience init(rgb: Int) {
        self.init(
            red:   CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue:  CGFloat((rgb >> 0) & 0xFF) / 255.0,
            alpha: 1
        )
    }

    public convenience init(rgba: Int) {
        self.init(
            red:   CGFloat((rgba >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgba >> 8) & 0xFF) / 255.0,
            blue:  CGFloat((rgba >> 0) & 0xFF) / 255.0,
            alpha: CGFloat((rgba >> 24) & 0xFF) / 255.0
        )
    }

    public convenience init(colorString: String) {
        var colorInt: UInt32 = 0
        Scanner(string: colorString).scanHexInt32(&colorInt)
        self.init(rgb: (Int) (colorInt))
    }

    public convenience init(colorStringWithAlpha: String) {
        var colorInt: UInt32 = 0
        Scanner(string: colorStringWithAlpha).scanHexInt32(&colorInt)
        self.init(rgb: (Int) (colorInt))
    }
}
