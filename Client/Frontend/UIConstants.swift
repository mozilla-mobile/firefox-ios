/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

extension UIColor {
    // These are defaults from http://design.firefox.com/photon/visuals/color.html
    struct Defaults {
        static let MobileGreyF = UIColor(rgb: 0x636369)
        static let iOSHighlightBlue = UIColor(rgb: 0xccdded) // This color should exactly match the ios text highlight
        static let Purple60A30 = UIColor(rgba: 0x8000d74c)
        static let MobilePrivatePurple = UIColor(rgb: 0xcf68ff)
        static let PaleBlue = UIColor(rgb: 0xB0D5FB)
        static let LightBeige = UIColor(rgb: 0xf0e6dc)
    }

    struct Browser {
        static let Background = AppColor(normal: Photon.Grey10, pbm: Photon.Grey70)
        static let Text = AppColor(normal: .white, pbm: Photon.Grey60)
        static let URLBarDivider = AppColor(normal: Photon.Grey90A10, pbm: Photon.Grey60)
        static let LocationBarBackground = Photon.Grey30
        static let Tint = AppColor(normal: Photon.Grey80, pbm: Photon.Grey30)
    }

    struct URLBar {
        static let Border = AppColor(normal: Photon.Grey50, pbm: Photon.Grey80)
        static let ActiveBorder = AppColor(normal: Photon.Blue50A30, pbm: Photon.Grey60)
        static let Tint = AppColor(normal: Photon.Blue50A30, pbm: Photon.Grey10)
    }

    struct TextField {
        static let Background = AppColor(normal: .white, pbm: Defaults.MobileGreyF)
        static let TextAndTint = AppColor(normal: Photon.Grey80, pbm: .white)
        static let Highlight = AppColor(normal: Defaults.iOSHighlightBlue, pbm: Defaults.Purple60A30)
        static let ReaderModeButtonSelected = AppColor(normal: Photon.Blue40, pbm: Defaults.MobilePrivatePurple)
        static let ReaderModeButtonUnselected = AppColor(normal: Photon.Grey50, pbm: Photon.Grey40)
        static let PageOptionsSelected = ReaderModeButtonSelected
        static let PageOptionsUnselected = UIColor.Browser.Tint
        static let Separator = AppColor(normal: Photon.Grey30, pbm: Photon.Grey70)
    }

    // The back/forward/refresh/menu button (bottom toolbar)
    struct ToolbarButton {
        static let SelectedTint = AppColor(normal: Photon.Blue40, pbm: Photon.Purple50)
        static let DisabledTint = AppColor(normal: Photon.Grey30, pbm: Photon.Grey50)
    }

    struct LoadingBar {
        static let Start = AppColor(normal: Photon.Blue50A30, pbm: Photon.Purple50)
        static let End = AppColor(normal: Photon.Blue50, pbm: Photon.Magenta50)
    }

    struct TabTray {
        static let Background = Browser.Background
    }

    struct TopTabs {
        static let PrivateModeTint = AppColor(normal: Photon.Grey10, pbm: Photon.Grey40)
        static let Background = Photon.Grey80
    }

    struct HomePanel {
        // These values are the same for both private/normal.
        // The homepanel toolbar needed to be able to theme, not anymore.
        // Keep this just in case someone decides they want it to theme again
        static let ToolbarBackground = AppColor(normal: Photon.Grey10, pbm: Photon.Grey10)
        static let ToolbarHighlight = AppColor(normal: Photon.Blue50, pbm: Photon.Blue50)
        static let ToolbarTint = AppColor(normal: Photon.Grey50, pbm: Photon.Grey50)
    }
}

public struct UIConstants {
    static let AboutHomePage = URL(string: "\(WebServer.sharedInstance.base)/about/home/")!

    static let DefaultPadding: CGFloat = 10
    static let SnackbarButtonHeight: CGFloat = 48
    static let TopToolbarHeight: CGFloat = 56
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

    static let AppBackgroundColor = UIColor.Photon.Grey10
    static let SystemBlueColor = UIColor.Photon.Blue40
    static let ControlTintColor = UIColor.Photon.Blue50
    static let PasscodeDotColor = UIColor.Photon.Grey60
    static let PrivateModeAssistantToolbarBackgroundColor = UIColor.Photon.Grey50
    static let PrivateModeTextHighlightColor = UIColor.Photon.Purple60
    static let PrivateModePurple = UIColor.Defaults.MobilePrivatePurple

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFont.Weight.regular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFont.Weight.bold)

    static let PanelBackgroundColor = UIColor.white
    static let SeparatorColor = UIColor.Photon.Grey30
    static let HighlightBlue = UIColor.Photon.Blue50
    static let DestructiveRed = UIColor.Photon.Red50
    static let BorderColor = UIColor.Photon.Grey60
    static let BackgroundColor = AppBackgroundColor

    // Used as backgrounds for favicons
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5
}
