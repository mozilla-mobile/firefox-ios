// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// Convenience reference to these normal mode colors which are used in a few color classes.
private let defaultBackground = UIColor.Photon.DarkGrey60
private let defaultSeparator = UIColor.Photon.Grey60
private let defaultTextAndTint = UIColor.Photon.Grey10

private class DarkTableViewColor: TableViewColor {
    override var rowBackground: UIColor {
        UIColor.Photon.Grey70
    }
    override var rowText: UIColor {
        defaultTextAndTint
    }
    override var rowDetailText: UIColor {
        UIColor.Photon.Grey30
    }
    override var disabledRowText: UIColor {
        UIColor.Photon.Grey40
    }
    override var separator: UIColor {
        UIColor.Photon.Grey60
    }
    override var headerBackground: UIColor {
        UIColor.Photon.Grey80
    }
    override var headerTextLight: UIColor {
        UIColor.Photon.Grey30
    }
    override var headerTextDark: UIColor {
        UIColor.Photon.Grey30
    }
    override var syncText: UIColor {
        defaultTextAndTint
    }
    override var accessoryViewTint: UIColor {
        UIColor.Photon.Grey40
    }
    override var selectedBackground: UIColor {
        UIColor.Custom.selectedHighlightDark
    }
}

private class DarkActionMenuColor: ActionMenuColor {
    override var foreground: UIColor {
        UIColor.Photon.White100
    }
    override var iPhoneBackgroundBlurStyle: UIBlurEffect.Style {
        UIBlurEffect.Style.dark
    }
    override var iPhoneBackground: UIColor {
        defaultBackground.withAlphaComponent(0.9)
    }
    override var closeButtonBackground: UIColor {
        defaultBackground
    }
}

private class DarkURLBarColor: URLBarColor {
    override func textSelectionHighlight(_ isPrivate: Bool) -> TextSelectionHighlight {
        let color = isPrivate ? UIColor.Defaults.MobilePrivatePurple : UIColor(rgb: 0x3d89cc)
        return (labelMode: color.withAlphaComponent(0.25), textFieldMode: color)

    }

    override func activeBorder(_ isPrivate: Bool) -> UIColor {
        !isPrivate ? UIColor.Photon.Blue20A40 : UIColor.Defaults.MobilePrivatePurple
    }
}

private class DarkBrowserColor: BrowserColor {
    override var background: UIColor {
        defaultBackground
    }
    override var tint: UIColor {
        defaultTextAndTint
    }
}

// The back/forward/refresh/menu button (bottom toolbar)
private class DarkToolbarButtonColor: ToolbarButtonColor {

}

private class DarkTabTrayColor: TabTrayColor {
    override var tabTitleText: UIColor {
        defaultTextAndTint
    }
    override var tabTitleBlur: UIBlurEffect.Style {
        UIBlurEffect.Style.dark
    }
    override var background: UIColor {
        UIColor.Photon.DarkGrey80
    }
    override var screenshotBackground: UIColor {
        UIColor.Photon.DarkGrey30
    }
    override var cellBackground: UIColor {
        defaultBackground
    }
    override var toolbar: UIColor {
        UIColor.Photon.Grey80
    }
    override var toolbarButtonTint: UIColor {
        defaultTextAndTint
    }
    override var cellCloseButton: UIColor {
        defaultTextAndTint
    }
    override var cellTitleBackground: UIColor {
        UIColor.Photon.Grey70
    }
    override var faviconTint: UIColor {
        UIColor.Photon.White100
    }
    override var searchBackground: UIColor {
        UIColor.Photon.Grey60
    }
}

private class DarkEnhancedTrackingProtectionMenuColor: EnhancedTrackingProtectionMenuColor {
    override var defaultImageTints: UIColor {
        defaultTextAndTint
    }
    override var background: UIColor {
        UIColor.Photon.DarkGrey80
    }
    override var sectionColor: UIColor {
        UIColor.Photon.DarkGrey65
    }
    override var switchAndButtonTint: UIColor {
        UIColor.Photon.Blue20
    }
    override var subtextColor: UIColor {
        UIColor.Photon.LightGrey05
    }
    override var closeButtonColor: UIColor {
        UIColor.Photon.DarkGrey65
    }
}

private class DarkTopTabsColor: TopTabsColor {
    override var background: UIColor { UIColor.Photon.DarkGrey80 }
    override var tabBackgroundSelected: UIColor {
        UIColor.Photon.DarkGrey30
    }
    override var tabBackgroundUnselected: UIColor {
        UIColor.Photon.Grey80
    }
    override var tabForegroundSelected: UIColor {
        UIColor.Photon.Grey10
    }
    override var tabForegroundUnselected: UIColor {
        UIColor.Photon.Grey40
    }
    override var closeButtonSelectedTab: UIColor {
        tabForegroundSelected
    }
    override var closeButtonUnselectedTab: UIColor {
        tabForegroundUnselected
    }
    override var separator: UIColor {
        UIColor.Photon.Grey50
    }
    override var buttonTint: UIColor {
        UIColor.Photon.Grey10
    }
}

private class DarkTextFieldColor: TextFieldColor {
    override var background: UIColor {
        UIColor.Photon.DarkGrey80
    }
    override var backgroundInOverlay: UIColor {
        self.background
    }

    override var textAndTint: UIColor {
        defaultTextAndTint
    }
    override var separator: UIColor {
        super.separator.withAlphaComponent(0.3)
    }
}

