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
        return LegacyThemeManager.instance.current
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
    var rowBackground: UIColor { return UIColor.Photon.White100 }
    var rowText: UIColor { return UIColor.Photon.Grey90 }
    var rowDetailText: UIColor { return UIColor.Photon.Grey60 }
    var disabledRowText: UIColor { return UIColor.Photon.Grey40 }
    var separator: UIColor { return defaultSeparator }
    var headerBackground: UIColor { return defaultBackground }
    // Used for table headers in Settings and Photon menus
    var headerTextLight: UIColor { return UIColor.Photon.Grey50 }
    // Used for table headers in home panel tables
    var headerTextDark: UIColor { return UIColor.Photon.Grey90 }
    var rowActionAccessory: UIColor { return UIColor.Photon.Blue40 }
    var controlTint: UIColor { return rowActionAccessory }
    var syncText: UIColor { return defaultTextAndTint }
    var errorText: UIColor { return UIColor.Photon.Red50 }
    var warningText: UIColor { return UIColor.Photon.Orange50 }
    var accessoryViewTint: UIColor { return UIColor.Photon.Grey40 }
    var selectedBackground: UIColor { return UIColor.Custom.selectedHighlightLight }
}

class ActionMenuColor {
    var foreground: UIColor { return defaultTextAndTint }
    var iPhoneBackgroundBlurStyle: UIBlurEffect.Style { return UIBlurEffect.Style.light }
    var iPhoneBackground: UIColor { return defaultBackground.withAlphaComponent(0.9) }
    var closeButtonBackground: UIColor { return defaultBackground }
}

class URLBarColor {
    var border: UIColor { return UIColor.Photon.Grey90A10 }
    func activeBorder(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Blue20A40 : UIColor.Defaults.MobilePrivatePurple
    }
    var tint: UIColor { return UIColor.Photon.Blue40A30 }

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

    var readerModeButtonSelected: UIColor { return UIColor.Photon.Blue40 }
    var readerModeButtonUnselected: UIColor { return UIColor.Photon.Grey50 }
    var pageOptionsSelected: UIColor { return readerModeButtonSelected }
    var pageOptionsUnselected: UIColor { return UIColor.theme.browser.tint }
}

class BrowserColor {
    var background: UIColor { return defaultBackground }
    var urlBarDivider: UIColor { return UIColor.Photon.Grey90A10 }
    var tint: UIColor { return defaultTextAndTint }
}

// The back/forward/refresh/menu button (bottom toolbar)
class ToolbarButtonColor {
    var selectedTint: UIColor { return UIColor.Photon.Blue40 }
    var disabledTint: UIColor { return UIColor.Photon.Grey30 }
}

class LoadingBarColor {
    func start(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Violet50 : UIColor.Photon.Magenta60A30
    }
    // Adds middle color for loadingBar only in public browsing
    func middle(_ isPrivate: Bool) -> UIColor? {
        return !isPrivate ? UIColor.Photon.Pink40 : nil
    }

    func end(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Yellow40 : UIColor.Photon.Purple60
    }
}

class TabTrayColor {
    var tabTitleText: UIColor { return UIColor.black }
    var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.extraLight }
    var background: UIColor { return UIColor.Photon.LightGrey30 }
    var screenshotBackground: UIColor { return UIColor.Photon.Grey10 }
    var cellBackground: UIColor { return defaultBackground }
    var toolbar: UIColor { return defaultBackground }
    var toolbarButtonTint: UIColor { return defaultTextAndTint }
    var privateModeLearnMore: UIColor { return UIColor.Photon.Purple60 }
    var privateModePurple: UIColor { return UIColor.Photon.Purple60 }
    var privateModeButtonOffTint: UIColor { return toolbarButtonTint }
    var privateModeButtonOnTint: UIColor { return UIColor.Photon.Grey10 }
    var cellCloseButton: UIColor { return UIColor.Photon.Grey50 }
    var cellTitleBackground: UIColor { return UIColor.clear }
    var faviconTint: UIColor { return UIColor.black }
    var searchBackground: UIColor { return UIColor.Photon.Grey30 }
}

class EnhancedTrackingProtectionMenuColor {
    var defaultImageTints: UIColor { return defaultTextAndTint }
    var background: UIColor { return UIColor.Photon.Grey12 }
    var horizontalLine: UIColor { return UIColor.Photon.Grey75A39 }
    var sectionColor: UIColor { return .white }
    var switchAndButtonTint: UIColor { return UIColor.Photon.Blue50 }
    var subtextColor: UIColor { return UIColor.Photon.Grey75A60}
    var closeButtonColor: UIColor { return UIColor.Photon.LightGrey30 }
}

class TopTabsColor {
    var background: UIColor { return UIColor.Photon.LightGrey20 }
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

class TextFieldColor {
    var background: UIColor { return UIColor.Photon.LightGrey20 }
    var backgroundInOverlay: UIColor { return UIColor.Photon.LightGrey20 }
    var textAndTint: UIColor { return defaultTextAndTint }
    var separator: UIColor { return .white }
}

class HomePanelColor {
    var toolbarBackground: UIColor { return defaultBackground }
    var toolbarHighlight: UIColor { return UIColor.Photon.Blue40 }
    var toolbarTint: UIColor { return UIColor.Photon.Grey50 }
    var topSiteHeaderTitle: UIColor { return .black }
    var panelBackground: UIColor { return UIColor.Photon.White100 }

