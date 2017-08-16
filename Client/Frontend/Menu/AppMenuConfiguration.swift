/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AVFoundation
import Shared

enum AppMenuAction: String {
    case openNewNormalTab = "OpenNewNormalTab"
    case openNewPrivateTab = "OpenNewPrivateTab"
    case findInPage = "FindInPage"
    case toggleBrowsingMode = "ToggleBrowsingMode"
    case toggleBookmarkStatus = "ToggleBookmarkStatus"
    case openSettings = "OpenSettings"
    case closeAllTabs = "CloseAllTabs"
    case openHomePage = "OpenHomePage"
    case setHomePage = "SetHomePage"
    case sharePage = "SharePage"
    case openTopSites = "OpenTopSites"
    case openBookmarks = "OpenBookmarks"
    case openHistory = "OpenHistory"
    case openReadingList = "OpenReadingList"
    case showImageMode = "ShowImageMode"
    case hideImageMode = "HideImageMode"
    case showNightMode = "ShowNightMode"
    case hideNightMode = "HideNightMode"
    case scanQRCode = "ScanQRCode"
}

struct AppMenuConfiguration: MenuConfiguration {

    internal fileprivate(set) var menuItems = [MenuItem]()
    internal fileprivate(set) var menuToolbarItems: [MenuToolbarItem]?
    internal fileprivate(set) var numberOfItemsInRow: Int = 0

    fileprivate(set) var isPrivateMode: Bool = false

    private let hasVideoCaptureDevice: Bool = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) != nil

    init(appState: AppState) {
        menuItems = menuItemsForAppState(appState)
        menuToolbarItems = menuToolbarItemsForAppState(appState)
        numberOfItemsInRow = numberOfMenuItemsPerRowForAppState(appState)
        isPrivateMode = appState.ui.isPrivate()
    }

    func menuForState(_ appState: AppState) -> MenuConfiguration {
        return AppMenuConfiguration(appState: appState)
    }

    func toolbarColor() -> UIColor {

        return isPrivateMode ? UIConstants.MenuToolbarBackgroundColorPrivate : UIConstants.MenuToolbarBackgroundColorNormal
    }

    func toolbarTintColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuToolbarTintColorNormal
    }

    func menuBackgroundColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuBackgroundColorPrivate : UIConstants.MenuBackgroundColorNormal
    }

    func menuTintColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuBackgroundColorPrivate
    }

    func menuFont() -> UIFont {
        return UIFont.systemFont(ofSize: 11)
    }

    func menuIcon() -> UIImage? {
        return isPrivateMode ? UIImage(named:"bottomNav-menu-pbm") : UIImage(named:"bottomNav-menu")
    }

    func minMenuRowHeight() -> CGFloat {
        return 65.0
    }

    func shadowColor() -> UIColor {
        return isPrivateMode ? UIColor.darkGray : UIColor.lightGray
    }

    func selectedItemTintColor() -> UIColor {
        return UIConstants.MenuSelectedItemTintColor
    }
    
    func disabledItemTintColor() -> UIColor {
        return UIConstants.MenuDisabledItemTintColor
    }

    fileprivate func numberOfMenuItemsPerRowForAppState(_ appState: AppState) -> Int {
        switch appState.ui {
        case .tabTray:
            return 4
        default:
            return 3
        }
    }

    // the items should be added to the array according to desired display order
    fileprivate func menuItemsForAppState(_ appState: AppState) -> [MenuItem] {
        var menuItems = [MenuItem]()
        switch appState.ui {
        case .tab(let tabState):
//            menuItems.append(AppMenuConfiguration.FindInPageMenuItem)
//            menuItems.append(tabState.desktopSite ? AppMenuConfiguration.RequestMobileMenuItem : AppMenuConfiguration.RequestDesktopMenuItem)
//
//            if !HomePageAccessors.isButtonInMenu(appState) {
//                menuItems.append(AppMenuConfiguration.SharePageMenuItem)
//            } else if HomePageAccessors.hasHomePage(appState) {
//                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
//            } else {
//                var homePageMenuItem = AppMenuConfiguration.SetHomePageMenuItem
//                if let url = tabState.url, !url.isWebPage(includeDataURIs: true) || url.isLocal {
//                    homePageMenuItem.isDisabled = true
//                }
//                menuItems.append(homePageMenuItem)
//            }
//            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
//            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
//            var bookmarkMenuItem = tabState.isBookmarked ? AppMenuConfiguration.RemoveBookmarkMenuItem : AppMenuConfiguration.AddBookmarkMenuItem
//            if let url = tabState.url, !url.isWebPage(includeDataURIs: true) || url.isLocal {
//                bookmarkMenuItem.isDisabled = true
//            }
//            menuItems.append(bookmarkMenuItem)
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            if hasVideoCaptureDevice {
                menuItems.append(AppMenuConfiguration.ScanQRCodeMenuItem)
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .homePanels:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            if HomePageAccessors.isButtonInMenu(appState) && HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            }
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            if hasVideoCaptureDevice {
                menuItems.append(AppMenuConfiguration.ScanQRCodeMenuItem)
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .emptyTab, .loading:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            if HomePageAccessors.isButtonInMenu(appState) && HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            }
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            if hasVideoCaptureDevice {
                menuItems.append(AppMenuConfiguration.ScanQRCodeMenuItem)
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .tabTray:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            menuItems.append(AppMenuConfiguration.CloseAllTabsMenuItem)
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        }
        return menuItems
    }

    // the items should be added to the array according to desired display order
    fileprivate func menuToolbarItemsForAppState(_ appState: AppState) -> [MenuToolbarItem]? {
        let menuToolbarItems: [MenuToolbarItem]?
        switch appState.ui {
        case .tab, .tabTray:
            menuToolbarItems = [AppMenuConfiguration.TopSitesMenuToolbarItem,
                                AppMenuConfiguration.BookmarksMenuToolbarItem,
                                AppMenuConfiguration.HistoryMenuToolbarItem,
                                AppMenuConfiguration.ReadingListMenuToolbarItem]
        default:
            menuToolbarItems = nil
        }
        return menuToolbarItems
    }
}

