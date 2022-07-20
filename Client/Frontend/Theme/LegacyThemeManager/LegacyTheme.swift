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
    var rowBackground: UIColor { return UIColor(named: "TableViewColor.rowBackground")!  }
    var rowText: UIColor { return UIColor(named: "TableViewColor.rowText")!  }
    var rowDetailText: UIColor { return UIColor(named: "TableViewColor.rowDetailText")!  }
    var disabledRowText: UIColor { return UIColor(named: "TableViewColor.disabledRowText")!  }
    var separator: UIColor { return UIColor(named: "TableViewColor.separator")!  }
    var headerBackground: UIColor { return UIColor(named: "TableViewColor.headerBackground")!  }
    // Used for table headers in Settings and Photon menus
    var headerTextLight: UIColor { return UIColor(named: "TableViewColor.headerTextLight")!  }
    // Used for table headers in home panel tables
    var headerTextDark: UIColor { return UIColor(named: "TableViewColor.headerTextDark")!  }
    var rowActionAccessory: UIColor { return UIColor(named: "TableViewColor.rowActionAccessory")!  }
    var controlTint: UIColor { return UIColor(named: "TableViewColor.controlTint")!  }
    var syncText: UIColor { return UIColor(named: "TableViewColor.syncText")!  }
    var errorText: UIColor { return UIColor(named: "TableViewColor.errorText")!  }
    var warningText: UIColor { return UIColor(named: "TableViewColor.warningText")!  }
    var accessoryViewTint: UIColor { return UIColor(named: "TableViewColor.accessoryViewTint")!  }
    var selectedBackground: UIColor { return UIColor(named: "TableViewColor.selectedBackground")!  }
}

class ActionMenuColor {
    var foreground: UIColor { return UIColor(named: "ActionMenuColor.foreground")! }
    var iPhoneBackgroundBlurStyle: UIBlurEffect.Style { return UIBlurEffect.Style.light }
    var iPhoneBackground: UIColor { return UIColor(named: "ActionMenuColor.iPhoneBackground")! }
    var closeButtonBackground: UIColor { return UIColor(named: "ActionMenuColor.closeButtonBackground")! }
}

class URLBarColor {
    var border: UIColor { return UIColor(named: "URLBarColor.border")! }
    func activeBorder(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Blue20A40 : UIColor.Defaults.MobilePrivatePurple
    }
    var tint: UIColor { return UIColor(named: "URLBarColor.tint")! }

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
            return (labelMode: UIColor(named: "URLBarColor.textSelectionHighlight")!, textFieldMode: nil)
        }
    }

    var readerModeButtonSelected: UIColor { return UIColor(named: "URLBarColor.readerModeButtonSelected")! }
    var readerModeButtonUnselected: UIColor { return UIColor(named: "URLBarColor.readerModeButtonUnselected")! }
    var pageOptionsSelected: UIColor { return UIColor(named: "URLBarColor.pageOptionsSelected")! }
    var pageOptionsUnselected: UIColor { return UIColor(named: "URLBarColor.pageOptionsUnselected")! }
}

class BrowserColor {
    var background: UIColor { return UIColor(named: "BrowserColor.background")! }
    var urlBarDivider: UIColor { return UIColor(named: "BrowserColor.urlBarDivider")! }
    var tint: UIColor { return UIColor(named: "BrowserColor.tint")! }
}

// The back/forward/refresh/menu button (bottom toolbar)
class ToolbarButtonColor {
    var selectedTint: UIColor { return UIColor(named: "ToolbarButtonColor.selectedTint")! }
    var disabledTint: UIColor { return UIColor(named: "ToolbarButtonColor.disabledTint")! }
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
    var tabTitleText: UIColor { return UIColor(named: "TabTrayColor.tabTitleText")! }
    var tabTitleBlur: UIBlurEffect.Style { return UIBlurEffect.Style.extraLight }
    var background: UIColor { return UIColor(named: "TabTrayColor.background")! }
    var screenshotBackground: UIColor { return UIColor(named: "TabTrayColor.screenshotBackground")! }
    var cellBackground: UIColor { return UIColor(named: "TabTrayColor.cellBackground")! }
    var toolbar: UIColor { return UIColor(named: "TabTrayColor.toolbar")! }
    var toolbarButtonTint: UIColor { return UIColor(named: "TabTrayColor.toolbarButtonTint")! }
    var privateModeLearnMore: UIColor { return UIColor(named: "TabTrayColor.privateModeLearnMore")! }
    var privateModePurple: UIColor { return UIColor(named: "TabTrayColor.privateModePurple")! }
    var privateModeButtonOffTint: UIColor { return UIColor(named: "TabTrayColor.privateModeButtonOffTint")! }
    var privateModeButtonOnTint: UIColor { return UIColor(named: "TabTrayColor.privateModeButtonOnTint")! }
    var cellCloseButton: UIColor { return UIColor(named: "TabTrayColor.cellCloseButton")! }
    var cellTitleBackground: UIColor { return UIColor(named: "TabTrayColor.cellTitleBackground")! }
    var faviconTint: UIColor { return UIColor(named: "TabTrayColor.faviconTint")! }
    var searchBackground: UIColor { return UIColor(named: "TabTrayColor.searchBackground")! }
}

