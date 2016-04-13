/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client

class MenuTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMenuConfigurationForBrowser() {
        var tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        var browserConfiguration = FirefoxMenuConfiguration(appState: .Tab(tabState: tabState))
        XCTAssertEqual(browserConfiguration.menuItems.count, 6)
        XCTAssertEqual(browserConfiguration.menuItems[0].title, FirefoxMenuConfiguration.FindInPageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[1].title, FirefoxMenuConfiguration.ViewDesktopSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[2].title, FirefoxMenuConfiguration.SettingsTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[3].title, FirefoxMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[4].title, FirefoxMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[5].title, FirefoxMenuConfiguration.AddBookmarkTitleString)


        XCTAssertNotNil(browserConfiguration.menuToolbarItems)
        XCTAssertEqual(browserConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![0].title, FirefoxMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![1].title, FirefoxMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![2].title, FirefoxMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![3].title, FirefoxMenuConfiguration.ReadingListTitleString)


        tabState = TabState(isPrivate: true, desktopSite: true, isBookmarked: true, url: NSURL(string: "http://mozilla.com")!, title: "Mozilla", favicon: nil)
        browserConfiguration = FirefoxMenuConfiguration(appState: .Tab(tabState: tabState))
        XCTAssertEqual(browserConfiguration.menuItems.count, 6)
        XCTAssertEqual(browserConfiguration.menuItems[0].title, FirefoxMenuConfiguration.FindInPageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[1].title, FirefoxMenuConfiguration.ViewMobileSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[2].title, FirefoxMenuConfiguration.SettingsTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[3].title, FirefoxMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[4].title, FirefoxMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[5].title, FirefoxMenuConfiguration.RemoveBookmarkTitleString)


        XCTAssertNotNil(browserConfiguration.menuToolbarItems)
        XCTAssertEqual(browserConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![0].title, FirefoxMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![1].title, FirefoxMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![2].title, FirefoxMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![3].title, FirefoxMenuConfiguration.ReadingListTitleString)
    }

    func testMenuConfigurationForHomePanels() {
        let homePanelState = HomePanelState(isPrivate: false, selectedIndex: 0)
        let homePanelConfiguration = FirefoxMenuConfiguration(appState: .HomePanels(homePanelState: homePanelState))
        XCTAssertEqual(homePanelConfiguration.menuItems.count, 3)
        XCTAssertEqual(homePanelConfiguration.menuItems[0].title, FirefoxMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[1].title, FirefoxMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[2].title, FirefoxMenuConfiguration.SettingsTitleString)

        XCTAssertNil(homePanelConfiguration.menuToolbarItems)
    }

    func testMenuConfigurationForTabTray() {
        let tabTrayState = TabTrayState(isPrivate: false)
        let tabTrayConfiguration = FirefoxMenuConfiguration(appState: .TabTray(tabTrayState: tabTrayState))
        XCTAssertEqual(tabTrayConfiguration.menuItems.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuItems[0].title, FirefoxMenuConfiguration.NewTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[1].title, FirefoxMenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[2].title, FirefoxMenuConfiguration.CloseAllTabsTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[3].title, FirefoxMenuConfiguration.SettingsTitleString)

        XCTAssertNotNil(tabTrayConfiguration.menuToolbarItems)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![0].title, FirefoxMenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![1].title, FirefoxMenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![2].title, FirefoxMenuConfiguration.HistoryTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![3].title, FirefoxMenuConfiguration.ReadingListTitleString)
    }

}