    var separator: UIColor { return defaultSeparator }
    var border: UIColor { return UIColor.Photon.Grey60 }
    var buttonContainerBorder: UIColor { return separator }

    var welcomeScreenText: UIColor { return UIColor.Photon.Grey50 }
    var bookmarkIconBorder: UIColor { return UIColor.Photon.Grey30 }
    var bookmarkFolderBackground: UIColor { return UIColor.Photon.Grey10.withAlphaComponent(0.3) }
    var bookmarkFolderText: UIColor { return UIColor.Photon.Grey80 }
    var bookmarkCurrentFolderText: UIColor { return UIColor.Photon.Blue40 }
    var bookmarkBackNavCellBackground: UIColor { return UIColor.clear }

    var siteTableHeaderBorder: UIColor { return UIColor.Photon.Grey30.withAlphaComponent(0.8) }

    var topSiteDomain: UIColor { return UIColor.Photon.DarkGrey90 }
    var topSitePin: UIColor { return UIColor.Photon.DarkGrey05 }
    var topSitesBackground: UIColor { return UIColor.Photon.LightGrey10 }

    var shortcutBackground: UIColor { return .white }
    var shortcutShadowColor: CGColor { return UIColor(red: 0.23, green: 0.22, blue: 0.27, alpha: 1.0).cgColor }
    var shortcutShadowOpacity: Float { return 0.2 }

    var recentlySavedBookmarkCellBackground: UIColor { return .white}

    var recentlyVisitedCellGroupImage: UIColor { return UIColor.Photon.DarkGrey90 }
    var recentlyVisitedCellBottomLine: UIColor { return UIColor.Photon.LightGrey40 }

    var activityStreamHeaderText: UIColor { return UIColor.Photon.DarkGrey90 }
    var activityStreamHeaderButton: UIColor { return UIColor.Photon.Blue50 }
    var activityStreamCellTitle: UIColor { return UIColor.Photon.DarkGrey90 }
    var activityStreamCellDescription: UIColor { return UIColor.Photon.DarkGrey05 }

    var readingListActive: UIColor { return defaultTextAndTint }
    var readingListDimmed: UIColor { return UIColor.Photon.Grey40 }

    var downloadedFileIcon: UIColor { return UIColor.Photon.Grey60 }

    var historyHeaderIconsBackground: UIColor { return UIColor.Photon.White100 }

    var searchSuggestionPillBackground: UIColor { return UIColor.Photon.White100 }
    var searchSuggestionPillForeground: UIColor { return UIColor.Photon.Blue40 }

    var customizeHomepageButtonBackground: UIColor { return UIColor.Photon.LightGrey30 }
    var customizeHomepageButtonText: UIColor { return UIColor.Photon.DarkGrey90 }
}

class SnackBarColor {
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue.withAlphaComponent(0.9) }
    var highlightText: UIColor { return UIColor.Photon.Blue40 }
    var border: UIColor { return UIColor.Photon.Grey30 }
    var title: UIColor { return UIColor.Photon.Blue40 }
}

class GeneralColor {
    var faviconBackground: UIColor { return UIColor.clear }
    var passcodeDot: UIColor { return UIColor.Photon.Grey60 }
    var highlightBlue: UIColor { return UIColor.Photon.Blue40 }
    var destructiveRed: UIColor { return UIColor.Photon.Red50 }
    var separator: UIColor { return defaultSeparator }
    var settingsTextPlaceholder: UIColor { return UIColor.Photon.Grey40 }
    var controlTint: UIColor { return UIColor.Photon.Blue40 }
    var switchToggle: UIColor { return UIColor.Photon.Grey90A40 }
}

class HomeTabBannerColor {
    var backgroundColor: UIColor { return UIColor.Photon.Grey30 }
    var textColor: UIColor { return UIColor.black }
    var closeButtonBackground: UIColor { return UIColor.Photon.Grey20 }
    var closeButton: UIColor { return UIColor.Photon.Grey80 }
}

class OnboardingColor {
    var backgroundColor: UIColor { return UIColor.white }
}

class RemoteTabTrayColor {
    var background: UIColor { return UIColor.white }
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
    var name: String { return BuiltinThemeName.normal.rawValue }
    var tableView: TableViewColor { return TableViewColor() }
    var urlbar: URLBarColor { return URLBarColor() }
    var browser: BrowserColor { return BrowserColor() }
    var toolbarButton: ToolbarButtonColor { return ToolbarButtonColor() }
    var loadingBar: LoadingBarColor { return LoadingBarColor() }
    var tabTray: TabTrayColor { return TabTrayColor() }
    var topTabs: TopTabsColor { return TopTabsColor() }
    var etpMenu: EnhancedTrackingProtectionMenuColor { return EnhancedTrackingProtectionMenuColor() }
    var textField: TextFieldColor { return TextFieldColor() }
    var homePanel: HomePanelColor { return HomePanelColor() }
    var snackbar: SnackBarColor { return SnackBarColor() }
    var general: GeneralColor { return GeneralColor() }
    var actionMenu: ActionMenuColor { return ActionMenuColor() }
    var switchToggleTheme: GeneralColor { return GeneralColor() }
    var homeTabBanner: HomeTabBannerColor { return HomeTabBannerColor() }
    var onboarding: OnboardingColor { return OnboardingColor() }
    var remotePanel: RemoteTabTrayColor { return RemoteTabTrayColor() }
}
