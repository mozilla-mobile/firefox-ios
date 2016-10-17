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
        static let deleteButtonBackgroundNormal = UIColor(white: 1, alpha: 0.2)
        static let deleteButtonBorder = UIColor(white: 1, alpha: 0.5)
        static let focusLightBlue = UIColor(rgb: 0x00A7E0)
        static let focusDarkBlue = UIColor(rgb: 0x005DA5)
        static let focusBlue = UIColor(rgb: 0x00A7E0)
        static let focusGreen = UIColor(rgb: 0x7ED321)
        static let focusMaroon = UIColor(rgb: 0xE63D2F)
        static let focusOrange = UIColor(rgb: 0xF26C23)
        static let focusRed = UIColor(rgb: 0xE63D2F)
        static let focusViolet = UIColor(rgb: 0x95368C)
        static let gradientBackground = UIColor(rgb: 0x363B40)
        static let gradientLeft = UIColor(rgb: 0xC86DD7, alpha: 0.1)
        static let gradientRight = UIColor(rgb: 0x3023AE, alpha: 0.1)
        static let navigationButton = UIColor(rgb: 0x00A7E0)
        static let navigationTitle = UIColor(rgb: 0x61666D)
        static let progressBar = UIColor(rgb: 0xC86DD7)
        static let tableSectionHeader = UIColor(rgb: 0x61666D)
        static let toggleOn = UIColor(rgb: 0x00A7E0)
        static let toggleOff = UIColor(rgb: 0x585E64)
        static let toolbarBorder = UIColor(rgb: 0x5F6368)
        static let toolbarButtonNormal = UIColor.darkGray
        static let urlTextBackground = UIColor(rgb: 0x636270)
        static let urlTextFont = UIColor.white
        static let urlTextHighlight = UIColor(rgb: 0xC86DD7)
        static let urlTextPlaceholder = UIColor(rgb: 0xffffff, alpha: 0.7)
        static let urlTextShadow = UIColor.black
    }

    struct fonts {
        static let cancelButton = UIFont.systemFont(ofSize: 15)
        static let deleteButton = UIFont.systemFont(ofSize: 11)
        static let safariInstruction = UIFont.systemFont(ofSize: 16, weight: UIFontWeightMedium)
        static let tableSectionHeader = UIFont.systemFont(ofSize: 12, weight: UIFontWeightSemibold)
        static let urlTextFont = UIFont.systemFont(ofSize: 15)
    }

    struct layout {
        static let browserToolbarDisabledOpacity: CGFloat = 0.3
        static let browserToolbarHeight = 44
        static let navigationDoneOffset: Float = -10
        static let urlBarCornerRadius: CGFloat = 2
        static let urlBarMargin: CGFloat = 8
        static let urlBarHeightInset: CGFloat = 10
        static let urlBarShadowOpacity: Float = 0.3
        static let urlBarShadowRadius: CGFloat = 2
        static let urlBarShadowOffset = CGSize(width: 0, height: 2)
        static let urlBarWidthInset: CGFloat = 8
    }

    struct strings {
        static let appDescription = String(format: NSLocalizedString("%@ improves privacy and may boost page load speed and lower your mobile data usage.", comment: "Label displayed above toggles"), AppInfo.ProductName)
        static let deleteButton = NSLocalizedString("URL.deleteButton", value: "DELETE", comment: "Delete button in the URL bar")
        static let notEnabledError = String(format: NSLocalizedString("%@ is not enabled.", comment: "Error label when the blocker is not enabled, shown in the intro and main app when disabled"), AppInfo.ProductName)
        static let openSettings = NSLocalizedString("Open Settings", comment: "Button to open the system Settings, shown in the intro and main app when disabled")
        static let labelBlockAds = NSLocalizedString("Block ad trackers", comment: "Label for toggle on main screen")
        static let labelBlockAnalytics = NSLocalizedString("Block analytics trackers", comment: "Label for toggle on main screen")
        static let labelBlockSocial = NSLocalizedString("Block social trackers", comment: "Label for toggle on main screen")
        static let labelBlockOther = NSLocalizedString("Block other content trackers", comment: "Label for toggle on main screen")
        static let labelBlockFonts = NSLocalizedString("Block Web fonts", comment: "Label for toggle on main screen")
        static let labelOpenSettings = NSLocalizedString("Open Settings", comment: "Button label to open settings screen")
        static let settingsTitle = NSLocalizedString("Settings.title", value: "Settings", comment: "Title for settings screen")
        static let subtitleBlockOther = NSLocalizedString("May break some videos and Web pages", comment: "Label subtitle for toggle on main screen")
        static let toggleSectionIntegration = NSLocalizedString("Settings.sectionIntegration", value: "INTEGRATION", comment: "Label for Safari integration section")
        static let toggleSectionPerformance = NSLocalizedString("PERFORMANCE", comment: "Section label for performance toggles")
        static let toggleSectionPrivacy = NSLocalizedString("PRIVACY", comment: "Section label for privacy toggles")
        static let toggleSafari = NSLocalizedString("Settings.toggleSafari", value: "Safari", comment: "Safari toggle label on settings screen")
        static let urlBarCancel = NSLocalizedString("URL.cancelLabel", value: "Cancel", comment: "Label for cancel button shown when entering a URL or search")
        static let urlTextPlaceholder = NSLocalizedString("URL.placeholderText", value: "Search or enter address", comment: "Placeholder text shown in the URL bar before the user navigates to a page")
    }
}
