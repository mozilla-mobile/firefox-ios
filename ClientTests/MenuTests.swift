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
        let appState: AppState = .Browser(currentURL: NSURL(string: "http://google.com")!, isBookmarked: true, isDesktopSite: true, hasAccount: true, isPrivate: false)
        let browserConfiguration = MenuConfiguration(appState: appState)
        XCTAssertEqual(browserConfiguration.menuItems.count, 8)
        XCTAssertEqual(browserConfiguration.menuItems[0].title, MenuConfiguration.FindInPageTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[1].title, MenuConfiguration.ViewDesktopSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[2].title, MenuConfiguration.ViewMobileSiteTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[3].title, MenuConfiguration.SettingsTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[4].title, MenuConfiguration.NewTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[5].title, MenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[6].title, MenuConfiguration.AddBookmarkTitleString)
        XCTAssertEqual(browserConfiguration.menuItems[7].title, MenuConfiguration.RemoveBookmarkTitleString)


        XCTAssertNotNil(browserConfiguration.menuToolbarItems)
        XCTAssertEqual(browserConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![0].title, MenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![1].title, MenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![2].title, MenuConfiguration.HistoryTitleString)
        XCTAssertEqual(browserConfiguration.menuToolbarItems![3].title, MenuConfiguration.ReadingListTitleString)
    }

    func testMenuConfigurationForHomePanels() {
        let appState: AppState = .HomePanels(selectedPanelIndex: 0, isPrivate: false)
        let homePanelConfiguration = MenuConfiguration(appState: appState)
        XCTAssertEqual(homePanelConfiguration.menuItems.count, 3)
        XCTAssertEqual(homePanelConfiguration.menuItems[0].title, MenuConfiguration.NewTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[1].title, MenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(homePanelConfiguration.menuItems[2].title, MenuConfiguration.SettingsTitleString)

        XCTAssertNil(homePanelConfiguration.menuToolbarItems)
    }

    func testMenuConfigurationForTabTray() {
        let appState: AppState = .TabsTray(isPrivate: false)
        let tabTrayConfiguration = MenuConfiguration(appState: appState)
        XCTAssertEqual(tabTrayConfiguration.menuItems.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuItems[0].title, MenuConfiguration.NewTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[1].title, MenuConfiguration.NewPrivateTabTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[2].title, MenuConfiguration.CloseAllTabsTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuItems[3].title, MenuConfiguration.SettingsTitleString)

        XCTAssertNotNil(tabTrayConfiguration.menuToolbarItems)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems!.count, 4)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![0].title, MenuConfiguration.TopSitesTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![1].title, MenuConfiguration.BookmarksTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![2].title, MenuConfiguration.HistoryTitleString)
        XCTAssertEqual(tabTrayConfiguration.menuToolbarItems![3].title, MenuConfiguration.ReadingListTitleString)
    }

}
