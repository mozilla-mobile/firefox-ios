/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Convenience reference to these normal mode colors which are used in a few color classes.
fileprivate let defaultBackground = UIColor.Photon.Ink80
fileprivate let defaultSeparator = UIColor.Photon.Grey30
fileprivate let defaultTextAndTint = UIColor.Photon.Grey10

fileprivate class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor { return UIColor.Photon.Ink70 }
    override var rowText: UIColor { return defaultTextAndTint }
    override var rowDetailText: UIColor { return UIColor.Photon.Grey30 }
    override var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    override var separator: UIColor { return UIColor.Photon.Grey60 }
    override var headerBackground: UIColor { return UIColor.Photon.Ink80 }
    override var headerTextLight: UIColor { return UIColor.Photon.Grey30 }
    override var headerTextDark: UIColor { return UIColor.Photon.Grey30 }
//    override var rowActionAccessory: UIColor { return UIColor.Photon.Blue50 }
//    override var controlTint: UIColor { return rowActionAccessory }
    override var syncText: UIColor { return defaultTextAndTint }
//    override var errorText: UIColor { return UIColor.Photon.Red50 }
//    override var warningText: UIColor { return UIColor.Photon.Orange50 }
}

fileprivate class DarkActionMenuColor: ActionMenuColor {
    override var foreground: UIColor { return defaultTextAndTint }
    override var iPhoneBackground: UIColor { return UIColor.Photon.Ink90.withAlphaComponent(0.7) }
    override var iPhoneBackgroundBlurStyle: UIBlurEffectStyle { return UIBlurEffectStyle.light }
    override var closeButtonBackground: UIColor { return defaultBackground }

}

fileprivate class DarkURLBarColor: URLBarColor {
    override var border: UIColor { return UIColor.Photon.Grey50 }
    override var activeBorder: UIColor { return UIColor.Photon.Blue50A30 }
    override var tint: UIColor { return UIColor.Photon.Blue50A30 }
    override var textSelectionHighlight: UIColor { return UIColor.Photon.Blue60 }
    override var readerModeButtonSelected: UIColor { return UIColor.Photon.Blue40 }
    override var readerModeButtonUnselected: UIColor { return UIColor.Photon.Grey20 }
    override var pageOptionsSelected: UIColor { return readerModeButtonSelected }
    override var pageOptionsUnselected: UIColor { return UIColor.theme.browser.tint }
}

fileprivate class DarkBrowserColor: BrowserColor {
    override var background: UIColor { return defaultBackground }
//    override var urlBarDivider: UIColor { return UIColor.Photon.Grey90A10 }
    override var tint: UIColor { return defaultTextAndTint }
}

// The back/forward/refresh/menu button (bottom toolbar)
fileprivate class DarkToolbarButtonColor: ToolbarButtonColor {
//    override var selectedTint: UIColor { return UIColor.Photon.Blue40 }
//    override var disabledTint: UIColor { return UIColor.Photon.Grey30 }
}

fileprivate class DarkLoadingBarColor: LoadingBarColor {
//    override var start: UIColor { return UIColor.Photon.Blue50A30 }
//    override var end: UIColor { return UIColor.Photon.Blue50 }
}

fileprivate class DarkTabTrayColor: TabTrayColor {
    override var tabTitleText: UIColor { return defaultTextAndTint }
    override var tabTitleBlur: UIBlurEffectStyle { return UIBlurEffectStyle.dark }
    override var background: UIColor { return UIColor.Photon.Ink90 }
    override var cellBackground: UIColor { return defaultBackground }
    override var toolbar: UIColor { return UIColor.Photon.Ink80 }
    override var toolbarButtonTint: UIColor { return defaultTextAndTint }
    override var cellCloseButton: UIColor { return defaultTextAndTint }
//    override var privateModeLearnMore: UIColor { return UIColor.Photon.Purple60 }
//    override var privateModePurple: UIColor { return UIColor.Defaults.MobilePrivatePurple }
//    override var privateModeButtonOffTint: UIColor { return toolbarButtonTint }
//    override var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
    override var cellTitleBackground: UIColor { return UIColor.Photon.Ink70 }
}