class EnhancedTrackingProtectionMenuColor {
    var defaultImageTints: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.defaultImageTints")! }
    var background: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.background")! }
    var horizontalLine: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.horizontalLine")! }
    var sectionColor: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.sectionColor")! }
    var switchAndButtonTint: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.switchAndButtonTint")! }
    var subtextColor: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.subtextColor")! }
    var closeButtonColor: UIColor { return UIColor(named: "EnhancedTrackingProtectionMenuColor.closeButtonColor")! }
}

class TopTabsColor {
    var background: UIColor { return UIColor(named: "TopTabsColor.background")! }
    var tabBackgroundSelected: UIColor { return UIColor(named: "TopTabsColor.tabBackgroundSelected")! }
    var tabBackgroundUnselected: UIColor { return UIColor(named: "TopTabsColor.tabBackgroundUnselected")! }
    var tabForegroundSelected: UIColor { return UIColor(named: "TopTabsColor.tabForegroundSelected")! }
    var tabForegroundUnselected: UIColor { return UIColor(named: "TopTabsColor.tabForegroundUnselected")! }
    func tabSelectedIndicatorBar(_ isPrivate: Bool) -> UIColor {
        return !isPrivate ? UIColor.Photon.Blue40 : UIColor.Photon.Purple60
    }
    var buttonTint: UIColor { return UIColor(named: "TopTabsColor.buttonTint")! }
    var privateModeButtonOffTint: UIColor { return UIColor(named: "TopTabsColor.privateModeButtonOffTint")! }
    var privateModeButtonOnTint: UIColor { return UIColor(named: "TopTabsColor.privateModeButtonOnTint")! }
    var closeButtonSelectedTab: UIColor { return UIColor(named: "TopTabsColor.closeButtonSelectedTab")! }
    var closeButtonUnselectedTab: UIColor { return UIColor(named: "TopTabsColor.closeButtonUnselectedTab")! }
    var separator: UIColor { return UIColor(named: "TopTabsColor.separator")! }
}

class TextFieldColor {
    var background: UIColor { return UIColor(named: "TextFieldColor.background")! }
    var backgroundInOverlay: UIColor { return UIColor(named: "TextFieldColor.backgroundInOverlay")!}
    var textAndTint: UIColor { return UIColor(named: "TextFieldColor.textAndTint")! }
    var separator: UIColor { return UIColor(named: "TextFieldColor.separator")! }
}

class HomePanelColor {
    var toolbarBackground: UIColor { return UIColor(named: "HomePanelColor.toolbarBackground")! }
    var toolbarHighlight: UIColor { return UIColor(named: "HomePanelColor.toolbarHighlight")! }
    var toolbarTint: UIColor { return UIColor(named: "HomePanelColor.toolbarTint")! }
    var topSiteHeaderTitle: UIColor { return UIColor(named: "HomePanelColor.topSiteHeaderTitle")! }
    var panelBackground: UIColor { return UIColor(named: "HomePanelColor.panelBackground")! }

    var separator: UIColor { return UIColor(named: "HomePanelColor.separator")! }
    var border: UIColor { return UIColor(named: "HomePanelColor.border")! }
    var buttonContainerBorder: UIColor { return UIColor(named: "HomePanelColor.buttonContainerBorder")! }

    var welcomeScreenText: UIColor { return UIColor(named: "HomePanelColor.welcomeScreenText")! }
    var bookmarkIconBorder: UIColor { return UIColor(named: "HomePanelColor.bookmarkIconBorder")! }
    var bookmarkFolderBackground: UIColor { return UIColor(named: "HomePanelColor.bookmarkFolderBackground")! }
    var bookmarkFolderText: UIColor { return UIColor(named: "HomePanelColor.bookmarkFolderText")! }
    var bookmarkCurrentFolderText: UIColor { return UIColor(named: "HomePanelColor.bookmarkCurrentFolderText")! }
    var bookmarkBackNavCellBackground: UIColor { return UIColor(named: "HomePanelColor.bookmarkBackNavCellBackground")! }

