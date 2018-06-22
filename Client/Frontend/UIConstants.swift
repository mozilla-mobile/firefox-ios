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

class TableViewColor {
    var rowBackground: UIColor { return UIColor.Photon.White100 }
    var rowText: UIColor { return UIColor.Photon.Grey90 }
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    var separator: UIColor { return UIColor.Photon.Grey30 }
    var headerBackground: UIColor { return UIConstants.AppBackgroundColor }
    var headerText: UIColor { return UIColor.Photon.Grey50 }
    var rowActionAccessory: UIColor { return UIColor.Photon.Blue50 }

    var errorText: UIColor { return UIColor.Photon.Red50 }
    var warningText: UIColor { return UIColor.Photon.Orange50 }
    var syncText: UIColor { return UIColor.Photon.Grey80 }
}


class URLBarColor {
    var border: UIColor { return UIColor.Photon.Grey50 }
    var activeBorder: UIColor { return UIColor.Photon.Blue50A30 }
    var tint: UIColor { return UIColor.Photon.Blue50A30 }
}

class BrowserColor2 {
    var background: UIColor { return UIColor.Photon.Grey10 }
    var text: UIColor { return .white }
    var urlBarDivider: UIColor { return UIColor.Photon.Grey90A10 }
    var locationBarBackground: UIColor { return UIColor.Photon.Grey30 }
    var tint: UIColor { return UIColor.Photon.Grey80 }
}

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


    struct TextField {
        static let Background = BrowserColor(normal: .white, pbm: Defaults.MobileGreyF)
        static let TextAndTint = BrowserColor(normal: Photon.Grey80, pbm: .white)
        static let Highlight = BrowserColor(normal: Defaults.iOSHighlightBlue, pbm: Defaults.Purple60A30)
        static let ReaderModeButtonSelected = BrowserColor(normal: Photon.Blue40, pbm: Defaults.MobilePrivatePurple)
        static let ReaderModeButtonUnselected = BrowserColor(normal: Photon.Grey50, pbm: Photon.Grey40)
        static let PageOptionsSelected = ReaderModeButtonSelected
        static let PageOptionsUnselected = UIColor.theme.browser.tint
        static let Separator = BrowserColor(normal: Photon.Grey30, pbm: Photon.Grey70)
    }

    // The back/forward/refresh/menu button (bottom toolbar)
    struct ToolbarButton {
        static let SelectedTint = BrowserColor(normal: Photon.Blue40, pbm: Photon.Purple50)
        static let DisabledTint = BrowserColor(normal: Photon.Grey30, pbm: Photon.Grey50)
    }

    struct LoadingBar {
        static let Start = BrowserColor(normal: Photon.Blue50A30, pbm: Photon.Purple50)
        static let End = BrowserColor(normal: Photon.Blue50, pbm: Photon.Magenta50)
    }

    struct TabTray {
        static let Background = UIColor.theme.browser.background
    }

    struct TopTabs {
        static let PrivateModeTint = BrowserColor(normal: Photon.Grey10, pbm: Photon.Grey40)
        static let Background = Photon.Grey80
    }

    struct HomePanel {
        // These values are the same for both private/normal.
        // The homepanel toolbar needed to be able to theme, not anymore.
        // Keep this just in case someone decides they want it to theme again
        static let ToolbarBackground = BrowserColor(normal: Photon.Grey10, pbm: Photon.Grey10)
        static let ToolbarHighlight = BrowserColor(normal: Photon.Blue50, pbm: Photon.Blue50)
        static let ToolbarTint = BrowserColor(normal: Photon.Grey50, pbm: Photon.Grey50)
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