// MARK: Static helper access function

extension AppMenuConfiguration {

    fileprivate static var NewTabMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNewTabTitleString, accessibilityIdentifier: "NewTabMenuItem", action: MenuAction(action: AppMenuAction.openNewNormalTab.rawValue), icon: "menu-NewTab", privateModeIcon: "menu-NewTab-pbm")
    }

    fileprivate static var NewPrivateTabMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNewPrivateTabTitleString, accessibilityIdentifier: "NewPrivateTabMenuItem", action:  MenuAction(action: AppMenuAction.openNewPrivateTab.rawValue), icon: "menu-NewPrivateTab", privateModeIcon: "menu-NewPrivateTab-pbm")
    }

    fileprivate static var AddBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuAddBookmarkTitleString, accessibilityIdentifier: "AddBookmarkMenuItem", action:  MenuAction(action: AppMenuAction.toggleBookmarkStatus.rawValue), icon: "menu-Bookmark", privateModeIcon: "menu-Bookmark-pbm", selectedIcon: "menu-RemoveBookmark", animation: JumpAndSpinAnimator())
    }

    fileprivate static var RemoveBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuRemoveBookmarkTitleString, accessibilityIdentifier: "RemoveBookmarkMenuItem", action:  MenuAction(action: AppMenuAction.toggleBookmarkStatus.rawValue), icon: "menu-RemoveBookmark", privateModeIcon: "menu-RemoveBookmark")
    }

    fileprivate static var FindInPageMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuFindInPageTitleString, accessibilityIdentifier: "FindInPageMenuItem", action:  MenuAction(action: AppMenuAction.findInPage.rawValue), icon: "menu-FindInPage", privateModeIcon: "menu-FindInPage-pbm")
    }

    fileprivate static var RequestDesktopMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuViewDesktopSiteTitleString, accessibilityIdentifier: "RequestDesktopMenuItem", action:  MenuAction(action: AppMenuAction.toggleBrowsingMode.rawValue), icon: "menu-RequestDesktopSite", privateModeIcon: "menu-RequestDesktopSite-pbm")
    }

    fileprivate static var RequestMobileMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuViewMobileSiteTitleString, accessibilityIdentifier: "RequestMobileMenuItem", action:  MenuAction(action: AppMenuAction.toggleBrowsingMode.rawValue), icon: "menu-ViewMobile", privateModeIcon: "menu-ViewMobile-pbm")
    }

    fileprivate static var HideImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNoImageModeTurnOnLabel, accessibilityIdentifier: "HideImageModeMenuItem", action:  MenuAction(action: AppMenuAction.hideImageMode.rawValue), icon: "menu-NoImageMode", privateModeIcon: "menu-NoImageMode-pbm")
    }

    fileprivate static var ShowImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNoImageModeTurnOffLabel, accessibilityIdentifier: "ShowImageModeMenuItem", action:  MenuAction(action: AppMenuAction.showImageMode.rawValue), icon: "menu-NoImageMode-Engaged", privateModeIcon: "menu-NoImageMode-Engaged")
   }
 
    fileprivate static var HideNightModeItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNightModeTurnOnLabel, accessibilityIdentifier: "HideNightModeItem", action:  MenuAction(action: AppMenuAction.hideNightMode.rawValue), icon: "menu-NightMode", privateModeIcon: "menu-NightMode-pbm")
    }

    fileprivate static var ShowNightModeItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuNightModeTurnOffLabel, accessibilityIdentifier: "ShowNightModeItem", action:  MenuAction(action: AppMenuAction.showNightMode.rawValue), icon: "menu-NightMode-Engaged", privateModeIcon: "menu-NightMode-Engaged")
    }

    fileprivate static var ScanQRCodeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuScanQRCodeTitleString, accessibilityIdentifier: "ScanQRCodeMenuItem", action: MenuAction(action: AppMenuAction.scanQRCode.rawValue), icon: "menu-ScanQRCode", privateModeIcon: "menu-ScanQRCode-pbm", selectedIcon: "menu-ScanQRCode-Engaged")
    }

    fileprivate static var SettingsMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuSettingsTitleString, accessibilityIdentifier: "SettingsMenuItem", action:  MenuAction(action: AppMenuAction.openSettings.rawValue), icon: "menu-Settings", privateModeIcon: "menu-Settings-pbm")
    }

    fileprivate static var CloseAllTabsMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuCloseAllTabsTitleString, accessibilityIdentifier: "CloseAllTabsMenuItem", action:  MenuAction(action: AppMenuAction.closeAllTabs.rawValue), icon: "menu-CloseTabs", privateModeIcon: "menu-CloseTabs-pbm")
    }

    fileprivate static var OpenHomePageMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuOpenHomePageTitleString, accessibilityIdentifier: "OpenHomePageMenuItem", action: MenuAction(action: AppMenuAction.openHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    fileprivate static var SetHomePageMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuSetHomePageTitleString, accessibilityIdentifier: "SetHomePageMenuItem", action: MenuAction(action: AppMenuAction.setHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    fileprivate static var SharePageMenuItem: MenuItem {
        return AppMenuItem(title: Strings.AppMenuSharePageTitleString, accessibilityIdentifier: "SharePageMenuItem", action: MenuAction(action: AppMenuAction.sharePage.rawValue), icon: "menu-Send", privateModeIcon: "menu-Send-pbm", selectedIcon: "menu-Send-Engaged")
    }

    fileprivate static var TopSitesMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: Strings.AppMenuTopSitesTitleString, accessibilityIdentifier: "TopSitesMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openTopSites.rawValue), icon: "menu-panel-TopSites")
    }

    fileprivate static var BookmarksMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: Strings.AppMenuBookmarksTitleString, accessibilityIdentifier: "BookmarksMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openBookmarks.rawValue), icon: "menu-panel-Bookmarks")
    }

    fileprivate static var HistoryMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: Strings.AppMenuHistoryTitleString, accessibilityIdentifier: "HistoryMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openHistory.rawValue), icon: "menu-panel-History")
    }

    fileprivate static var ReadingListMenuToolbarItem: MenuToolbarItem {
        return  AppMenuToolbarItem(title: Strings.AppMenuReadingListTitleString, accessibilityIdentifier: "ReadingListMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openReadingList.rawValue), icon: "menu-panel-ReadingList")
    }


}
