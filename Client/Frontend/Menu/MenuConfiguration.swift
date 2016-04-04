/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct MenuConfiguration {

    internal private(set) var menuItems = [MenuItem]()
    internal private(set) var menuToolbarItems: [MenuToolbarItem]?
    internal private(set) var numberOfItemsInRow: Int = 0

    internal private(set) var isPrivateMode: Bool = false

    init(appState: AppState) {
        menuItems = menuItemsForAppState(appState)
        menuToolbarItems = menuToolbarItemsForAppState(appState)
        numberOfItemsInRow = numberOfMenuItemsPerRowForAppState(appState)
        isPrivateMode = isPrivateMode(appState)
    }

    private func isPrivateMode(appState: AppState) -> Bool {
        switch(appState) {
        case .Tab(let tabState):
            return tabState.isPrivate
        case .HomePanels(homePanelState: let homePanelState):
            return homePanelState.isPrivate
        case .TabTray(let isPrivate):
            return isPrivate
        default:
            return false
        }
    }

    func toolbarColour() -> UIColor {

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
        let menuItems: [MenuItem]
        switch appState {
        case .Tab(let tabState):
                menuItems = [MenuConfiguration.FindInPageMenuItem,
                         tabState.desktopSite ? MenuConfiguration.RequestMobileMenuItem : MenuConfiguration.RequestDesktopMenuItem,
                         MenuConfiguration.SettingsMenuItem,
                         MenuConfiguration.NewTabMenuItem,
                         MenuConfiguration.NewPrivateTabMenuItem,
                         tabState.isBookmarked ? MenuConfiguration.RemoveBookmarkMenuItem : MenuConfiguration.AddBookmarkMenuItem]
        case .HomePanels:
            menuItems = [MenuConfiguration.NewTabMenuItem,
                         MenuConfiguration.NewPrivateTabMenuItem,
                         MenuConfiguration.SettingsMenuItem]
        case .TabTray:
            menuItems = [MenuConfiguration.NewTabMenuItem,
                         MenuConfiguration.NewPrivateTabMenuItem,
                         MenuConfiguration.CloseAllTabsMenuItem,
                         MenuConfiguration.SettingsMenuItem]
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
            menuToolbarItems = [MenuConfiguration.TopSitesMenuToolbarItem,
                                MenuConfiguration.BookmarksMenuToolbarItem,
                                MenuConfiguration.HistoryMenuToolbarItem,
                                MenuConfiguration.ReadingListMenuToolbarItem]
        default:
            menuToolbarItems = nil
        }
        return menuToolbarItems
    }
}

// MARK: Static helper access function

extension MenuConfiguration {

    private static var NewTabMenuItem: MenuItem {
        return MenuItem(title: NewTabTitleString, icon: "menu-NewTab", privateModeIcon: "menu-NewTab-pbm")
    }

    private static var NewPrivateTabMenuItem: MenuItem {
        return MenuItem(title: NewPrivateTabTitleString, icon: "menu-NewPrivateTab", privateModeIcon: "menu-NewPrivateTab-pbm")
    }

    private static var AddBookmarkMenuItem: MenuItem {
        return MenuItem(title: AddBookmarkTitleString, icon: "menu-Bookmark", privateModeIcon: "menu-Bookmark-pbm")
    }

    private static var RemoveBookmarkMenuItem: MenuItem {
        return MenuItem(title: RemoveBookmarkTitleString, icon: "menu-RemoveBookmark", privateModeIcon: "menu-RemoveBookmark")
    }

    private static var FindInPageMenuItem: MenuItem {
        return MenuItem(title: FindInPageTitleString, icon: "menu-FindInPage", privateModeIcon: "menu-FindInPage-pbm")
    }

    private static var RequestDesktopMenuItem: MenuItem {
        return MenuItem(title: ViewDesktopSiteTitleString, icon: "menu-RequestDesktopSite", privateModeIcon: "menu-RequestDesktopSite-pbm")
    }

    private static var RequestMobileMenuItem: MenuItem {
        return MenuItem(title: ViewMobileSiteTitleString, icon: "menu-ViewMobile", privateModeIcon: "menu-ViewMobile-pbm")
    }

    private static var SettingsMenuItem: MenuItem {
        return MenuItem(title: SettingsTitleString, icon: "menu-Settings", privateModeIcon: "menu-Settings-pbm")
    }

    private static var CloseAllTabsMenuItem: MenuItem {
        return MenuItem(title: CloseAllTabsTitleString, icon: "menu-CloseTabs", privateModeIcon: "menu-CloseTabs-pbm")
    }

    private static var TopSitesMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: TopSitesTitleString, icon: "menu-panel-TopSites", privateModeIcon: "menu-panel-TopSites-pbm")
    }

    private static var BookmarksMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: BookmarksTitleString, icon: "menu-panel-Bookmarks", privateModeIcon: "menu-panel-Bookmarks-pbm")
    }

    private static var HistoryMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: HistoryTitleString, icon: "menu-panel-History", privateModeIcon: "menu-panel-History-pbm")
    }

    private static var ReadingListMenuToolbarItem: MenuToolbarItem {
        return  MenuToolbarItem(title: ReadingListTitleString, icon: "menu-panel-ReadingList", privateModeIcon: "menu-panel-ReadingList-pbm")
    }

    static let NewTabTitleString = NSLocalizedString("New Tab", tableName: "Menu", comment: "String describing the action of creating a new tab from the menu")
    static let NewPrivateTabTitleString = NSLocalizedString("New Private Tab", tableName: "Menu", comment: "String describing the action of creating a new private tab from the menu")
    static let AddBookmarkTitleString = NSLocalizedString("Add Bookmark", tableName: "Menu", comment: "String describing the action of adding the current site as a bookmark from the menu")
    static let RemoveBookmarkTitleString = NSLocalizedString("Remove Bookmark", tableName: "Menu", comment: "String describing the action of remove the current site as a bookmark from the menu")
    static let FindInPageTitleString = NSLocalizedString("Find In Page", tableName: "Menu", comment: "String describing the action of opening the toolbar that allows users to search for items within a webpage from the menu")
    static let ViewDesktopSiteTitleString = NSLocalizedString("View Desktop Site", tableName: "Menu", comment: "String describing the action of switching a website from a mobile optimized view to a desktop view from the menu")
    static let ViewMobileSiteTitleString = NSLocalizedString("View Mobile Site", tableName: "Menu", comment: "String describing the action of switching a website from a desktop view to a mobile optimized view from the menu")
    static let SettingsTitleString = NSLocalizedString("Settings", tableName: "Menu", comment: "String describing the action of opening the settings menu from the menu")
    static let CloseAllTabsTitleString = NSLocalizedString("Close All Tabs", tableName: "Menu", comment: "String describing the action of closing all tabs in the tab tray at once from the menu")
    static let TopSitesTitleString = NSLocalizedString("Top Sites", tableName: "Menu", comment: "String describing the action of opening the Top Sites home panel from the menu")
    static let BookmarksTitleString = NSLocalizedString("Bookmarks", tableName: "Menu", comment: "String describing the action of opening the bookmarks home panel from the menu")
    static let HistoryTitleString = NSLocalizedString("History", tableName: "Menu", comment: "String describing the action of opening the history home panel from the menu")
    static let ReadingListTitleString = NSLocalizedString("Reading List", tableName: "Menu", comment: "String describing the action of opening the reading list home panel from the menu")
}