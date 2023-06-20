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
    var headerTextDark: UIColor { return UIColor.Photon.Grey90 }
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

class TopTabsColor {
    var tabBackgroundSelected: UIColor { return UIColor.Photon.Grey10 }
    var tabBackgroundUnselected: UIColor { return UIColor.Photon.Grey80 }
    var tabForegroundSelected: UIColor { return UIColor.Photon.Grey90 }
    var tabForegroundUnselected: UIColor { return UIColor.Photon.Grey40 }
    func tabSelectedIndicatorBar(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Blue40 : UIColor.Photon.Purple60
    }
    var buttonTint: UIColor { return UIColor.Photon.Grey80 }
    var privateModeButtonOffTint: UIColor { return buttonTint }
    var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
    var closeButtonSelectedTab: UIColor { return tabBackgroundUnselected }
    var closeButtonUnselectedTab: UIColor { return tabBackgroundSelected }
    var separator: UIColor { return UIColor.Photon.Grey70 }
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

class OnboardingColor {
    var backgroundColor: UIColor { return UIColor.white }
    var etpBackgroundColor: UIColor { return UIColor.white }
    var etpTextColor: UIColor { return UIColor.black }
    var etpButtonColor: UIColor { return UIColor.Photon.Blue50 }
}

class RemoteTabTrayColor {
    var background: UIColor { return UIColor.white }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var topTabs: TopTabsColor { get }
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
    var topTabs: TopTabsColor { return TopTabsColor() }
    var homePanel: HomePanelColor { return HomePanelColor() }
    var snackbar: SnackBarColor { return SnackBarColor() }
}
