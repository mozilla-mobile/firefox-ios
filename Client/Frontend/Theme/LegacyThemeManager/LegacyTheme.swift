// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0
import UIKit

protocol NotificationThemeable: AnyObject {
    func applyTheme()
}

protocol PrivateModeUI {
    func applyUIMode(isPrivate: Bool)
}

extension UIColor {
    static var theme: LegacyTheme {
        LegacyThemeManager.instance.current
    }
}

enum BuiltinThemeName: String {
    case normal
    case dark
}

// Convenience reference to these normal mode colors which are used in a few color classes.
private let defaultBackground = UIColor.Photon.Grey10
private let defaultSeparator = UIColor.Photon.Grey30
private let defaultTextAndTint = UIColor.Photon.Grey80

class TableViewColor {
    var rowBackground: UIColor {
        UIColor.Photon.White100
    }
    var rowText: UIColor {
        UIColor.Photon.Grey90
    }
    var rowDetailText: UIColor {
        UIColor.Photon.Grey60
    }
    var disabledRowText: UIColor {
        UIColor.Photon.Grey40
    }
    var separator: UIColor {
        defaultSeparator
    }
    var headerBackground: UIColor {
        defaultBackground
    }
    // Used for table headers in Settings and Photon menus
    var headerTextLight: UIColor {
        UIColor.Photon.Grey50
    }
    // Used for table headers in home panel tables
    var headerTextDark: UIColor {
        UIColor.Photon.Grey90
    }
    var rowActionAccessory: UIColor {
        UIColor.Photon.Blue40
    }
    var controlTint: UIColor {
        rowActionAccessory
    }
    var syncText: UIColor {
        defaultTextAndTint
    }
    var errorText: UIColor {
        UIColor.Photon.Red50
    }
    var warningText: UIColor {
        UIColor.Photon.Orange50
    }
    var accessoryViewTint: UIColor {
        UIColor.Photon.Grey40
    }
    var selectedBackground: UIColor {
        UIColor.Custom.selectedHighlightLight
    }
}

class ActionMenuColor {
    var foreground: UIColor {
        defaultTextAndTint
    }
    var iPhoneBackgroundBlurStyle: UIBlurEffect.Style {
        UIBlurEffect.Style.light
    }
    var iPhoneBackground: UIColor {
        defaultBackground.withAlphaComponent(0.9)
    }
    var closeButtonBackground: UIColor {
        defaultBackground
    }
}

class URLBarColor {
    var border: UIColor {
        UIColor.Photon.Grey90A10
    }
    func activeBorder(_ isPrivate: Bool) -> UIColor {
        !isPrivate ? UIColor.Photon.Blue20A40 : UIColor.Defaults.MobilePrivatePurple
    }
    var tint: UIColor {
        UIColor.Photon.Blue40A30
    }

    // This text selection color is used in two ways:
    // 1) <UILabel>.background = textSelectionHighlight.withAlphaComponent(textSelectionHighlightAlpha)
    // To simulate text highlighting when the URL bar is tapped once, this is a background
    // color to create a simulated selected text effect. The color will have an alpha
    // applied when assigning it to the background.
    // 2) <UITextField>.tintColor = textSelectionHighlight.
    // When the text is in edit mode (tapping URL bar second time), this is assigned to the to set the selection (and cursor) color. The color is assigned directly to the tintColor.
    typealias TextSelectionHighlight = (labelMode: UIColor, textFieldMode: UIColor?)
    func textSelectionHighlight(_ isPrivate: Bool) -> TextSelectionHighlight {
        if isPrivate {
            let color = UIColor.Defaults.MobilePrivatePurple
            return (labelMode: color.withAlphaComponent(0.25), textFieldMode: color)
        } else {
            return (labelMode: UIColor.Defaults.iOSTextHighlightBlue, textFieldMode: nil)
        }
    }

