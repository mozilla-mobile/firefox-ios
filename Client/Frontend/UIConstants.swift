/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public struct UIConstants {
    static let AboutHomeURL = NSURL(string: "\(WebServer.sharedInstance.base)/about/home/#panel=0")!

    static let AppBackgroundColor = UIColor.blackColor()

    static let ToolbarHeight: CGFloat = 44
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10

    static let DeviceFontSize: CGFloat = DeviceInfo.deviceModel().rangeOfString("iPad") != nil ? 18 : 15
    static let DefaultMediumFontSize: CGFloat = 14
    static let DefaultMediumFont = UIFont.systemFontOfSize(DefaultMediumFontSize, weight: UIFontWeightRegular)
    static let DefaultMediumBoldFont = UIFont.boldSystemFontOfSize(DefaultMediumFontSize)
    static let DefaultSmallFontSize: CGFloat = 11
    static let DefaultSmallFont = UIFont.systemFontOfSize(DefaultSmallFontSize, weight: UIFontWeightRegular)
    static let DefaultSmallFontBold = UIFont.systemFontOfSize(DefaultSmallFontSize, weight: UIFontWeightBold)
    static let DefaultStandardFontSize: CGFloat = 17
    static let DefaultStandardFontBold = UIFont.boldSystemFontOfSize(DefaultStandardFontSize)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = DeviceInfo.isBlurSupported() ? UIColor.whiteColor().colorWithAlphaComponent(0.6) : UIColor.whiteColor()
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red:0.3, green:0.62, blue:1, alpha:1)
    static let DestructiveRed = UIColor(red: 255/255, green: 64/255, blue: 0/255, alpha: 1.0)
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.25)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)

    // settings
    static let TableViewHeaderBackgroundColor = UIColor(red: 242/255, green: 245/255, blue: 245/255, alpha: 1.0)
    static let TableViewHeaderTextColor = UIColor(red: 130/255, green: 135/255, blue: 153/255, alpha: 1.0)
    static let TableViewRowTextColor = UIColor(red: 53.55/255, green: 53.55/255, blue: 53.55/255, alpha: 1.0)
    static let TableViewSeparatorColor = UIColor(rgb: 0xD1D1D4)

    // Firefox Orange
    static let ControlTintColor = UIColor(red: 240.0 / 255, green: 105.0 / 255, blue: 31.0 / 255, alpha: 1)
}