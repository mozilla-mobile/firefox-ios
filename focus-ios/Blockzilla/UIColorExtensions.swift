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

    func lerp(toColor toColor: UIColor, step: CGFloat) -> UIColor {
        var fromR: CGFloat = 0
        var fromG: CGFloat = 0
        var fromB: CGFloat = 0
        getRed(&fromR, green: &fromG, blue: &fromB, alpha: nil)

        var toR: CGFloat = 0
        var toG: CGFloat = 0
        var toB: CGFloat = 0
        toColor.getRed(&toR, green: &toG, blue: &toB, alpha: nil)

        let r = fromR + (toR - fromR) * step
        let g = fromG + (toG - fromG) * step
        let b = fromB + (toB - fromB) * step

        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