    var readerModeButtonSelected: UIColor {
        UIColor.Photon.Blue40
    }
    var readerModeButtonUnselected: UIColor {
        UIColor.Photon.Grey50
    }
    var pageOptionsSelected: UIColor {
        readerModeButtonSelected
    }
    var pageOptionsUnselected: UIColor {
        UIColor.theme.browser.tint
    }
}

class BrowserColor {
    var background: UIColor {
        defaultBackground
    }
    var urlBarDivider: UIColor {
        UIColor.Photon.Grey90A10
    }
    var tint: UIColor {
        defaultTextAndTint
    }
}

// The back/forward/refresh/menu button (bottom toolbar)
class ToolbarButtonColor {
    var selectedTint: UIColor {
        UIColor.Photon.Blue40
    }
    var disabledTint: UIColor {
        UIColor.Photon.Grey30
    }
}

class LoadingBarColor {
    func start(_ isPrivate: Bool) -> UIColor {
        !isPrivate ? UIColor.Photon.Violet50 : UIColor.Photon.Magenta60A30
    }
    // Adds middle color for loadingBar only in public browsing
    func middle(_ isPrivate: Bool) -> UIColor? {
        !isPrivate ? UIColor.Photon.Pink40 : nil
    }

    func end(_ isPrivate: Bool) -> UIColor {
        !isPrivate ? UIColor.Photon.Yellow40 : UIColor.Photon.Purple60
    }
}

class TabTrayColor {
    var tabTitleText: UIColor {
        UIColor.black
    }
    var tabTitleBlur: UIBlurEffect.Style {
        UIBlurEffect.Style.extraLight
    }
    var background: UIColor {
        UIColor.Photon.LightGrey30
    }
    var screenshotBackground: UIColor {
        UIColor.Photon.Grey10
    }
    var cellBackground: UIColor {
        defaultBackground
    }
    var toolbar: UIColor {
        defaultBackground
    }
    var toolbarButtonTint: UIColor {
        defaultTextAndTint
    }
    var privateModeLearnMore: UIColor {
        UIColor.Photon.Purple60
    }
    var privateModePurple: UIColor {
        UIColor.Photon.Purple60
    }
    var privateModeButtonOffTint: UIColor {
        toolbarButtonTint
    }
    var privateModeButtonOnTint: UIColor {
        UIColor.Photon.Grey10
    }
    var cellCloseButton: UIColor {
        UIColor.Photon.Grey50
    }
    var cellTitleBackground: UIColor {
        UIColor.clear
    }
    var faviconTint: UIColor {
        UIColor.black
    }
    var searchBackground: UIColor {
        UIColor.Photon.Grey30
    }
}

class EnhancedTrackingProtectionMenuColor {
    var defaultImageTints: UIColor {
        defaultTextAndTint
    }
    var background: UIColor {
        UIColor.Photon.Grey12
    }
    var horizontalLine: UIColor {
        UIColor.Photon.Grey75A39
    }
    var sectionColor: UIColor {
        .white
    }
    var switchAndButtonTint: UIColor {
        UIColor.Photon.Blue50
    }
    var subtextColor: UIColor {
        UIColor.Photon.Grey75A60
    }
    var closeButtonColor: UIColor {
        UIColor.Photon.LightGrey30
    }
}

class TopTabsColor {
    var background: UIColor {
        UIColor.Photon.LightGrey20
    }
    var tabBackgroundSelected: UIColor {
        UIColor.Photon.Grey10
    }
    var tabBackgroundUnselected: UIColor {
        UIColor.Photon.Grey80
    }
    var tabForegroundSelected: UIColor {
        UIColor.Photon.Grey90
    }
    var tabForegroundUnselected: UIColor {
        UIColor.Photon.Grey40
    }
    func tabSelectedIndicatorBar(_ isPrivate: Bool) -> UIColor {
        !isPrivate ? UIColor.Photon.Blue40 : UIColor.Photon.Purple60
    }
    var buttonTint: UIColor {
        UIColor.Photon.Grey80
    }
    var privateModeButtonOffTint: UIColor {
        buttonTint
    }
    var privateModeButtonOnTint: UIColor {
        UIColor.Photon.Grey10
    }
    var closeButtonSelectedTab: UIColor {
        tabBackgroundUnselected
    }
    var closeButtonUnselectedTab: UIColor {
        tabBackgroundSelected
    }
    var separator: UIColor {
        UIColor.Photon.Grey70
    }
}

