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

    func appState(_ ui: UIState) -> AppState {
        let prefs = MockProfilePrefs()
        prefs.setString("http://mozilla.com", forKey: HomePageConstants.HomePageURLPrefKey)
        return AppState(ui: ui, prefs: prefs)
    }

    func testMenuConfigurationForBrowser() {
        var tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: URL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        var browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        XCTAssertEqual(browserConfiguration.menuItems.count, 7)
        XCTAssertEqual(browserConfiguration.menuItems[0].title, AppMenuConfiguration.FindInPageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[1].title, AppMenuConfiguration.ViewDesktopSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[2].title, AppMenuConfiguration.OpenHomePageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[3].title, AppMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[4].title, AppMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[5].title, AppMenuConfiguration.AddBookmarkTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[6].title, AppMenuConfiguration.SettingsTitleString)

        XCTAssertNotNil(browserConfiguration.menuToolbarItems)
        XCTAssertEqual(browserConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![0].title, AppMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![1].title, AppMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![2].title, AppMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![3].title, AppMenuConfiguration.ReadingListTitleString)


        tabState = TabState(isPrivate: true, desktopSite: true, isBookmarked: true, url: URL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        browserConfiguration = AppMenuConfiguration(appState: appState(.Tab(tabState: tabState)))
        XCTAssertEqual(browserConfiguration.menuItems.count, 7)
        XCTAssertEqual(browserConfiguration.menuItems[0].title, AppMenuConfiguration.FindInPageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[1].title, AppMenuConfiguration.ViewMobileSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[2].title, AppMenuConfiguration.OpenHomePageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[3].title, AppMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[4].title, AppMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[5].title, AppMenuConfiguration.RemoveBookmarkTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[6].title, AppMenuConfiguration.SettingsTitleString)


        XCTAssertNotNil(browserConfiguration.menuToolbarItems)
        XCTAssertEqual(browserConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![0].title, AppMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![1].title, AppMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![2].title, AppMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![3].title, AppMenuConfiguration.ReadingListTitleString)
    }

    func testMenuConfigurationForHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = AppMenuConfiguration(appState: appState(.HomePanels(homePanelState: homePanelState)))
        XCTAssertEqual(homePanelConfiguration.menuItems.count, 4)
        XCTAssertEqual(homePanelConfiguration.menuItems[0].title, AppMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[1].title, AppMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[2].title, AppMenuConfiguration.OpenHomePageTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[3].title, AppMenuConfiguration.SettingsTitleString)

        XCTAssertNil(homePanelConfiguration.menuToolbarItems)
    }

    func testMenuConfigurationForTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = AppMenuConfiguration(appState: appState(.TabTray(tabTrayState: tabTrayState)))
        XCTAssertEqual(tabTrayConfiguration.menuItems.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuItems[0].title, AppMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[1].title, AppMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[2].title, AppMenuConfiguration.CloseAllTabsTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[3].title, AppMenuConfiguration.SettingsTitleString)

        XCTAssertNotNil(tabTrayConfiguration.menuToolbarItems)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![0].title, AppMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![1].title, AppMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![2].title, AppMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![3].title, AppMenuConfiguration.ReadingListTitleString)
    }

}
