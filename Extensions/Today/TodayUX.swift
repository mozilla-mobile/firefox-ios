/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct TodayUX {
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)
    static let linkTextSize: CGFloat = 9.0
    static let labelTextSize: CGFloat = 12.0
    static let imageButtonTextSize: CGFloat = 13.0
    static let copyLinkImageWidth: CGFloat = 20.0
    static let margin: CGFloat = 8
    static let buttonsHorizontalMarginPercentage: CGFloat = 0.1
    static let buttonStackViewSpacing: CGFloat = 2.0
    static var labelColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor(named: "widgetLabelColors") ?? UIColor(rgb: 0x242327)
        } else {
            return UIColor(rgb: 0x242327)
        }
    }
    static var subtitleLabelColor: UIColor {
        if #available(iOS 13, *) {
            return UIColor(named: "subtitleLableColor") ?? UIColor(rgb: 0x38383C)
        } else {
            return UIColor(rgb: 0x38383C)
        }
    }
}