class TextFieldColor {
    var background: UIColor {
        UIColor.Photon.LightGrey20
    }
    var backgroundInOverlay: UIColor {
        UIColor.Photon.LightGrey20
    }
    var textAndTint: UIColor {
        defaultTextAndTint
    }
    var separator: UIColor {
        .white
    }
}

class HomePanelColor {
    var toolbarBackground: UIColor {
        defaultBackground
    }
    var toolbarHighlight: UIColor {
        UIColor.Photon.Blue40
    }
    var toolbarTint: UIColor {
        UIColor.Photon.Grey50
    }
    var topSiteHeaderTitle: UIColor {
        .black
    }
    var panelBackground: UIColor {
        UIColor.Photon.White100
    }

    var separator: UIColor {
        defaultSeparator
    }
    var border: UIColor {
        UIColor.Photon.Grey60
    }
    var buttonContainerBorder: UIColor {
        separator
    }

    var welcomeScreenText: UIColor {
        UIColor.Photon.Grey50
    }
    var bookmarkIconBorder: UIColor {
        UIColor.Photon.Grey30
    }
    var bookmarkFolderBackground: UIColor {
        UIColor.Photon.Grey10.withAlphaComponent(0.3)
    }
    var bookmarkFolderText: UIColor {
        UIColor.Photon.Grey80
    }
    var bookmarkCurrentFolderText: UIColor {
        UIColor.Photon.Blue40
    }
    var bookmarkBackNavCellBackground: UIColor {
        UIColor.clear
    }

    var siteTableHeaderBorder: UIColor {
        UIColor.Photon.Grey30.withAlphaComponent(0.8)
    }

    var topSiteDomain: UIColor {
        UIColor.Photon.DarkGrey90
    }
    var topSitePin: UIColor {
        UIColor.Photon.DarkGrey05
    }
    var topSitesBackground: UIColor {
        UIColor.Photon.LightGrey10
    }

    var shortcutBackground: UIColor {
        .white
    }
    var shortcutShadowColor: CGColor {
        UIColor(red: 0.23, green: 0.22, blue: 0.27, alpha: 1.0).cgColor
    }
    var shortcutShadowOpacity: Float {
        0.2
    }

    var recentlySavedBookmarkCellBackground: UIColor {
        .white
    }

    var recentlyVisitedCellGroupImage: UIColor {
        UIColor.Photon.DarkGrey90
    }
    var recentlyVisitedCellBottomLine: UIColor {
        UIColor.Photon.LightGrey40
    }

    var activityStreamHeaderText: UIColor {
        UIColor.Photon.DarkGrey90
    }
    var activityStreamHeaderButton: UIColor {
        UIColor.Photon.Blue50
    }
    var activityStreamCellTitle: UIColor {
        UIColor.Photon.DarkGrey90
    }
    var activityStreamCellDescription: UIColor {
        UIColor.Photon.DarkGrey05
    }

    var readingListActive: UIColor {
        defaultTextAndTint
    }
    var readingListDimmed: UIColor {
        UIColor.Photon.Grey40
    }

    var downloadedFileIcon: UIColor {
        UIColor.Photon.Grey60
    }

    var historyHeaderIconsBackground: UIColor {
        UIColor.Photon.White100
    }

    var searchSuggestionPillBackground: UIColor {
        UIColor.Photon.White100
    }
    var searchSuggestionPillForeground: UIColor {
        UIColor.Photon.Blue40
    }

    var customizeHomepageButtonBackground: UIColor {
        UIColor.Photon.LightGrey30
    }
    var customizeHomepageButtonText: UIColor {
        UIColor.Photon.DarkGrey90
    }

