/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

enum AppMenuAction: String {
    case OpenNewNormalTab = "OpenNewNormalTab"
    case OpenNewPrivateTab = "OpenNewPrivateTab"
    case FindInPage = "FindInPage"
    case ToggleBrowsingMode = "ToggleBrowsingMode"
    case ToggleBookmarkStatus = "ToggleBookmarkStatus"
    case OpenSettings = "OpenSettings"
    case CloseAllTabs = "CloseAllTabs"
    case OpenHomePage = "OpenHomePage"
    case SetHomePage = "SetHomePage"
    case SharePage = "SharePage"
    case OpenTopSites = "OpenTopSites"
    case OpenBookmarks = "OpenBookmarks"
    case OpenHistory = "OpenHistory"
    case OpenReadingList = "OpenReadingList"
    case ShowImageMode = "ShowImageMode"
    case HideImageMode = "HideImageMode"
    case ShowNightMode = "ShowNightMode"
    case HideNightMode = "HideNightMode"
}

struct AppMenuConfiguration: MenuConfiguration {

    internal private(set) var menuItems = [MenuItem]()
    internal private(set) var menuToolbarItems: [MenuToolbarItem]?
    internal private(set) var numberOfItemsInRow: Int = 0

    private(set) var isPrivateMode: Bool = false

    init(appState: AppState) {
        menuItems = menuItems(forAppState: appState)
        menuToolbarItems = menuToolbarItems(forAppState: appState)
        numberOfItemsInRow = numberOfMenuItemsPerRow(forAppState: appState)
        isPrivateMode = appState.ui.isPrivate()
    }

    func menu(forState appState: AppState) -> MenuConfiguration {
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
        return isPrivateMode ? UIColor.darkGray() : UIColor.lightGray()
    }

    func selectedItemTintColor() -> UIColor {
        return UIConstants.MenuSelectedItemTintColor
    }

    private func numberOfMenuItemsPerRow(forAppState appState: AppState) -> Int {
        switch appState.ui {
        case .tabTray:
            return 4
        default:
            return 3
        }
    }

