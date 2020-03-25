/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Convenience reference to these normal mode colors which are used in a few color classes.
fileprivate let defaultBackground = UIColor.Photon.Grey80
fileprivate let defaultSeparator = UIColor.Photon.Grey60
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
    override var accessoryViewTint: UIColor { return UIColor.Photon.Grey40 }
    override var selectedBackground: UIColor { return UIColor.Custom.selectedHighlightDark }
}

fileprivate class DarkActionMenuColor: ActionMenuColor {
    override var foreground: UIColor { return UIColor.Photon.White100 }
    override var iPhoneBackgroundBlurStyle: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
    override var iPhoneBackground: UIColor { return defaultBackground.withAlphaComponent(0.9) }
    override var closeButtonBackground: UIColor { return defaultBackground }
}

fileprivate class DarkURLBarColor: URLBarColor {
    override func textSelectionHighlight(_ isPrivate: Bool) -> TextSelectionHighlight {
        let color = isPrivate ? UIColor.Defaults.MobilePrivatePurple : UIColor(rgb: 0x3d89cc)
        return (labelMode: color.withAlphaComponent(0.25), textFieldMode: color)

    }
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
    override var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.dark }
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
    override var backgroundInOverlay: UIColor { return self.background }

    override var textAndTint: UIColor { return defaultTextAndTint }
    override var separator: UIColor { return super.separator.withAlphaComponent(0.3) }
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
    override var topSitesGradientStart:  UIColor { return UIColor(rgb: 0x29282d) }
    override var topSitesGradientEnd:  UIColor { return UIColor(rgb: 0x212104) }
    override var topSitesBackground: UIColor { return UIColor(rgb: 0x29282d) }

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
    override var settingsTextPlaceholder: UIColor { return UIColor.Photon.Grey40 }
    override var faviconBackground: UIColor { return UIColor.Photon.White100 }
    override var passcodeDot: UIColor { return UIColor.Photon.Grey40 }
    override var switchToggle: UIColor { return UIColor.Photon.Grey40 }
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
