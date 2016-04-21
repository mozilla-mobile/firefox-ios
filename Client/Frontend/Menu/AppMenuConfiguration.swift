/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum AppMenuAction: String {
    case OpenNewNormalTab = "OpenNewNormalTab"
    case OpenNewPrivateTab = "OpenNewPrivateTab"
    case FindInPage = "FindInPage"
    case ToggleBrowsingMode = "ToggleBrowsingMode"
    case ToggleBookmarkStatus = "ToggleBookmarkStatus"
    case OpenSettings = "OpenSettings"
    case CloseAllTabs = "CloseAllTabs"
    case OpenTopSites = "OpenTopSites"
    case OpenBookmarks = "OpenBookmarks"
    case OpenHistory = "OpenHistory"
    case OpenReadingList = "OpenReadingList"
}

struct AppMenuConfiguration: MenuConfiguration {

    internal private(set) var menuItems = [MenuItem]()
    internal private(set) var menuToolbarItems: [MenuToolbarItem]?
    internal private(set) var numberOfItemsInRow: Int = 0

    private(set) var isPrivateMode: Bool = false

    init(appState: AppState) {
        menuItems = menuItemsForAppState(appState)
        menuToolbarItems = menuToolbarItemsForAppState(appState)
        numberOfItemsInRow = numberOfMenuItemsPerRowForAppState(appState)
        isPrivateMode = appState.isPrivate()
    }

    func menuForState(appState: AppState) -> MenuConfiguration {
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
        return UIFont.systemFontOfSize(11)
    }

    func menuIcon() -> UIImage? {
        return isPrivateMode ? UIImage(named:"bottomNav-menu-pbm") : UIImage(named:"bottomNav-menu")
    }

    func shadowColor() -> UIColor {
        return isPrivateMode ? UIColor.darkGrayColor() : UIColor.lightGrayColor()
    }

    func selectedItemTintColor() -> UIColor {
        return UIConstants.MenuSelectedItemTintColor
    }

    private func numberOfMenuItemsPerRowForAppState(appState: AppState) -> Int {
        switch appState {
        case .TabTray:
            return 4
        default:
            return 3
        }
    }

    // the items should be added to the array according to desired display order
    private func menuItemsForAppState(appState: AppState) -> [MenuItem] {
        var menuItems = [MenuItem]()
        switch appState {
        case .Tab(let tabState):
            menuItems.append(AppMenuConfiguration.FindInPageMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(tabState.desktopSite ? AppMenuConfiguration.RequestMobileMenuItem : AppMenuConfiguration.RequestDesktopMenuItem)
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
            menuItems.append(tabState.isBookmarked ? AppMenuConfiguration.RemoveBookmarkMenuItem : AppMenuConfiguration.AddBookmarkMenuItem)
        case .HomePanels:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .TabTray:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            if #available(iOS 9, *) {
                menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            }
            menuItems.append(AppMenuConfiguration.CloseAllTabsMenuItem)
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        default:
            menuItems = []
        }
        return menuItems
    }

    // the items should be added to the array according to desired display order
    private func menuToolbarItemsForAppState(appState: AppState) -> [MenuToolbarItem]? {
        let menuToolbarItems: [MenuToolbarItem]?
        switch appState {
        case .Tab, .TabTray:
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

    private static var SettingsMenuItem: MenuItem {
        return AppMenuItem(title: SettingsTitleString, action:  MenuAction(action: AppMenuAction.OpenSettings.rawValue), icon: "menu-Settings", privateModeIcon: "menu-Settings-pbm")
    }

    private static var CloseAllTabsMenuItem: MenuItem {
        return AppMenuItem(title: CloseAllTabsTitleString, action:  MenuAction(action: AppMenuAction.CloseAllTabs.rawValue), icon: "menu-CloseTabs", privateModeIcon: "menu-CloseTabs-pbm")
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

    static let NewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", value: "New Tab", tableName: "Menu", comment: "String describing the action of creating a new tab from the menu")
    static let NewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", value: "New Private Tab", tableName: "Menu", comment: "String describing the action of creating a new private tab from the menu")
    static let AddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", value: "Add Bookmark", tableName: "Menu", comment: "String describing the action of adding the current site as a bookmark from the menu")
    static let RemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", value: "Remove Bookmark", tableName: "Menu", comment: "String describing the action of remove the current site as a bookmark from the menu")
    static let FindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", value: "Find In Page", tableName: "Menu", comment: "String describing the action of opening the toolbar that allows users to search for items within a webpage from the menu")
    static let ViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", value: "View Desktop Site", tableName: "Menu", comment: "String describing the action of switching a website from a mobile optimized view to a desktop view from the menu")
    static let ViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", value: "View Mobile Site", tableName: "Menu", comment: "String describing the action of switching a website from a desktop view to a mobile optimized view from the menu")
    static let SettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", value: "Settings", tableName: "Menu", comment: "String describing the action of opening the settings menu from the menu")
    static let CloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", value: "Close All Tabs", tableName: "Menu", comment: "String describing the action of closing all tabs in the tab tray at once from the menu")
    static let TopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", value: "Top Sites", tableName: "Menu", comment: "AccessibilityLabel describing the action of opening the Top Sites home panel from the menu")
    static let BookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel", value: "Bookmarks", tableName: "Menu", comment: "AccessibilityLabel describing the action of opening the bookmarks home panel from the menu")
    static let HistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel", value: "History", tableName: "Menu", comment: "AccessibilityLabel describing the action of opening the history home panel from the menu")
    static let ReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel", value: "Reading List", tableName: "Menu", comment: "AccessibilityLabel describing the action of opening the reading list home panel from the menu")
}
