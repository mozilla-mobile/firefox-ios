/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Convenience reference to these normal mode colors which are used in a few color classes.
fileprivate let defaultBackground = UIColor.Photon.Grey80
fileprivate let defaultSeparator = UIColor.Photon.Grey30
fileprivate let defaultTextAndTint = UIColor.Photon.Grey10

fileprivate class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor { return UIColor.Photon.Grey70 }
    override var rowText: UIColor { return defaultTextAndTint }
    override var rowDetailText: UIColor { return UIColor.Photon.Grey30 }
    override var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    override var separator: UIColor { return UIColor.Photon.Grey60 }
    override var headerBackground: UIColor { return UIColor.Photon.Grey80 }
    override var headerTextLight: UIColor { return UIColor.Photon.Grey30 }
    override var headerTextDark: UIColor { return UIColor.Photon.Grey30 }
    override var syncText: UIColor { return defaultTextAndTint }
}

fileprivate class DarkActionMenuColor: ActionMenuColor {
    override var foreground: UIColor { return defaultTextAndTint }
    override var iPhoneBackground: UIColor { return UIColor.Photon.Grey90.withAlphaComponent(0.9) }
    override var closeButtonBackground: UIColor { return defaultBackground }

}

fileprivate class DarkURLBarColor: URLBarColor {
    // use defaults
}

fileprivate class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return defaultBackground }
    override var tint: UIColor { return defaultTextAndTint }
}

// The back/forward/refresh/menu button (bottom toolbar)
fileprivate class DarkToolbarButtonColor: ToolbarButtonColor {

}

fileprivate class DarkTabTrayColor: TabTrayColor {
    override var tabTitleText: UIColor { return defaultTextAndTint }
    override var tabTitleBlur: UIBlurEffectStyle { return UIBlurEffectStyle.dark }
    override var background: UIColor { return UIColor.Photon.Grey90 }
    override var cellBackground: UIColor { return defaultBackground }
    override var toolbar: UIColor { return UIColor.Photon.Grey80 }
    override var toolbarButtonTint: UIColor { return defaultTextAndTint }
    override var cellCloseButton: UIColor { return defaultTextAndTint }
    override var cellTitleBackground: UIColor { return UIColor.Photon.Grey70 }
    override var searchBackground: UIColor { return UIColor.Photon.Grey60 }
}

fileprivate class DarkTopTabsColor: TopTabsColor {
    override var background: UIColor { return UIColor.Photon.Grey80 }
    override var tabBackgroundSelected: UIColor { return UIColor.Photon.Grey80 }
    override var tabBackgroundUnselected: UIColor { return UIColor.Photon.Grey80 }
    override var tabForegroundSelected: UIColor { return UIColor.Photon.Grey10 }
    override var tabForegroundUnselected: UIColor { return UIColor.Photon.Grey40 }
    override var closeButtonSelectedTab: UIColor { return tabForegroundSelected }
    override var closeButtonUnselectedTab: UIColor { return tabForegroundUnselected }
    override var separator: UIColor { return UIColor.Photon.Grey50 }
}

fileprivate class DarkTextFieldColor: TextFieldColor {
    override var background: UIColor { return UIColor.Photon.Grey60 }
    override var textAndTint: UIColor { return defaultTextAndTint }

}

fileprivate class DarkHomePanelColor: HomePanelColor {
    override var toolbarBackground: UIColor { return defaultBackground }
    override var toolbarHighlight: UIColor { return UIColor.Photon.Blue40 }
    override var toolbarTint: UIColor { return UIColor.Photon.Grey30 }
    override var panelBackground: UIColor { return UIColor.Photon.Grey90 }
    override var separator: UIColor { return defaultSeparator }
    override var border: UIColor { return UIColor.Photon.Grey60 }
    override var buttonContainerBorder: UIColor { return separator }

    override var welcomeScreenText: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkIconBorder: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkFolderBackground: UIColor { return UIColor.Photon.Grey80 }
    override var bookmarkFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkCurrentFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkBackNavCellBackground: UIColor { return UIColor.Photon.Grey70 }
    
    override var activityStreamHeaderText: UIColor { return UIColor.Photon.Grey30 }
    override var activityStreamCellTitle: UIColor { return UIColor.Photon.Grey20 }
    override var activityStreamCellDescription: UIColor { return UIColor.Photon.Grey30 }

    override var topSiteDomain: UIColor { return defaultTextAndTint }
    
    override var downloadedFileIcon: UIColor { return UIColor.Photon.Grey30 }

    override var historyHeaderIconsBackground: UIColor { return UIColor.clear }

    override var readingListActive: UIColor { return UIColor.Photon.Grey10 }
    override var readingListDimmed: UIColor { return UIColor.Photon.Grey40 }

    override var searchSuggestionPillBackground: UIColor { return UIColor.Photon.Grey70 }
    override var searchSuggestionPillForeground: UIColor { return defaultTextAndTint }
}

fileprivate class DarkSnackBarColor: SnackBarColor {
// Use defaults
}

fileprivate class DarkGeneralColor: GeneralColor {
    override var settingsTextPlaceholder: UIColor? { return UIColor.black }
    override var faviconBackground: UIColor { return UIColor.Photon.White100 }
}

class DarkTheme: NormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var tableView: TableViewColor { return DarkTableViewColor() }
    override var urlbar: URLBarColor { return DarkURLBarColor() }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var toolbarButton: ToolbarButtonColor { return DarkToolbarButtonColor() }
    override var tabTray: TabTrayColor { return DarkTabTrayColor() }
    override var topTabs: TopTabsColor { return DarkTopTabsColor() }
    override var textField: TextFieldColor { return DarkTextFieldColor() }
    override var homePanel: HomePanelColor { return DarkHomePanelColor() }
    override var snackbar: SnackBarColor { return DarkSnackBarColor() }
    override var general: GeneralColor { return DarkGeneralColor() }
    override var actionMenu: ActionMenuColor { return DarkActionMenuColor() } 
}
