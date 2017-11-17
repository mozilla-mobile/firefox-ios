/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// A browser color represents the color of UI in both Private browsing mode and normal mode
struct BrowserColor {
    let normalColor: UIColor
    let PBMColor: UIColor
    init(normal: UIColor, pbm: UIColor) {
        self.normalColor = normal
        self.PBMColor = pbm
    }

    init(normal: Int, pbm: Int) {
        self.normalColor = UIColor(rgb: normal)
        self.PBMColor = UIColor(rgb: pbm)
    }

    func color(isPBM: Bool) -> UIColor {
        return isPBM ? PBMColor : normalColor
    }

    func colorFor(_ theme: Theme) -> UIColor {
        return color(isPBM: theme == .Private)
    }
}

extension UIColor {
    // These are defaults from http://design.firefox.com/photon/visuals/color.html
    struct Defaults {
        static let Grey10 = UIColor(rgb: 0xf9f9fa)
        static let Grey30 = UIColor(rgb: 0xd7d7db)
        static let Grey40 = UIColor(rgb: 0xb1b1b3)
        static let Grey50 = UIColor(rgb: 0x737373)
        static let Grey60 = UIColor(rgb: 0x4a4a4f)
        static let Grey70 = UIColor(rgb: 0x38383d)
        static let Grey80 = UIColor(rgb: 0x272727) // Grey80 is actually #2a2a2e
        static let Grey90 = UIColor(rgb: 0x0c0c0d)
        static let Blue40 = UIColor(rgb: 0x45a1ff)
        static let Blue50 = UIColor(rgb: 0x0a84ff)
        static let Blue60 = UIColor(rgb: 0x0066DC) // Blue60 is actually #0060df
        static let Purple50 = UIColor(rgb: 0x9400ff)
        static let Magenta50 = UIColor(rgb: 0xff1ad9)
        static let Red50 = UIColor(rgb: 0xff0039)
        static let LockGreen = UIColor(rgb: 0x16DA00)

        // Non-Photon design system colors. These are not in the design doc yet.
        static let MobileGreyA = UIColor(rgb: 0xD2D2D4)
        static let MobileGreyC = UIColor(rgb: 0xE4E4E4)
        static let MobileGreyD = UIColor(rgb: 0x414146)
        static let MobileGreyE = UIColor(rgb: 0x2D2D31)
        static let MobileGreyF = UIColor(rgb: 0x636369)
        static let MobileGreyH = UIColor(rgb: 0xADADb0)
        static let MobileGreyI = UIColor(rgb: 0x3f3f43)
        static let MobileGreyJ = UIColor(rgb: 0xE5E5E5)
        static let MobileBlueA = UIColor(rgb: 0xB0D5FB)
        static let MobileBlueB = UIColor(rgb: 0x00dcfc)
        static let MobileBlueC = UIColor(rgb: 0xccdded)
        static let MobileBlueD = UIColor(rgb: 0x00A2FE)
        static let MobilePurple = UIColor(rgb: 0x7878a5)
        static let MobilePurpleB = UIColor(rgb: 0xAC39FF)
        static let MobilePrivatePurple = UIColor(rgb: 0xcf68ff)
    }

    struct Browser {
        static let Background = BrowserColor(normal: Defaults.Grey10, pbm: Defaults.Grey70)
        static let Text = BrowserColor(normal: .white, pbm: Defaults.MobileGreyD)
        static let URLBarDivider = BrowserColor(normal: Defaults.MobileGreyC, pbm: Defaults.MobileGreyD)
        static let LocationBarBackground = Defaults.Grey30
        static let Tint = BrowserColor(normal: Defaults.Grey80, pbm: Defaults.MobileGreyA)
    }

    struct URLBar {
        static let Border = BrowserColor(normal: Defaults.Grey50, pbm: Defaults.MobileGreyE)
        static let ActiveBorder = BrowserColor(normal: Defaults.MobileBlueA, pbm: Defaults.Grey60)
        static let Tint = BrowserColor(normal: Defaults.MobileBlueB, pbm: Defaults.Grey10)
    }

    struct TextField {
        static let Background = BrowserColor(normal: .white, pbm: Defaults.MobileGreyF)
        static let TextAndTint = BrowserColor(normal: Defaults.Grey80, pbm: .white)
        static let Highlight = BrowserColor(normal: Defaults.MobileBlueC, pbm: Defaults.MobilePurple)
        static let ReaderModeButtonSelected = BrowserColor(normal: Defaults.MobileBlueD, pbm: Defaults.MobilePrivatePurple)
        static let ReaderModeButtonUnselected = BrowserColor(normal: Defaults.Grey50, pbm: Defaults.MobileGreyH)
        static let PageOptionsSelected = ReaderModeButtonSelected
        static let PageOptionsUnselected = UIColor.Browser.Tint
        static let Separator = BrowserColor(normal: Defaults.MobileGreyJ, pbm: Defaults.MobileGreyI)
    }

    // The back/forward/refresh/menu button (bottom toolbar)
    struct ToolbarButton {
        static let SelectedTint = BrowserColor(normal: Defaults.MobileBlueD, pbm: Defaults.MobilePurpleB)
        static let DisabledTint = BrowserColor(normal: UIColor.lightGray, pbm: UIColor.gray)
    }

    struct LoadingBar {
        static let Start = BrowserColor(normal: Defaults.MobileBlueB, pbm: Defaults.Purple50)
        static let End = BrowserColor(normal: Defaults.Blue50, pbm: Defaults.Magenta50)
    }

    struct TabTray {
        static let Background = Browser.Background
    }

    struct TopTabs {
        static let PrivateModeTint = BrowserColor(normal: Defaults.Grey10, pbm: Defaults.Grey40)
        static let Background = UIColor.Defaults.Grey80
    }

    struct HomePanel {
        // These values are the same for both private/normal.
        // The homepanel toolbar needed to be able to theme, not anymore.
        // Keep this just in case someone decides they want it to theme again
        static let ToolbarBackground = BrowserColor(normal: Defaults.Grey10, pbm: Defaults.Grey10)
        static let ToolbarHighlight = BrowserColor(normal: Defaults.Blue50, pbm: Defaults.Blue50)
        static let ToolbarTint = BrowserColor(normal: Defaults.Grey50, pbm: Defaults.Grey50)
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

    static let AppBackgroundColor = UIColor.Defaults.Grey10
    static let SystemBlueColor = UIColor.Defaults.Blue50
    static let ControlTintColor = UIColor.Defaults.Blue50
    static let PasscodeDotColor = UIColor.Defaults.Grey60
    static let PrivateModeAssistantToolbarBackgroundColor = UIColor.Defaults.Grey50
    static let PrivateModeTextHighlightColor = UIColor.Defaults.Purple50
    static let PrivateModePurple = UIColor.Defaults.MobilePrivatePurple

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFontWeightRegular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFontWeightBold)

    static let PanelBackgroundColor = UIColor.white
    static let SeparatorColor = UIColor.Defaults.Grey30
    static let HighlightBlue = UIColor.Defaults.Blue50
    static let DestructiveRed = UIColor.Defaults.Red50
    static let BorderColor = UIColor.darkGray
    static let BackgroundColor = AppBackgroundColor

    // Used as backgrounds for favicons
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5
}