fileprivate class DarkTopTabsColor: TopTabsColor {
    override var background: UIColor { return UIColor.Photon.Grey80 }
    override var tabBackgroundSelected: UIColor { return UIColor.Photon.Grey80 }
    override var tabBackgroundUnselected: UIColor { return UIColor.Photon.Ink80 }
    override var tabForegroundSelected: UIColor { return UIColor.Photon.Grey10 }
    override var tabForegroundUnselected: UIColor { return UIColor.Photon.Grey40 }
   
//    override var selectedLineNormalMode: UIColor { return UIColor.Photon.Blue60 }
//    override var selectedLinePrivateMode: UIColor { return UIColor.Photon.Purple50 }
//    override var buttonTint: UIColor { return .red }
//    override var privateModeButtonOffTint: UIColor { return buttonTint }
//    override var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
    override var closeButtonSelectedTab: UIColor { return tabForegroundSelected }
    override var closeButtonUnselectedTab: UIColor { return tabForegroundUnselected }
    override var separator: UIColor { return UIColor.Photon.Grey50 }
}

fileprivate class DarkTextFieldColor: TextFieldColor {
    override var background: UIColor { return UIColor.Photon.Ink70 }
    override var textAndTint: UIColor { return defaultTextAndTint }
   // override var separator: UIColor { return defaultSeparator }
}

fileprivate class DarkHomePanelColor: HomePanelColor {
    override var toolbarBackground: UIColor { return defaultBackground }
    override var toolbarHighlight: UIColor { return UIColor.Photon.Blue50 }
    override var toolbarTint: UIColor { return UIColor.Photon.Grey30 }
    override var panelBackground: UIColor { return UIColor.black }
    override var separator: UIColor { return defaultSeparator }
    override var border: UIColor { return UIColor.Photon.Grey60 }
    override var buttonContainerBorder: UIColor { return separator }
    override var backgroundColorPrivateMode: UIColor { return UIColor.Photon.Grey50 }

    override var welcomeScreenText: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkIconBorder: UIColor { return UIColor.Photon.Grey30 }
    override var bookmarkFolderBackground: UIColor { return UIColor.Photon.Ink80 }
    override var bookmarkFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkCurrentFolderText: UIColor { return UIColor.Photon.White100 }
    override var bookmarkBackNavCellBackground: UIColor { return UIColor.Photon.Ink70 }
    
   //  var siteTableHeaderBorder: UIColor { return UIColor.Photon.Grey30.withAlphaComponent(0.8) }
    // var siteTableHeaderText: UIColor { return UIColor.Photon.Grey80 }
   // var siteTableHeaderBackground: UIColor { return UIColor.Photon.Grey10 }

    override var activityStreamHeaderText: UIColor { return UIColor.Photon.Grey30 }
    override var activityStreamCellTitle: UIColor { return UIColor.Photon.Grey20 }
    override var activityStreamCellDescription: UIColor { return UIColor.Photon.Grey30 }

    override var topSiteDomain: UIColor { return defaultTextAndTint }
    
    override var downloadedFileIcon: UIColor { return UIColor.Photon.Grey30 }

    override var historyHeaderIconsBackground: UIColor { return UIColor.clear }

    override var readingListActive: UIColor { return UIColor.Photon.Grey10 }
    override var readingListDimmed: UIColor { return UIColor.Photon.Grey40 }
}

fileprivate class DarkSnackBarColor: SnackBarColor {
// Use defaults
}

fileprivate class DarkGeneralColor: GeneralColor {
//    override var passcodeDot: UIColor { return UIColor.Photon.Grey60 }
//    override var highlightBlue: UIColor { return UIColor.Photon.Blue50 }
//    override var destructiveRed: UIColor { return UIColor.Photon.Red50 }
//    override var separator: UIColor { return defaultSeparator }

    override var settingsTextPlaceholder: UIColor? { return UIColor.black }
}

class DarkTheme: NormalTheme {
    override var name: String { return BuiltinThemeName.dark.rawValue }
    override var tableView: TableViewColor { return DarkTableViewColor() }
    override var urlbar: URLBarColor { return DarkURLBarColor() }
    override var browser: BrowserColor { return DarkBrowserColor() }
    override var toolbarButton: ToolbarButtonColor { return DarkToolbarButtonColor() }
    override var loadingBar: LoadingBarColor { return DarkLoadingBarColor() }
    override var tabTray: TabTrayColor { return DarkTabTrayColor() }
    override var topTabs: TopTabsColor { return DarkTopTabsColor() }
    override var textField: TextFieldColor { return DarkTextFieldColor() }
    override var homePanel: HomePanelColor { return DarkHomePanelColor() }
    override var snackbar: SnackBarColor { return DarkSnackBarColor() }
    override var general: GeneralColor { return DarkGeneralColor() }
    override var actionMenu: ActionMenuColor { return DarkActionMenuColor() } 
}