    var siteTableHeaderBorder: UIColor { return UIColor(named: "HomePanelColor.siteTableHeaderBorder")! }

    var topSiteDomain: UIColor { return UIColor(named: "HomePanelColor.topSiteDomain")! }
    var topSitePin: UIColor { return UIColor(named: "HomePanelColor.topSitePin")! }
    var topSitesBackground: UIColor { return UIColor(named: "HomePanelColor.topSitesBackground")! }

    var shortcutBackground: UIColor { return UIColor(named: "HomePanelColor.shortcutBackground")! }
    var shortcutShadowColor: CGColor { return UIColor(named: "HomePanelColor.shortcutShadowColor")!.cgColor }
    var shortcutShadowOpacity: Float { return 0.2 }

    var recentlySavedBookmarkCellBackground: UIColor { return UIColor(named: "HomePanelColor.recentlySavedBookmarkCellBackground")! }

    var recentlyVisitedCellGroupImage: UIColor { return UIColor(named: "HomePanelColor.recentlyVisitedCellGroupImage")! }
    var recentlyVisitedCellBottomLine: UIColor { return UIColor(named: "HomePanelColor.recentlyVisitedCellBottomLine")! }

    var activityStreamHeaderText: UIColor { return UIColor(named: "HomePanelColor.activityStreamHeaderText")! }
    var activityStreamHeaderButton: UIColor { return UIColor(named: "HomePanelColor.activityStreamHeaderButton")! }
    var activityStreamCellTitle: UIColor { return UIColor(named: "HomePanelColor.activityStreamCellTitle")! }
    var activityStreamCellDescription: UIColor { return UIColor(named: "HomePanelColor.activityStreamCellDescription")!}

    var readingListActive: UIColor { return UIColor(named: "HomePanelColor.readingListActive")! }
    var readingListDimmed: UIColor { return UIColor(named: "HomePanelColor.readingListDimmed")! }

    var downloadedFileIcon: UIColor { return UIColor(named: "HomePanelColor.downloadedFileIcon")! }

    var historyHeaderIconsBackground: UIColor { return UIColor(named: "HomePanelColor.historyHeaderIconsBackground")! }

    var searchSuggestionPillBackground: UIColor { return UIColor(named: "HomePanelColor.searchSuggestionPillBackground")! }
    var searchSuggestionPillForeground: UIColor { return UIColor(named: "HomePanelColor.searchSuggestionPillForeground")! }

    var customizeHomepageButtonBackground: UIColor { return UIColor(named: "HomePanelColor.customizeHomepageButtonBackground")! }
    var customizeHomepageButtonText: UIColor { return UIColor(named: "HomePanelColor.customizeHomepageButtonText")! }
}

class SnackBarColor {
    var highlight: UIColor { return UIColor.Defaults.iOSTextHighlightBlue.withAlphaComponent(0.9) }
    var highlightText: UIColor { return UIColor(named: "SnackBarColor.highlightText")! }
    var border: UIColor { return UIColor(named: "SnackBarColor.border")! }
    var title: UIColor { return UIColor(named: "SnackBarColor.title")! }
}

class GeneralColor {
    var faviconBackground: UIColor { return UIColor(named: "GeneralColor.faviconBackground")! }
    var passcodeDot: UIColor { return UIColor(named: "GeneralColor.passcodeDot")! }
    var highlightBlue: UIColor { return UIColor(named: "GeneralColor.highlightBlue")! }
    var destructiveRed: UIColor { return UIColor(named: "GeneralColor.destructiveRed")! }
    var separator: UIColor { return UIColor(named: "GeneralColor.separator")! }
    var settingsTextPlaceholder: UIColor { return UIColor(named: "GeneralColor.settingsTextPlaceholder")! }
    var controlTint: UIColor { return UIColor(named: "GeneralColor.controlTint")! }
    var switchToggle: UIColor { return UIColor(named: "GeneralColor.switchToggle")! }
}

class HomeTabBannerColor {
    var backgroundColor: UIColor { return UIColor(named: "HomeTabBannerColor.backgroundColor")!  }
    var textColor: UIColor { return UIColor(named: "HomeTabBannerColor.textColor")!  }
    var closeButtonBackground: UIColor { return UIColor(named: "HomeTabBannerColor.closeButtonBackground")! }
    var closeButton: UIColor { return UIColor(named: "HomeTabBannerColor.closeButton")! }
}

class OnboardingColor {
    var backgroundColor: UIColor { return UIColor(named: "OnboardingColor.backgroundColor")! }
}

class RemoteTabTrayColor {
    var background: UIColor { return UIColor(named: "RemoteTabTrayColor.background")! }
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
