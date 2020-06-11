/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct TodayUX {
    static let privateBrowsingColor = UIColor(rgb: 0xcf68ff)
    static let backgroundHightlightColor = UIColor(white: 216.0/255.0, alpha: 44.0/255.0)
    static let linkTextSize: CGFloat = 10.0
    static let labelTextSize: CGFloat = 14.0
    static let imageButtonTextSize: CGFloat = 14.0
    static let copyLinkImageWidth: CGFloat = 23
    static let margin: CGFloat = 8
    static let buttonsHorizontalMarginPercentage: CGFloat = 0.1
    static let privateSearchButtonColorBrightPurple = UIColor(red: 117.0/255.0, green: 41.0/255.0, blue: 167.0/255.0, alpha: 1.0)
    static let privateSearchButtonColorDarkPurple = UIColor(red: 73.0/255.0, green: 46.0/255.0, blue: 133.0/255.0, alpha: 1.0)
    static let privateSearchButtonColorFaintDarkPurple = UIColor(red: 56.0/255.0, green: 51.0/255.0, blue: 114.0/255.0, alpha: 1.0)
}

struct TodayStrings {
    static let NewPrivateTabButtonLabel = NSLocalizedString("TodayWidget.NewPrivateTabButtonLabel", tableName: "Today", value: "Private Search", comment: "New Private Tab button label")
    static let NewTabButtonLabel = NSLocalizedString("TodayWidget.NewTabButtonLabel", tableName: "Today", value: "New Search", comment: "New Tab button label")
    static let GoToCopiedLinkLabel = NSLocalizedString("TodayWidget.GoToCopiedLinkLabel", tableName: "Today", value: "Go to copied link", comment: "Go to link on clipboard")
}