    var sponsored: UIColor {
        UIColor.Photon.DarkGrey05
    }
}

class SnackBarColor {
    var highlight: UIColor {
        UIColor.Defaults.iOSTextHighlightBlue.withAlphaComponent(0.9)
    }
    var highlightText: UIColor {
        UIColor.Photon.Blue40
    }
    var border: UIColor {
        UIColor.Photon.Grey30
    }
    var title: UIColor {
        UIColor.Photon.Blue40
    }
}

class GeneralColor {
    var faviconBackground: UIColor {
        UIColor.clear
    }
    var passcodeDot: UIColor {
        UIColor.Photon.Grey60
    }
    var highlightBlue: UIColor {
        UIColor.Photon.Blue40
    }
    var destructiveRed: UIColor {
        UIColor.Photon.Red50
    }
    var separator: UIColor {
        defaultSeparator
    }
    var settingsTextPlaceholder: UIColor {
        UIColor.Photon.Grey40
    }
    var controlTint: UIColor {
        UIColor.Photon.Blue40
    }
    var switchToggle: UIColor {
        UIColor.Photon.Grey90A40
    }
}

class HomeTabBannerColor {
    var backgroundColor: UIColor {
        UIColor.Photon.Grey30
    }
    var textColor: UIColor {
        UIColor.black
    }
    var closeButtonBackground: UIColor {
        UIColor.Photon.Grey20
    }
    var closeButton: UIColor {
        UIColor.Photon.Grey80
    }
}

class OnboardingColor {
    var backgroundColor: UIColor {
        UIColor.white
    }
}

class RemoteTabTrayColor {
    var background: UIColor {
        UIColor.white
    }
}

protocol LegacyTheme {
    var name: String { get }
    var tableView: TableViewColor { get }
    var urlbar: URLBarColor { get }
    var browser: BrowserColor { get }
    var toolbarButton: ToolbarButtonColor { get }
    var loadingBar: LoadingBarColor { get }
    var tabTray: TabTrayColor { get }
    var etpMenu: EnhancedTrackingProtectionMenuColor { get }
    var topTabs: TopTabsColor { get }
    var textField: TextFieldColor { get }
    var homePanel: HomePanelColor { get }
    var snackbar: SnackBarColor { get }
    var general: GeneralColor { get }
    var actionMenu: ActionMenuColor { get }
    var switchToggleTheme: GeneralColor { get }
    var homeTabBanner: HomeTabBannerColor { get }
    var onboarding: OnboardingColor { get }
    var remotePanel: RemoteTabTrayColor { get }
}

class NormalTheme: LegacyTheme {
    var name: String {
        BuiltinThemeName.normal.rawValue
    }
    var tableView: TableViewColor {
        TableViewColor()
    }
    var urlbar: URLBarColor {
        URLBarColor()
    }
    var browser: BrowserColor {
        BrowserColor()
    }
    var toolbarButton: ToolbarButtonColor {
        ToolbarButtonColor()
    }
    var loadingBar: LoadingBarColor {
        LoadingBarColor()
    }
    var tabTray: TabTrayColor {
        TabTrayColor()
    }
    var topTabs: TopTabsColor {
        TopTabsColor()
    }
    var etpMenu: EnhancedTrackingProtectionMenuColor {
        EnhancedTrackingProtectionMenuColor()
    }
    var textField: TextFieldColor {
        TextFieldColor()
    }
    var homePanel: HomePanelColor {
        HomePanelColor()
    }
    var snackbar: SnackBarColor {
        SnackBarColor()
    }
    var general: GeneralColor {
        GeneralColor()
    }
    var actionMenu: ActionMenuColor {
        ActionMenuColor()
    }
    var switchToggleTheme: GeneralColor {
        GeneralColor()
    }
    var homeTabBanner: HomeTabBannerColor {
        HomeTabBannerColor()
    }
    var onboarding: OnboardingColor {
        OnboardingColor()
    }
    var remotePanel: RemoteTabTrayColor {
        RemoteTabTrayColor()
    }
}
