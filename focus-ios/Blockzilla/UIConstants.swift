/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

struct UIConstants {
    struct colors {
        static let background = UIColor(rgb: 0x221F1F)
        static let buttonHighlight = UIColor(rgb: 0x333333)
        static let cellSelected = UIColor(rgb: 0x2C6EC8)
        static let defaultFont = UIColor(rgb: 0xE1E5EA)
        static let focusLightBlue = UIColor(rgb: 0x00A7E0)
        static let focusDarkBlue = UIColor(rgb: 0x005DA5)
        static let focusBlue = UIColor(rgb: 0x00A7E0)
        static let focusGreen = UIColor(rgb: 0x7ED321)
        static let focusMaroon = UIColor(rgb: 0xE63D2F)
        static let focusOrange = UIColor(rgb: 0xF26C23)
        static let focusRed = UIColor(rgb: 0xE63D2F)
        static let focusViolet = UIColor(rgb: 0x95368C)
        static let navigationButton = UIColor(rgb: 0x00A7E0)
        static let navigationTitle = UIColor(rgb: 0x61666D)
        static let progressBar = UIColor(rgb: 0xff9500)
        static let tableSectionHeader = UIColor(rgb: 0x61666D)
        static let toolbarButtonNormal = UIColor.darkGray
        static let toolbarBackground = UIColor(rgb: 0xEEEEEE)
        static let urlBarBackgroundLeft = UIColor(rgb: 0x9c62a7)
        static let urlBarBackgroundRight = UIColor(rgb: 0x2f2a8d)
        static let urlTextBackground = UIColor(rgb: 0xffffff, alpha: 0.44)
        static let urlTextFont = UIColor.white
        static let urlTextHighlight = UIColor(rgb: 0xf27c33)
        static let urlTextPlaceholder = UIColor(rgb: 0xffffff, alpha: 0.8)
    }

    struct fonts {
        static let defaultFont = UIFont.systemFont(ofSize: 16)
        static let defaultFontSemibold = UIFont.systemFont(ofSize: 16, weight: UIFontWeightSemibold)
        static let defaultFontMedium = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        static let smallerFont = UIFont.systemFont(ofSize: 14)
        static let smallerFontSemibold = UIFont.systemFont(ofSize: 14, weight: UIFontWeightSemibold)
        static let tableSectionHeader = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
        static let urlTextFont = UIFont.systemFont(ofSize: 14)
    }

    struct layout {
        static let browserToolbarHeight = 44
        static let navigationDoneOffset: Float = -10
        static let urlTextCornerRadius: CGFloat = 1.5
        static let urlBarMargin: CGFloat = 8
        static let urlBarHeightInset: CGFloat = 12
        static let urlBarWidthInset: CGFloat = 8
    }

    struct strings {
        static let appDescription = String(format: NSLocalizedString("%@ improves privacy and may boost page load speed and lower your mobile data usage.", comment: "Label displayed above toggles"), AppInfo.ProductName)
        static let notEnabledError = String(format: NSLocalizedString("%@ is not enabled.", comment: "Error label when the blocker is not enabled, shown in the intro and main app when disabled"), AppInfo.ProductName)
        static let openSettings = NSLocalizedString("Open Settings", comment: "Button to open the system Settings, shown in the intro and main app when disabled")
        static let labelBlockAds = NSLocalizedString("Block ad trackers", comment: "Label for toggle on main screen")
        static let labelBlockAnalytics = NSLocalizedString("Block analytics trackers", comment: "Label for toggle on main screen")
        static let labelBlockSocial = NSLocalizedString("Block social trackers", comment: "Label for toggle on main screen")
        static let labelBlockOther = NSLocalizedString("Block other content trackers", comment: "Label for toggle on main screen")
        static let labelBlockFonts = NSLocalizedString("Block Web fonts", comment: "Label for toggle on main screen")
        static let labelOpenSettings = NSLocalizedString("Open Settings", comment: "Button label to open settings screen")
        static let settingsTitle = NSLocalizedString("Settings.title", value: "Settings", comment: "Title for settings screen")
        static let subtitleBlockOther = NSLocalizedString("May break some videos and Web pages", comment: "Label for toggle on main screen")
        static let urlBarCancel = NSLocalizedString("URL.cancelLabel", value: "Cancel", comment: "Label for cancel button shown when entering a URL or search")
        static let urlTextPlaceholder = NSLocalizedString("URL.placeholderText", value: "Search or enter address", comment: "Placeholder text shown in the URL bar before the user navigates to a page")
    }
}