private class DarkHomePanelColor: HomePanelColor {
    override var toolbarBackground: UIColor {
        defaultBackground
    }
    override var toolbarHighlight: UIColor {
        UIColor.Photon.Blue20
    }
    override var toolbarTint: UIColor {
        UIColor.Photon.Grey30
    }
    override var topSiteHeaderTitle: UIColor {
        UIColor.Photon.White100
    }
    override var panelBackground: UIColor {
        UIColor.Photon.Grey80
    }
    override var separator: UIColor {
        defaultSeparator
    }
    override var border: UIColor {
        UIColor.Photon.Grey60
    }
    override var buttonContainerBorder: UIColor {
        separator
    }

    override var welcomeScreenText: UIColor {
        UIColor.Photon.Grey30
    }
    override var bookmarkIconBorder: UIColor {
        UIColor.Photon.Grey30
    }
    override var bookmarkFolderBackground: UIColor {
        UIColor.Photon.Grey80
    }
    override var bookmarkFolderText: UIColor {
        UIColor.Photon.White100
    }
    override var bookmarkCurrentFolderText: UIColor {
        UIColor.Photon.White100
    }
    override var bookmarkBackNavCellBackground: UIColor {
        UIColor.Photon.Grey70
    }

    override var activityStreamHeaderText: UIColor {
        UIColor.Photon.LightGrey05
    }
    override var activityStreamHeaderButton: UIColor {
        UIColor.Photon.Blue20
    }
    override var activityStreamCellTitle: UIColor {
        UIColor.Photon.LightGrey05
    }
    override var activityStreamCellDescription: UIColor {
        UIColor.Photon.LightGrey50
    }

    override var topSiteDomain: UIColor {
        UIColor.Photon.LightGrey05
    }
    override var topSitePin: UIColor {
        UIColor.Photon.LightGrey05
    }
    override var topSitesBackground: UIColor {
        UIColor.Photon.DarkGrey60
    }

    override var shortcutBackground: UIColor {
        UIColor.Photon.DarkGrey30
    }
    override var shortcutShadowColor: CGColor {
        UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0).cgColor
    }
    override var shortcutShadowOpacity: Float {
        0.5
    }

    override var recentlySavedBookmarkCellBackground: UIColor {
        UIColor.Photon.DarkGrey30
    }

    override var recentlyVisitedCellGroupImage: UIColor {
        .white
    }

    override var downloadedFileIcon: UIColor {
        UIColor.Photon.Grey30
    }

    override var historyHeaderIconsBackground: UIColor {
        UIColor.clear
    }

    override var readingListActive: UIColor {
        UIColor.Photon.Grey10
    }
    override var readingListDimmed: UIColor {
        UIColor.Photon.Grey40
    }

    override var searchSuggestionPillBackground: UIColor {
        UIColor.Photon.Grey70
    }
    override var searchSuggestionPillForeground: UIColor {
        defaultTextAndTint
    }

    override var customizeHomepageButtonBackground: UIColor {
        UIColor.Photon.DarkGrey50
    }
    override var customizeHomepageButtonText: UIColor {
        UIColor.Photon.LightGrey10
    }

    override var sponsored: UIColor {
        UIColor.Photon.LightGrey40
    }
}

private class DarkSnackBarColor: SnackBarColor {
// Use defaults
}

private class DarkGeneralColor: GeneralColor {
    override var settingsTextPlaceholder: UIColor {
        UIColor.Photon.Grey40
    }
    override var faviconBackground: UIColor {
        UIColor.Photon.White100
    }
    override var passcodeDot: UIColor {
        UIColor.Photon.Grey40
    }
    override var switchToggle: UIColor {
        UIColor.Photon.Grey40
    }
}

class DarkHomeTabBannerColor: HomeTabBannerColor {
    override var backgroundColor: UIColor {
        UIColor.Photon.Grey60
    }
    override var textColor: UIColor {
        UIColor.white
    }
    override var closeButtonBackground: UIColor {
        UIColor.Photon.Grey80
    }
    override var closeButton: UIColor {
        UIColor.Photon.Grey20
    }
}

class DarkOnboardingColor: OnboardingColor {
    override var backgroundColor: UIColor {
        UIColor.Photon.Grey90
    }
}

class DarkRemoteTabTrayColor: RemoteTabTrayColor {
    override var background: UIColor {
        UIColor.Photon.Grey70
    }
}

class DarkTheme: NormalTheme {
    override var name: String {
        BuiltinThemeName.dark.rawValue
    }
    override var tableView: TableViewColor {
        DarkTableViewColor()
    }
    override var urlbar: URLBarColor {
        DarkURLBarColor()
    }
    override var browser: BrowserColor {
        DarkBrowserColor()
    }
    override var toolbarButton: ToolbarButtonColor {
        DarkToolbarButtonColor()
    }
    override var tabTray: TabTrayColor {
        DarkTabTrayColor()
    }
    override var etpMenu: EnhancedTrackingProtectionMenuColor {
        DarkEnhancedTrackingProtectionMenuColor()
    }
    override var topTabs: TopTabsColor {
        DarkTopTabsColor()
    }
    override var textField: TextFieldColor {
        DarkTextFieldColor()
    }
    override var homePanel: HomePanelColor {
        DarkHomePanelColor()
    }
    override var snackbar: SnackBarColor {
        DarkSnackBarColor()
    }
    override var general: GeneralColor {
        DarkGeneralColor()
    }
    override var actionMenu: ActionMenuColor {
        DarkActionMenuColor()
    }
    override var homeTabBanner: HomeTabBannerColor {
        DarkHomeTabBannerColor()
    }
    override var onboarding: OnboardingColor {
        DarkOnboardingColor()
    }
    override var remotePanel: RemoteTabTrayColor {
        DarkRemoteTabTrayColor()
    }
}
