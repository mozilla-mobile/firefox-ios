/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum MenuLocation {
    case Browser
    case HomePanels
    case TabTray
}

struct MenuConfiguration {

    let menuItems: [MenuItem]
    let menuToolbarItems: [MenuToolbarItem]?
    let location: MenuLocation

    init(location: MenuLocation, menuItems: [MenuItem], toolbarItems: [MenuToolbarItem]?) {
        self.location = location
        self.menuItems = menuItems
        self.menuToolbarItems = toolbarItems
    }

    func toolbarColourForMode(isPrivate isPrivate: Bool = false) -> UIColor {
        return isPrivate ? UIConstants.MenuToolbarBackgroundColorPrivate : UIConstants.MenuToolbarBackgroundColorNormal
    }

    func toolbarTintColorForMode(isPrivate isPrivate: Bool = false) -> UIColor {
        return isPrivate ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuToolbarTintColorNormal
    }

    func menuBackgroundColorForMode(isPrivate isPrivate: Bool = false) -> UIColor {
        return isPrivate ? UIConstants.MenuBackgroundColorPrivate : UIConstants.MenuBackgroundColorNormal
    }

    func menuTintColorForMode(isPrivate isPrivate: Bool = false) -> UIColor {
        return isPrivate ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuBackgroundColorPrivate
    }

    func menuFont() -> UIFont {
        return UIFont.systemFontOfSize(11)
    }
}

// MARK: Static helper access function

extension MenuConfiguration {

    static let menuIcon = UIImage(named: "add")

    static func menuConfigurationForLocation(location: MenuLocation) -> MenuConfiguration {
        return MenuConfiguration(location: location, menuItems: menuItemsForLocation(location), toolbarItems: menuToolbarItemsForLocation(location))
    }

    // the items should be added to the array according to desired display order
    private static func menuItemsForLocation(location: MenuLocation) -> [MenuItem] {
        let menuItems: [MenuItem]
        switch location {
        case .Browser:
            // TODO: filter out menu items that are not to be displayed given the current app state
            // (i.e. whether the current browser URL is bookmarked or not)
            menuItems = [FindInPageMenuItem, RequestDesktopMenuItem, RequestMobileMenuItem, SettingsMenuItem, NewTabMenuItem, NewPrivateTabMenuItem, AddBookmarkMenuItem, RemoveBookmarkMenuItem]
        case .HomePanels:
            menuItems = [NewTabMenuItem, NewPrivateTabMenuItem, SettingsMenuItem]
        case .TabTray:
            menuItems = [NewTabMenuItem, NewPrivateTabMenuItem, CloseAllTabsMenuItem, SettingsMenuItem]
        }
        return menuItems
    }

    // the items should be added to the array according to desired display order
    private static func menuToolbarItemsForLocation(location: MenuLocation) -> [MenuToolbarItem]? {
        let menuToolbarItems: [MenuToolbarItem]?
        switch location {
        case .Browser, .TabTray:
            menuToolbarItems = [TopSitesMenuToolbarItem, BookmarksMenuToolbarItem, HistoryMenuToolbarItem, ReadingListMenuToolbarItem]
        case .HomePanels:
            menuToolbarItems = nil
        }
        return menuToolbarItems
    }

    private static var NewTabMenuItem: MenuItem {
        return MenuItem(title: NewTabTitleString, icon: "add", selectedIcon: "add")
    }

    private static var NewPrivateTabMenuItem: MenuItem {
        return MenuItem(title: NewPrivateTabTitleString, icon: "smallPrivateMask", selectedIcon: "smallPrivateMask")
    }

    private static var AddBookmarkMenuItem: MenuItem {
        return MenuItem(title: AddBookmarkTitleString, icon: "bookmark", selectedIcon: "bookmarkHighlighted")
    }

    private static var RemoveBookmarkMenuItem: MenuItem {
        return MenuItem(title: RemoveBookmarkTitleString, icon: "bookmark", selectedIcon: "bookmarkHighlighted")
    }

    private static var FindInPageMenuItem: MenuItem {
        return MenuItem(title: FindInPageTitleString, icon: "shareFindInPage", selectedIcon: "shareFindInPage")
    }

    private static var RequestDesktopMenuItem: MenuItem {
        return MenuItem(title: ViewDesktopSiteTitleString, icon: "shareRequestDesktopSite", selectedIcon: "shareRequestDesktopSite")
    }

    private static var RequestMobileMenuItem: MenuItem {
        return MenuItem(title: ViewMobileSiteTitleString, icon: "shareRequestMobileSite", selectedIcon: "shareRequestMobileSite")
    }

    private static var SettingsMenuItem: MenuItem {
        return MenuItem(title: SettingsTitleString, icon: "settings", selectedIcon: "settings")
    }

    private static var CloseAllTabsMenuItem: MenuItem {
        return MenuItem(title: CloseAllTabsTitleString, icon: "find_close", selectedIcon: "find_close")
    }

    private static var TopSitesMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: TopSitesTitleString, icon: "panelIconTopSites", selectedIcon: "panelIconTopSitesSelected")
    }

    private static var BookmarksMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: BookmarksTitleString, icon: "panelIconBookmarks", selectedIcon: "panelIconBookmarksSelected")
    }

    private static var HistoryMenuToolbarItem: MenuToolbarItem {
        return MenuToolbarItem(title: HistoryTitleString, icon: "panelIconHistory", selectedIcon: "panelIconHistorySelected")
    }

    private static var ReadingListMenuToolbarItem: MenuToolbarItem {
        return  MenuToolbarItem(title: ReadingListTitleString, icon: "panelIconReadingList", selectedIcon: "panelIconReadingListSelected")
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
