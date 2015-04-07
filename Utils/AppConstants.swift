/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

public struct AppConstants {
    static var StatusBarHeight: CGFloat {
        if UIScreen.mainScreen().traitCollection.verticalSizeClass == .Compact {
            return 0
        }
        return 20
    }

    static let ToolbarHeight: CGFloat = 44
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10

    static let DefaultMediumFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 13)
    static let DefaultSmallFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 11)
    static let DefaultSmallFontBold = UIFont(name: "HelveticaNeue-Bold", size: 11)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)
}
