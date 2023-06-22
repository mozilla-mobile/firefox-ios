// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

protocol LegacyNotificationThemeable: AnyObject {
    func applyTheme()
}

protocol PrivateModeUI {
    func applyUIMode(isPrivate: Bool, theme: Theme)
}

extension UIColor {
    static var legacyTheme: LegacyTheme {
        return LegacyThemeManager.instance.current
    }
}

enum BuiltinThemeName: String {
    case normal
    case dark
}

class TableViewColor {
    var rowBackground: UIColor { return UIColor.Photon.White100 } // layer5
    var selectedBackground: UIColor { return UIColor.Custom.selectedHighlightLight } // layer5Hover
    var rowText: UIColor { return UIColor.Photon.Grey90 } // textPrimary
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
    var headerBackground: UIColor { return UIColor.Photon.Grey10 } // layer1
}

class BrowserColor {
    var background: UIColor { return UIColor.Photon.Grey10 } // layer1
}

class TabTrayColor {
    var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.extraLight }
}

class HomePanelColor {
    var activityStreamHeaderText: UIColor { return UIColor.Photon.DarkGrey90 }
}

class SnackBarColor {
    var highlight: UIColor { return UIColor.LegacyDefaults.iOSTextHighlightBlue.withAlphaComponent(0.9) }
    var highlightText: UIColor { return UIColor.Photon.Blue40 }
    var border: UIColor { return UIColor.Photon.Grey30 }
    var title: UIColor { return UIColor.Photon.Blue40 }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var browser: BrowserColor { get }
    var tabTray: TabTrayColor { get }
    var homePanel: HomePanelColor { get }
    var snackbar: SnackBarColor { get }
}

class LegacyNormalTheme: LegacyTheme {
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
    var browser: BrowserColor { return BrowserColor() }
    var tabTray: TabTrayColor { return TabTrayColor() }
    var homePanel: HomePanelColor { return HomePanelColor() }
    var snackbar: SnackBarColor { return SnackBarColor() }
}
