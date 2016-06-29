/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct UIConstants {
    static let AboutHomePage = NSURL(string: "\(WebServer.sharedInstance.base)/about/home/")!

    static let AppBackgroundColor = UIColor.blackColor()
    static let SystemBlueColor = UIColor(red: 0 / 255, green: 122 / 255, blue: 255 / 255, alpha: 1)
    static let PrivateModePurple = UIColor(red: 207 / 255, green: 104 / 255, blue: 255 / 255, alpha: 1)
    static let PrivateModeLocationBackgroundColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 1)
    static let PrivateModeLocationBorderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.15)
    static let PrivateModeActionButtonTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
    static let PrivateModeTextHighlightColor = UIColor(red: 120 / 255, green: 120 / 255, blue: 165 / 255, alpha: 1)
    static let PrivateModeReaderModeBackgroundColor = UIColor(red: 89 / 255, green: 89 / 255, blue: 89 / 255, alpha: 1)
    static let PrivateModeToolbarTintColor = UIColor(red: 74 / 255, green: 74 / 255, blue: 74 / 255, alpha: 1)

    static let ToolbarHeight: CGFloat = 44
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48

    // Static fonts
    static let DefaultChromeSize: CGFloat = 14
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFontOfSize(DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeBoldFont = UIFont.boldSystemFontOfSize(DefaultChromeSize)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFontOfSize(DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFontOfSize(PasscodeEntryFontSize, weight: UIFontWeightBold)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = UIColor.whiteColor()
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red:76/255, green:158/255, blue:255/255, alpha:1)
    static let DestructiveRed = UIColor(red: 255/255, green: 64/255, blue: 0/255, alpha: 1.0)
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)

    // These colours are used on the Menu
    static let MenuToolbarBackgroundColorNormal = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1.0)
    static let MenuToolbarBackgroundColorPrivate = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1.0)
    static let MenuToolbarTintColorNormal = BackgroundColor
    static let MenuToolbarTintColorPrivate = UIColor.whiteColor()
    static let MenuBackgroundColorNormal = UIColor(red: 223/255, green: 223/255, blue: 223/255, alpha: 1.0)
    static let MenuBackgroundColorPrivate = UIColor(red: 59/255, green: 59/255, blue: 59/255, alpha: 1.0)
    static let MenuSelectedItemTintColor = UIColor(red: 0.30, green: 0.62, blue: 1.0, alpha: 1.0)

    // settings
    static let TableViewHeaderBackgroundColor = UIColor(red: 242/255, green: 245/255, blue: 245/255, alpha: 1.0)
    static let TableViewHeaderTextColor = UIColor(red: 130/255, green: 135/255, blue: 153/255, alpha: 1.0)
    static let TableViewRowTextColor = UIColor(red: 53.55/255, green: 53.55/255, blue: 53.55/255, alpha: 1.0)
    static let TableViewDisabledRowTextColor = UIColor.lightGrayColor()
    static let TableViewSeparatorColor = UIColor(rgb: 0xD1D1D4)
    static let TableViewHeaderFooterHeight = CGFloat(44)
    static let TableViewRowErrorTextColor = UIColor(red: 255/255, green: 0/255, blue: 26/255, alpha: 1.0)
    static let TableViewRowWarningTextColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1.0)
    static let TableViewRowActionAccessoryColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)

    // Firefox Orange
    static let ControlTintColor = UIColor(red: 240.0 / 255, green: 105.0 / 255, blue: 31.0 / 255, alpha: 1)

    // Passcode dot gray
    static let PasscodeDotColor = UIColor(rgb: 0x4A4A4A)

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5

    static let OKString = NSLocalizedString("OK", comment: "OK button")
    static let CancelString = NSLocalizedString("Cancel", comment: "Label for Cancel button")
}
