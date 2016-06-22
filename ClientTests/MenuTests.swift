/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
import Shared

class MenuTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func appState(ui: UIState) -> AppState {
        let prefs = MockProfilePrefs()
        prefs.setString("http://mozilla.com", forKey: HomePageConstants.HomePageURLPrefKey)
        return AppState(ui: ui, prefs: prefs)
    }

    // bookmarks menu item
    func testMenuConfigurationForNonBookmarkedItemInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let bookmarkItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.AddBookmarkTitleString }
        XCTAssertNotNil(bookmarkItem)
        let bookmarkedItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.RemoveBookmarkTitleString }
        XCTAssertNil(bookmarkedItem)
    }

    func testMenuConfigurationForBookmarkedItemInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: true, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let bookmarkedItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.RemoveBookmarkTitleString }
        XCTAssertNotNil(bookmarkedItem)
        let bookmarkItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.AddBookmarkTitleString }
        XCTAssertNil(bookmarkItem)
    }

    func testBookmarkItemsNotPresentInMenuConfigurationForHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let bookmarkItem = homePanelConfiguration.menuItems.find { ($0.title == AppMenuConfiguration.AddBookmarkTitleString || $0.title == AppMenuConfiguration.RemoveBookmarkTitleString) }
        XCTAssertNil(bookmarkItem)
    }

    func testBookmarkItemsNotPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let bookmarkItem = tabTrayConfiguration.menuItems.find { ($0.title == AppMenuConfiguration.AddBookmarkTitleString || $0.title == AppMenuConfiguration.RemoveBookmarkTitleString) }
        XCTAssertNil(bookmarkItem)
    }

    // new private tab item
    func testNewPrivateTabItemPresentInMenuConfigurationInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let privateTabItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewPrivateTabTitleString }
        XCTAssertNotNil(privateTabItem)
    }

    func testNewPrivateTabItemPresentInMenuConfigurationInHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let privateTabItem = homePanelConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewPrivateTabTitleString }
        XCTAssertNotNil(privateTabItem)
    }

    func testNewPrivateTabItemPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let privateTabItem = tabTrayConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewPrivateTabTitleString }
        XCTAssertNotNil(privateTabItem)
    }


    // new tab item
    func testNewTabItemPresentInMenuConfigurationInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let tabItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewTabTitleString }
        XCTAssertNotNil(tabItem)
    }

    func testNewTabItemPresentInMenuConfigurationInHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let tabItem = homePanelConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewTabTitleString }
        XCTAssertNotNil(tabItem)
    }

    func testNewTabItemPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let tabItem = tabTrayConfiguration.menuItems.find { $0.title == AppMenuConfiguration.NewTabTitleString }
        XCTAssertNotNil(tabItem)
    }


    // find in page item
    func testFindInPageItemPresentInMenuConfigurationInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let findInPageItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.FindInPageTitleString }
        XCTAssertNotNil(findInPageItem)
    }

    func testFindInPageItemNotPresentInMenuConfigurationInHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let findInPageItem = homePanelConfiguration.menuItems.find { $0.title == AppMenuConfiguration.FindInPageTitleString }
        XCTAssertNil(findInPageItem)
    }

    func testFindInPageItemNotPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let findInPageItem = tabTrayConfiguration.menuItems.find { $0.title == AppMenuConfiguration.FindInPageTitleString }
        XCTAssertNil(findInPageItem)
    }

    // view desktop site menu item
    func testMenuConfigurationForViewDesktopSiteItemInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let viewDesktopSiteItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.ViewDesktopSiteTitleString }
        XCTAssertNotNil(viewDesktopSiteItem)
        let viewMobileSiteItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.ViewMobileSiteTitleString }
        XCTAssertNil(viewMobileSiteItem)
    }

    func testMenuConfigurationForViewMobileSiteItemInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let viewMobileSiteItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.ViewMobileSiteTitleString }
        XCTAssertNotNil(viewMobileSiteItem)
        let viewDesktopSiteItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.ViewDesktopSiteTitleString }
        XCTAssertNil(viewDesktopSiteItem)
    }

    func testViewDesktopSiteItemsNotPresentInMenuConfigurationForHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let viewDesktopSiteItems = homePanelConfiguration.menuItems.find { ($0.title == AppMenuConfiguration.ViewDesktopSiteTitleString || $0.title == AppMenuConfiguration.ViewMobileSiteTitleString) }
        XCTAssertNil(viewDesktopSiteItems)
    }

    func testViewDesktopSiteItemsNotPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let viewDesktopSiteItems = tabTrayConfiguration.menuItems.find { ($0.title == AppMenuConfiguration.ViewDesktopSiteTitleString || $0.title == AppMenuConfiguration.ViewMobileSiteTitleString) }
        XCTAssertNil(viewDesktopSiteItems)
    }

    // Homepage and Set homepage items.
    func testHomePageMenuConfiguration() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let appState = self.appState(.Tab(tabState: tabState))
        appState.prefs.setString("http://mozilla.com", forKey: HomePageConstants.HomePageURLPrefKey)
        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let homePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.OpenHomePageTitleString }
        XCTAssertNotNil(homePageMenuItem)
        let setHomePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SetHomePageTitleString }
        XCTAssertNil(setHomePageMenuItem)
    }

    func testSetHomePageMenuConfiguration() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let appState = self.appState(.Tab(tabState: tabState))
        appState.prefs.removeObjectForKey(HomePageConstants.HomePageURLPrefKey)

        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let homePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.OpenHomePageTitleString }
        XCTAssertNil(homePageMenuItem)
        let setHomePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SetHomePageTitleString }
        XCTAssertNotNil(setHomePageMenuItem)
    }

    func testHomePageNotInMenuConfiguration() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let appState = self.appState(.Tab(tabState: tabState))
        appState.prefs.setBool(false, forKey: HomePageConstants.HomePageButtonIsInMenuPrefKey)
        
        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let homePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.OpenHomePageTitleString }
        XCTAssertNil(homePageMenuItem)
        let setHomePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SetHomePageTitleString }
        XCTAssertNil(setHomePageMenuItem)
        let sendMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SharePageTitleString }
        XCTAssertNotNil(sendMenuItem)
    }

    func testHomePageInHomePanelsMenuConfiguration() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let appState = self.appState(.HomePanels(homePanelState: homePanelState))
        appState.prefs.setString("http://mozilla.com", forKey: HomePageConstants.HomePageURLPrefKey)

        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let homePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.OpenHomePageTitleString }
        XCTAssertNotNil(homePageMenuItem)
        let setHomePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SetHomePageTitleString }
        XCTAssertNil(setHomePageMenuItem)
    }

    func testNoSetHomePageInHomePanelsMenuConfiguration() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let appState = self.appState(.HomePanels(homePanelState: homePanelState))
        appState.prefs.removeObjectForKey(HomePageConstants.HomePageURLPrefKey)

        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let homePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.OpenHomePageTitleString }
        XCTAssertNil(homePageMenuItem)
        let setHomePageMenuItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SetHomePageTitleString }
        XCTAssertNil(setHomePageMenuItem)
    }

    // Show and Hide Image items
    func testHideImagesMenuConfiguration() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let appState = self.appState(.Tab(tabState: tabState))
        appState.prefs.setBool(false, forKey: NoImageModePrefsKey.NoImageModeStatus)

        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let hideImageMenuItem = browserConfiguration.menuItems.find { $0.title == Strings.MenuNoImageModeTurnOnTitleString }
        XCTAssertNotNil(hideImageMenuItem)
        let showImageMenuItem = browserConfiguration.menuItems.find { $0.title == Strings.MenuNoImageModeTurnOffTitleString }
        XCTAssertNil(showImageMenuItem)
    }

    func testShowImagesMenuConfiguration() {
        let tabState = TabState(isPrivate: false, desktopSite: true, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let appState = self.appState(.Tab(tabState: tabState))
        appState.prefs.setBool(true, forKey: NoImageModePrefsKey.NoImageModeStatus)

        let browserConfiguration = AppMenuConfiguration(appState: appState)
        let hideImageMenuItem = browserConfiguration.menuItems.find { $0.title == Strings.MenuNoImageModeTurnOnTitleString }
        XCTAssertNil(hideImageMenuItem)
        let showImageMenuItem = browserConfiguration.menuItems.find { $0.title == Strings.MenuNoImageModeTurnOffTitleString }
        XCTAssertNotNil(showImageMenuItem)
    }

    // settings item
    func testSettingsItemPresentInMenuConfigurationInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let settingsItem = browserConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SettingsTitleString }
        XCTAssertNotNil(settingsItem)
    }

    func testSettingsItemNotPresentInMenuConfigurationInHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let settingsItem = homePanelConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SettingsTitleString }
        XCTAssertNotNil(settingsItem)
    }

    func testSettingsItemNotPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let settingsItem = tabTrayConfiguration.menuItems.find { $0.title == AppMenuConfiguration.SettingsTitleString }
        XCTAssertNotNil(settingsItem)
    }

    // home panel toolbar items
    func testHomePanelToolbarItemsPresentInMenuConfigurationInTab() {
        let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        let browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        let topSitesItem = browserConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.TopSitesTitleString }
        XCTAssertNotNil(topSitesItem)
        let bookmarksItem = browserConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.BookmarksTitleString }
        XCTAssertNotNil(bookmarksItem)
        let historyItem = browserConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.HistoryTitleString }
        XCTAssertNotNil(historyItem)
        let readingListItem = browserConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.ReadingListTitleString }
        XCTAssertNotNil(readingListItem)
    }

    func testHomePanelToolbarItemsNotPresentInMenuConfigurationInHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        let homePanelItems = homePanelConfiguration.menuToolbarItems?.find { menuToolbarItem in
            let exists = menuToolbarItem.title == AppMenuConfiguration.TopSitesTitleString
            || menuToolbarItem.title == AppMenuConfiguration.TopSitesTitleString
            || menuToolbarItem.title == AppMenuConfiguration.TopSitesTitleString
            || menuToolbarItem.title == AppMenuConfiguration.TopSitesTitleString
            return exists
        }
        XCTAssertNil(homePanelItems)
    }

    func testHomePanelToolbarItemsPresentInMenuConfigurationInTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        let topSitesItem = tabTrayConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.TopSitesTitleString }
        XCTAssertNotNil(topSitesItem)
        let bookmarksItem = tabTrayConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.BookmarksTitleString }
        XCTAssertNotNil(bookmarksItem)
        let historyItem = tabTrayConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.HistoryTitleString }
        XCTAssertNotNil(historyItem)
        let readingListItem = tabTrayConfiguration.menuToolbarItems?.find { $0.title == AppMenuConfiguration.ReadingListTitleString }
        XCTAssertNotNil(readingListItem)
    }
}