    // the items should be added to the array according to desired display order
    private func menuItems(forAppState appState: AppState) -> [MenuItem] {
        var menuItems = [MenuItem]()
        switch appState.ui {
        case .tab(let tabState):
            menuItems.append(AppMenuConfiguration.FindInPageMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(tabState.desktopSite ? AppMenuConfiguration.RequestMobileMenuItem : AppMenuConfiguration.RequestDesktopMenuItem)
            }

            if !HomePageAccessors.isButtonInMenu(appState) {
                menuItems.append(AppMenuConfiguration.SharePageMenuItem)
            } else if HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            } else {
                menuItems.append(AppMenuConfiguration.SetHomePageMenuItem)
            }
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
            menuItems.append(tabState.isBookmarked ? AppMenuConfiguration.RemoveBookmarkMenuItem : AppMenuConfiguration.AddBookmarkMenuItem)
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
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .homePanels, .loading:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
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
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .tabTray:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
            menuItems.append(AppMenuConfiguration.CloseAllTabsMenuItem)
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        }
        return menuItems
    }

    // the items should be added to the array according to desired display order
    private func menuToolbarItems(forAppState appState: AppState) -> [MenuToolbarItem]? {
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

    private static var NewTabMenuItem: MenuItem {
        return AppMenuItem(title: NewTabTitleString, action: MenuAction(action: AppMenuAction.OpenNewNormalTab.rawValue), icon: "menu-NewTab", privateModeIcon: "menu-NewTab-pbm")
    }

    @available(iOS 9, *)
    private static var NewPrivateTabMenuItem: MenuItem {
        return AppMenuItem(title: NewPrivateTabTitleString, action:  MenuAction(action: AppMenuAction.OpenNewPrivateTab.rawValue), icon: "menu-NewPrivateTab", privateModeIcon: "menu-NewPrivateTab-pbm")
    }

    private static var AddBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: AddBookmarkTitleString, action:  MenuAction(action: AppMenuAction.ToggleBookmarkStatus.rawValue), icon: "menu-Bookmark", privateModeIcon: "menu-Bookmark-pbm", selectedIcon: "menu-RemoveBookmark", animation: JumpAndSpinAnimator())
    }

    private static var RemoveBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: RemoveBookmarkTitleString, action:  MenuAction(action: AppMenuAction.ToggleBookmarkStatus.rawValue), icon: "menu-RemoveBookmark", privateModeIcon: "menu-RemoveBookmark")
    }

    private static var FindInPageMenuItem: MenuItem {
        return AppMenuItem(title: FindInPageTitleString, action:  MenuAction(action: AppMenuAction.FindInPage.rawValue), icon: "menu-FindInPage", privateModeIcon: "menu-FindInPage-pbm")
    }

    @available(iOS 9, *)
    private static var RequestDesktopMenuItem: MenuItem {
        return AppMenuItem(title: ViewDesktopSiteTitleString, action:  MenuAction(action: AppMenuAction.ToggleBrowsingMode.rawValue), icon: "menu-RequestDesktopSite", privateModeIcon: "menu-RequestDesktopSite-pbm")
    }

    @available(iOS 9, *)
    private static var RequestMobileMenuItem: MenuItem {
        return AppMenuItem(title: ViewMobileSiteTitleString, action:  MenuAction(action: AppMenuAction.ToggleBrowsingMode.rawValue), icon: "menu-ViewMobile", privateModeIcon: "menu-ViewMobile-pbm")
    }

    private static var HideImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNoImageModeTurnOnTitleString, action:  MenuAction(action: AppMenuAction.HideImageMode.rawValue), icon: "menu-NoImageMode", privateModeIcon: "menu-NoImageMode-pbm")
    }

    private static var ShowImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNoImageModeTurnOffTitleString, action:  MenuAction(action: AppMenuAction.ShowImageMode.rawValue), icon: "menu-NoImageMode-Engaged", privateModeIcon: "menu-NoImageMode-Engaged")
   }
 
    private static var HideNightModeItem : MenuItem {
        return AppMenuItem(title: Strings.MenuNightModeTurnOnTitleString, action:  MenuAction(action: AppMenuAction.HideNightMode.rawValue), icon: "menu-NightMode", privateModeIcon: "menu-NightMode-pbm")
    }

    private static var ShowNightModeItem : MenuItem {
        return AppMenuItem(title: Strings.MenuNightModeTurnOffTitleString, action:  MenuAction(action: AppMenuAction.ShowNightMode.rawValue), icon: "menu-NightMode-Engaged", privateModeIcon: "menu-NightMode-Engaged")
    }

    private static var SettingsMenuItem: MenuItem {
        return AppMenuItem(title: SettingsTitleString, action:  MenuAction(action: AppMenuAction.OpenSettings.rawValue), icon: "menu-Settings", privateModeIcon: "menu-Settings-pbm")
    }

    private static var CloseAllTabsMenuItem: MenuItem {
        return AppMenuItem(title: CloseAllTabsTitleString, action:  MenuAction(action: AppMenuAction.CloseAllTabs.rawValue), icon: "menu-CloseTabs", privateModeIcon: "menu-CloseTabs-pbm")
    }

    private static var OpenHomePageMenuItem: MenuItem {
        return AppMenuItem(title: OpenHomePageTitleString, action: MenuAction(action: AppMenuAction.OpenHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    private static var SetHomePageMenuItem: MenuItem {
        return AppMenuItem(title: SetHomePageTitleString, action: MenuAction(action: AppMenuAction.SetHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    private static var SharePageMenuItem: MenuItem {
        return AppMenuItem(title: SharePageTitleString, action: MenuAction(action: AppMenuAction.SharePage.rawValue), icon: "menu-Send", privateModeIcon: "menu-Send-pbm", selectedIcon: "menu-Send-Engaged")
    }

    private static var TopSitesMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: TopSitesTitleString, action:  MenuAction(action: AppMenuAction.OpenTopSites.rawValue), icon: "menu-panel-TopSites")
    }

    private static var BookmarksMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: BookmarksTitleString, action:  MenuAction(action: AppMenuAction.OpenBookmarks.rawValue), icon: "menu-panel-Bookmarks")
    }

    private static var HistoryMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: HistoryTitleString, action:  MenuAction(action: AppMenuAction.OpenHistory.rawValue), icon: "menu-panel-History")
    }

    private static var ReadingListMenuToolbarItem: MenuToolbarItem {
        return  AppMenuToolbarItem(title: ReadingListTitleString, action:  MenuAction(action: AppMenuAction.OpenReadingList.rawValue), icon: "menu-panel-ReadingList")
    }

    static let NewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", value: "New Tab", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to open a new tab")
    static let NewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", value: "New Private Tab", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    static let AddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", value: "Add Bookmark", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    static let RemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", value: "Remove Bookmark", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    static let FindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", value: "Find In Page", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    static let ViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", value: "Request Desktop Site", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    static let ViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", value: "Request Mobile Site", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    static let SettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", value: "Settings", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    static let CloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", value: "Close All Tabs", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    static let OpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", value: "Home", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    static let SetHomePageTitleString = NSLocalizedString("Menu.SetHomePageAction.Title", value: "Set Homepage", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to set the homepage if none is currently set.")
    static let SharePageTitleString = NSLocalizedString("Menu.SendPageAction.Title", value: "Send", tableName: "Menu", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    static let TopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", value: "Top Sites", tableName: "Menu", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    static let BookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel", value: "Bookmarks", tableName: "Menu", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    static let HistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel", value: "History", tableName: "Menu", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    static let ReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel", value: "Reading List", tableName: "Menu", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    static let MenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
}
