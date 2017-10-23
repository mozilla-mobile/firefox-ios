/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// A browser color represents the color of UI in both Private browsing mode and normal mode
struct BrowserColor {
    let normalColor: Int
    let PBMColor: Int
    init(normal: Int, pbm: Int) {
        self.normalColor = normal
        self.PBMColor = pbm
    }
    func color(isPBM: Bool) -> UIColor {
        return UIColor(rgb: isPBM ? PBMColor : normalColor)
    }
}

public struct UIConstants {
    static let AboutHomePage = URL(string: "\(WebServer.sharedInstance.base)/about/home/")!

    // Photon Colors. Remove old colors once we've completly transitioned
    static let BrowserUI = BrowserColor(normal: 0xf9f9fa, pbm: 0x38383D)
    static let TextColor = BrowserColor(normal: 0xffffff, pbm: 0x414146)
    static let URLBarDivider = BrowserColor(normal: 0xE4E4E4, pbm: 0x414146)
    static let TabTrayBG = UIColor(rgb: 0x272727)
    static let locationBarBG = UIColor(rgb: 0xD7D7DB)
    static let LoadingStartColor = BrowserColor(normal: 0x00DCFC, pbm: 0x9400ff)
    static let LoadingEndColor = BrowserColor(normal: 0x0A84FF, pbm: 0xff1ad9)

    //Photon UI sizes
    static let TopToolbarHeight: CGFloat = 56
    // The loading bar starts with one color and then animates to the second one
    static let LoadingBarStart = BrowserColor(normal: 0x00DCFC, pbm: 0x9f00ff)
    static let LoadingBarEnd = BrowserColor(normal: 0x0A84FF, pbm: 0xff1ad9)

    static let TextSelectionBG = UIColor(rgb: 0xE4E4E4)

    static let TopTabsBG = TabTrayBG

    static let AppBackgroundColor = UIColor(rgb: 0xf9f9fa)
    static let SystemBlueColor = UIColor(rgb: 0x0297F8)
    static let PrivateModePurple = UIColor(red: 207 / 255, green: 104 / 255, blue: 255 / 255, alpha: 1)
    static let PrivateModeLocationBackgroundColor = UIColor(red: 31 / 255, green: 31 / 255, blue: 31 / 255, alpha: 1)
    static let PrivateModeLocationBorderColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.15)
    static let PrivateModeActionButtonTintColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
    static let PrivateModeTextHighlightColor = UIColor(red: 207 / 255, green: 104 / 255, blue: 255 / 255, alpha: 1)
    static let PrivateModeInputHighlightColor = UIColor(red: 120 / 255, green: 120 / 255, blue: 165 / 255, alpha: 1)
    static let PrivateModeAssistantToolbarBackgroundColor = UIColor(red: 89 / 255, green: 89 / 255, blue: 89 / 255, alpha: 1)
    static let PrivateModeToolbarTintColor = UIColor(red: 74 / 255, green: 74 / 255, blue: 74 / 255, alpha: 1)

    static var ToolbarHeight: CGFloat = 46
    static var BottomToolbarHeight: CGFloat {
        get {
            var bottomInset: CGFloat = 0.0
            if #available(iOS 11, *) {
                if let window = UIApplication.shared.keyWindow {
                    bottomInset = window.safeAreaInsets.bottom
                }
            }
            return ToolbarHeight + bottomInset
        }
    }
    static let DefaultRowHeight: CGFloat = 58
    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeBoldFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFontWeightHeavy)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFontWeightBold)

    // These highlight colors are currently only used on Snackbar buttons when they're pressed
    static let HighlightColor = UIColor(red: 205/255, green: 223/255, blue: 243/255, alpha: 0.9)
    static let HighlightText = UIColor(red: 42/255, green: 121/255, blue: 213/255, alpha: 1.0)

    static let PanelBackgroundColor = UIColor.white
    static let SeparatorColor = UIColor(rgb: 0xcccccc)
    static let HighlightBlue = UIColor(red: 76/255, green: 158/255, blue: 255/255, alpha: 1)
    static let DestructiveRed = UIColor(red: 255/255, green: 64/255, blue: 0/255, alpha: 1.0)
    static let BorderColor = UIColor.darkGray
    static let BackgroundColor = AppBackgroundColor

    // These colours are used on the Menu
    static let MenuToolbarBackgroundColorNormal = AppBackgroundColor
    static let MenuToolbarBackgroundColorPrivate = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1.0)
    static let MenuToolbarTintColorNormal = BackgroundColor
    static let MenuToolbarTintColorPrivate = UIColor.white
    static let MenuBackgroundColorNormal = UIColor(red: 223/255, green: 223/255, blue: 223/255, alpha: 1.0)
    static let MenuBackgroundColorPrivate = UIColor(red: 59/255, green: 59/255, blue: 59/255, alpha: 1.0)
    static let MenuSelectedItemTintColor = UIColor(red: 0.30, green: 0.62, blue: 1.0, alpha: 1.0)
    static let MenuDisabledItemTintColor = UIColor.lightGray

    // settings
    static let TableViewHeaderBackgroundColor = AppBackgroundColor
    static let TableViewHeaderTextColor = UIColor(rgb: 0x737373)
    static let TableViewRowTextColor = UIColor(rgb: 0x0c0c0d)
    static let TableViewDisabledRowTextColor = UIColor.lightGray
    static let TableViewSeparatorColor = UIColor(rgb: 0xD1D1D4)
    static let TableViewHeaderFooterHeight = CGFloat(44)
    static let TableViewRowErrorTextColor = UIColor(red: 255/255, green: 0/255, blue: 26/255, alpha: 1.0)
    static let TableViewRowWarningTextColor = UIColor(red: 245/255, green: 166/255, blue: 35/255, alpha: 1.0)
    static let TableViewRowActionAccessoryColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)
    static let TableViewRowSyncTextColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
    
    // Firefox Orange
    static let ControlTintColor = SystemBlueColor

    // List of Default colors to use for Favicon backgrounds
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    // Passcode dot gray
    static let PasscodeDotColor = UIColor(rgb: 0x4A4A4A)

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5

    static let OKString = NSLocalizedString("OK", comment: "OK button")
    static let CancelString = NSLocalizedString("Cancel", comment: "Label for Cancel button")
}
