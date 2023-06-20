// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return UIColor.Photon.DarkGrey60 }
}

private class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor { return UIColor.Photon.Grey70 } // layer2
    override var headerTextDark: UIColor { return UIColor.Photon.Grey30 }
    override var selectedBackground: UIColor { return UIColor.Custom.selectedHighlightDark }
    override var rowText: UIColor { return UIColor.Photon.Grey10 } // textPrimary
    override var disabledRowText: UIColor { return UIColor.Photon.Grey40 } // textDisabled
    override var headerBackground: UIColor { return UIColor.Photon.Grey80 }
}

private class DarkTabTrayColor: TabTrayColor {
    override var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
}

private class DarkHomePanelColor: HomePanelColor {
    override var activityStreamHeaderText: UIColor { return UIColor.Photon.LightGrey05 }
}

class LegacyDarkTheme: LegacyNormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var tableView: TableViewColor { return DarkTableViewColor() }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var tabTray: TabTrayColor { return DarkTabTrayColor() }
    override var topTabs: TopTabsColor { return TopTabsColor() }
    override var homePanel: HomePanelColor { return DarkHomePanelColor() }
    override var snackbar: SnackBarColor { return SnackBarColor() }
}
