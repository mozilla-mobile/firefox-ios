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

private var colors: [Color] = [
    Color(red: 237, green: 230, blue: 4),  // Yellow just to the left of center
    Color(red: 158, green: 209, blue: 16), // Next color clockwise (green)
    Color(red: 80, green: 181, blue: 23),
    Color(red: 23, green: 144, blue: 103),
    Color(red: 71, green: 110, blue: 175),
    Color(red: 159, green: 73, blue: 172),
    Color(red: 204, green: 66, blue: 162),
    Color(red: 255, green: 59, blue: 167),
    Color(red: 255, green: 88, blue: 0),
    Color(red: 255, green: 129, blue: 0),
    Color(red: 254, green: 172, blue: 0),
    Color(red: 255, green: 204, blue: 0),
]

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

    public class func random() -> UIColor {
        let r = Int(arc4random_uniform(12))
        let randomColor = colors[r]
        return UIColor(red: (randomColor.red / 255.0), green:(randomColor.green / 255.0), blue:(randomColor.blue / 255.0), alpha:0.5)
    }

}
