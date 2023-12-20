// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

extension UIColor {
    // These are colors which we shouldn't use anymore - we'll migrate to use the new theming system
    struct LegacyDefaults {
        static let iOSTextHighlightBlue = UIColor(rgb: 0xccdded) // This color should exactly match the ios text highlight
    }
}

public struct UIConstants {
    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 57
    static let TopToolbarHeight: CGFloat = 56
    static let TopToolbarHeightMax: CGFloat = 75
    static var ToolbarHeight: CGFloat = 46
    static let ZoomPageBarHeight: CGFloat = 54

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFont.Weight.regular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFont.Weight.bold)

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 1
    static let ActiveScreenshotQuality: CGFloat = 0.5
}
