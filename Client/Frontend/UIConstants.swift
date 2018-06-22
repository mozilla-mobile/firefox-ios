/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

// Convenience reference to these normal mode colors which are used in a few color classes.
fileprivate let defaultBackground = UIColor.Photon.Grey10
fileprivate let defaultSeparator = UIColor.Photon.Grey30
    
class TableViewColor {
    var rowBackground: UIColor { return UIColor.Photon.White100 }
    var rowText: UIColor { return UIColor.Photon.Grey90 }
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    var separator: UIColor { return defaultSeparator }
    var headerBackground: UIColor { return defaultBackground }
    var headerText: UIColor { return UIColor.Photon.Grey50 }
    var rowActionAccessory: UIColor { return UIColor.Photon.Blue50 }
    var controlTint: UIColor { return rowActionAccessory }
    var syncText: UIColor { return UIColor.Photon.Grey80 }
    var errorText: UIColor { return UIColor.Photon.Red50 }
    var warningText: UIColor { return UIColor.Photon.Orange50 }
}

class URLBarColor {
    var border: UIColor { return UIColor.Photon.Grey50 }
    var activeBorder: UIColor { return UIColor.Photon.Blue50A30 }
    var tint: UIColor { return UIColor.Photon.Blue50A30 }
}

class BrowserColor {
    var background: UIColor { return defaultBackground }
    var text: UIColor { return .white }
    var urlBarDivider: UIColor { return UIColor.Photon.Grey90A10 }
    var locationBarBackground: UIColor { return UIColor.Photon.Grey30 }
    var tint: UIColor { return UIColor.Photon.Grey80 }
}

// The back/forward/refresh/menu button (bottom toolbar)
class ToolbarButtonColor {
    var selectedTint: UIColor { return UIColor.Photon.Blue40 }
    var disabledTint: UIColor { return UIColor.Photon.Grey30 }
}

class LoadingBarColor {
    var start: UIColor { return UIColor.Photon.Blue50A30 }
    var end: UIColor { return UIColor.Photon.Blue50 }
}

class TabTrayColor {
    var background: UIColor { return defaultBackground }
    var privateModeLearnMore: UIColor { return UIColor.Photon.Purple60 }
    var privateModePurple: UIColor { return UIColor.Defaults.MobilePrivatePurple }
}

class TopTabsColor {
    var privateModeTint: UIColor { return UIColor.Photon.Grey10 } // remove me
    var background: UIColor { return UIColor.Photon.Grey80 }
    var selectedLine: UIColor { return UIColor.Photon.Blue60 }
}

class TextFieldColor {
    var background: UIColor { return .white }
    var textAndTint: UIColor { return UIColor.Photon.Grey80 }
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue }
    var readerModeButtonSelected: UIColor { return UIColor.Photon.Blue40 }
    var readerModeButtonUnselected: UIColor { return UIColor.Photon.Grey50 }
    var pageOptionsSelected: UIColor { return readerModeButtonSelected }
    var pageOptionsUnselected: UIColor { return UIColor.theme.browser.tint }
    var separator: UIColor { return defaultSeparator }
}

class SearchInputColor {
    var title: UIColor { return UIColor.Photon.Grey40 }
    var input: UIColor { return UIColor.Photon.Blue50 }
    var border: UIColor { return defaultSeparator }
}

class HomePanelColor {
    var toolbarBackground: UIColor { return defaultBackground }
    var toolbarHighlight: UIColor { return UIColor.Photon.Blue50 }
    var toolbarTint: UIColor { return UIColor.Photon.Grey50 }

    var panelBackground: UIColor { return UIColor.white }
    var appBackground: UIColor { return defaultBackground }
    var separator: UIColor { return defaultSeparator }
    var border: UIColor { return UIColor.Photon.Grey60 }
    var buttonContainerBorder: UIColor { return separator }
    var backgroundColorPrivateMode: UIColor { return UIColor.Photon.Grey50 }
}

class SnackBarColor {
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue.withAlphaComponent(0.9) }
    var highlightText: UIColor { return UIColor.Photon.Blue60 }
    var border: UIColor { return UIColor.Photon.Grey60 }
}

class GeneralColor {
    var passcodeDot: UIColor { return UIColor.Photon.Grey60 }
    var highlightBlue: UIColor { return UIColor.Photon.Blue50 }
    var destructiveRed: UIColor { return UIColor.Photon.Red50 }
    var separator: UIColor { return defaultSeparator }
}

extension UIColor {
    // These are defaults from http://design.firefox.com/photon/visuals/color.html
    struct Defaults {
        static let MobileGreyF = UIColor(rgb: 0x636369)
        static let iOSTextHighlightBlue = UIColor(rgb: 0xccdded) // This color should exactly match the ios text highlight
        static let Purple60A30 = UIColor(rgba: 0x8000d74c)
        static let MobilePrivatePurple = UIColor(rgb: 0xcf68ff)
        static let PaleBlue = UIColor(rgb: 0xB0D5FB)
        static let LightBeige = UIColor(rgb: 0xf0e6dc)
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

    static let SystemBlueColor = UIColor.Photon.Blue40

    // Static fonts
    static let DefaultChromeSize: CGFloat = 16
    static let DefaultChromeSmallSize: CGFloat = 11
    static let PasscodeEntryFontSize: CGFloat = 36
    static let DefaultChromeFont: UIFont = UIFont.systemFont(ofSize: DefaultChromeSize, weight: UIFont.Weight.regular)
    static let DefaultChromeSmallFontBold = UIFont.boldSystemFont(ofSize: DefaultChromeSmallSize)
    static let PasscodeEntryFont = UIFont.systemFont(ofSize: PasscodeEntryFontSize, weight: UIFont.Weight.bold)

    // Used as backgrounds for favicons
    static let DefaultColorStrings = ["2e761a", "399320", "40a624", "57bd35", "70cf5b", "90e07f", "b1eea5", "881606", "aa1b08", "c21f09", "d92215", "ee4b36", "f67964", "ffa792", "025295", "0568ba", "0675d3", "0996f8", "2ea3ff", "61b4ff", "95cdff", "00736f", "01908b", "01a39d", "01bdad", "27d9d2", "58e7e6", "89f4f5", "c84510", "e35b0f", "f77100", "ff9216", "ffad2e", "ffc446", "ffdf81", "911a2e", "b7223b", "cf2743", "ea385e", "fa526e", "ff7a8d", "ffa7b3" ]

    /// JPEG compression quality for persisted screenshots. Must be between 0-1.
    static let ScreenshotQuality: Float = 0.3
    static let ActiveScreenshotQuality: CGFloat = 0.5
}
