/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

struct UIConstants {
    struct Colors {
        static let Background = UIColor(rgb: 0x221F1F)
        static let ButtonHighlightedColor = UIColor(rgb: 0x333333)
        static let CellSelected = UIColor(rgb: 0x2C6EC8)
        static let DefaultFont = UIColor(rgb: 0xE1E5EA)
        static let FocusLightBlue = UIColor(rgb: 0x00A7E0)
        static let FocusDarkBlue = UIColor(rgb: 0x005DA5)
        static let FocusBlue = UIColor(rgb: 0x00A7E0)
        static let FocusGreen = UIColor(rgb: 0x7ED321)
        static let FocusMaroon = UIColor(rgb: 0xE63D2F)
        static let FocusOrange = UIColor(rgb: 0xF26C23)
        static let FocusRed = UIColor(rgb: 0xE63D2F)
        static let FocusViolet = UIColor(rgb: 0x95368C)
        static let NavigationTitle = UIColor(rgb: 0x61666D)
        static let TableSectionHeader = UIColor(rgb: 0x61666D)
    }

    struct Fonts {
        static let DefaultFont = UIFont.systemFontOfSize(16)
        static let DefaultFontSemibold = UIFont.systemFontOfSize(16, weight: UIFontWeightSemibold)
        static let DefaultFontMedium = UIFont.systemFontOfSize(16, weight: UIFontWeightMedium)
        static let SmallerFont = UIFont.systemFontOfSize(14)
        static let SmallerFontSemibold = UIFont.systemFontOfSize(14, weight: UIFontWeightSemibold)
        static let TableSectionHeader = UIFont.systemFontOfSize(12, weight: UIFontWeightSemibold)
    }

    struct Layout {
        static let NavigationDoneOffset: Float = -10
    }

    struct Strings {
        static let AppDescription = String(format: NSLocalizedString("%@ improves privacy and may boost page load speed and lower your mobile data usage.", comment: "Label displayed above toggles"), AppInfo.ProductName)
        static let NotEnabledError = String(format: NSLocalizedString("%@ is not enabled.", comment: "Error label when the blocker is not enabled, shown in the intro and main app when disabled"), AppInfo.ProductName)
        static let OpenSettings = NSLocalizedString("Open Settings", comment: "Button to open the system Settings, shown in the intro and main app when disabled")
    }
}