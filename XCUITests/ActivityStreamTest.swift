/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ActivityStreamTest: BaseTestCase {

    override func setUp() {
        if Constants.testWithDB.contains(Base.helper.getTestName(fromTest: name)) {
            // for the current test name, add the db fixture used
            let pagesVisitedDB = Base.helper.iPad() ? LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPad : LaunchArguments.LoadDatabasePrefix + Constants.pagesVisitediPhone
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, pagesVisitedDB]
        }
        
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // Smoketest
    func testDefaultSites() {
        // There should be 5 top sites by default
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        
        // Check their names so that test is added to Smoketest
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupTwitterCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupAmazonCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupWikipediaCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupYoutubeCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupFacebookCell)
    }

    func testTopSitesAdd() {
        navigator.goto(URLBarOpen)
        Base.helper.iPad() ? TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 12) : TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 8)
    }

    func testTopSitesRemove() {
        Base.helper.loadWebPage(Constants.urlExample)
        Base.helper.waitForTabsButton()
        Base.helper.iPad() ? Base.helper.tapOnElement(UIElements.urlBarViewBackButton) : Base.helper.tapOnElement(UIElements.tabToolbarBackButton)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        
        // A new site has been added to the top sites
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        // example is the name of the domain. (example.com)
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupExampleCell, forSeconds: 1)
        Base.helper.tapOnElement(UIElements.contextMenuRemoveButton)
        
        // A top site has been removed
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
    }

    func testTopSitesRemoveDefaultTopSite() {
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupTopSiteLabel, forSeconds: 1)

        // Tap on Remove and check that now there should be only 4 default top sites
        Base.helper.selectOptionFromContextMenu(option: "Remove")
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 4)
    }

    func testTopSitesRemoveAllDefaultTopSitesAddNewOne() {
        // Remove all default Top Sites
        CommonStepFlows.removeAllDefaultTopSites()

        let numberOfTopSites = UIElements.topSiteCells.count
        Base.helper.waitForNoExistence(UIElements.topSiteCell)
        TestCheck.numbersAreEqual(numberOfTopSites, 0, failureMessage: "All top sites should have been removed")

        // Open a new page and wait for the completion
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL(Constants.urlMozilla)
        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        Base.helper.waitForExistence(UIElements.topSiteCellGroupTopSiteLabel)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 1)
    }

    func testTopSitesRemoveAllExceptDefaultClearPrivateData() {
        navigator.goto(BrowserTab)
        Base.helper.waitForTabsButton()
        navigator.goto(TabTray)
        
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        TestCheck.elementIsPresent(UIElements.mozillaCollectionCell)
        
        // A new site has been added to the top sites
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 5)
        TestCheck.elementIsNotPresent(UIElements.mozillaCollectionCell)
    }

    func testTopSitesRemoveAllExceptPinnedClearPrivateData() {
        navigator.goto(BrowserTab)
        navigator.performAction(Action.PinToTopSitesPAM)
        
        // Workaround to have visited website in top sites
        navigator.performAction(Action.AcceptRemovingAllTabs)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        TestCheck.elementIsPresent(UIElements.mozillaCollectionCell)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)

        navigator.goto(ClearPrivateDataSettings)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        TestCheck.elementIsPresent(UIElements.mozillaCollectionCell, timeout: Constants.longWaitTime)
        TestCheck.checkNumberOfExpectedTopSites(numberOfExpectedTopSites: 6)
    }

    func testTopSitesShiftAfterRemovingOne() {
        // Check top site in first and second cell
        TestCheck.stringsAreEqual(UIElements.topSiteFirstCell.label, Constants.allDefaultTopSites[0])
        TestCheck.stringsAreEqual(UIElements.topSiteSecondCell.label, Constants.allDefaultTopSites[1])

        // Remove facebook top sites, first cell
        Base.helper.longTapOnElement(UIElements.firstTopSiteCell, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Remove")

        // Check top site in first cell now
        TestCheck.elementIsPresent(UIElements.topSiteFirstCell)
        let topSiteCells = UIElements.topSiteCellGroup.cells
        let topSiteFirstCellAfter = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0).label
        TestCheck.stringsAreEqual(topSiteFirstCellAfter, topSiteCells["youtube"].label)
    }

    func testTopSitesOpenInNewTab() {
        navigator.goto(HomePanelsScreen)
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupAppleLabel, forSeconds: 1)
        Base.helper.tapOnElement(UIElements.contexMenuOpenInNewTab)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroup)
        TestCheck.elementIsNotPresent(UIElements.appleLabel)

        navigator.goto(TabTray)
        Base.helper.tapOnElement(UIElements.homeCollectionCell)
        TestCheck.elementIsPresent(UIElements.topSiteCellGroupAppleLabel)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        TestCheck.elementIsPresent(UIElements.appleCollectionCell)
    }

    // Smoketest
    func testTopSitesOpenInNewTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        Base.helper.longTapOnElement(UIElements.fourthTopSiteCell, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Open in New Tab")
        
        // Check that two tabs are open and one of them is the default top site one
        // Needed for BB to work after iOS 13.3 update
        sleep(1)
        Base.helper.waitForNoExistence(UIElements.contextMenuTable, timeoutValue: Constants.longWaitTime)
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(UIElements.wikipediaBookmarkLabelCell)
        TestCheck.numbersAreEqual(Base.app.collectionViews.cells.count, 2, failureMessage: "New tab not open.")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTab() {
        navigator.goto(HomePanelsScreen)
        // Long tap on apple top site, second cell
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupAppleLabel, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Open in New Private Tab")

        TestCheck.elementIsPresent(UIElements.topSiteCellGroup)
        TestCheck.elementIsNotPresent(UIElements.appleLabel)

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        navigator.goto(TabTray)
        Base.helper.waitForExistence(UIElements.firstCollectionCell)
        
        if !UIElements.appleCollectionView.waitForExistence(timeout: Constants.smallWaitTime) {
            Base.helper.tapOnElement(UIElements.firstCollectionCell)
            Base.helper.waitForValueContains(UIElements.urlTextInputField, value: "apple")
            Base.helper.tapOnElement(UIElements.showTabsButton)
        }
        
        navigator.nowAt(TabTray)
        Base.helper.tapOnElement(UIElements.appleCollectionCell)

        // The website is open
        TestCheck.elementIsNotPresent(UIElements.topSiteCellGroup)
        TestCheck.elementIsPresent(UIElements.urlTextInputField)
        Base.helper.waitForValueContains(UIElements.urlTextInputField, value: "apple.com")
    }

    // Smoketest
    func testTopSitesOpenInNewPrivateTabDefaultTopSite() {
        // Open one of the sites from Topsites and wait until page is loaded
        // Long tap on apple top site, second cell
        Base.helper.longTapOnElement(UIElements.fourthTopSiteCell, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Open in New Private Tab")

        // Check that two tabs are open and one of them is the default top site one
        // Workaroud needed after xcode 11.3 update Issue 5937
        sleep(3)
        navigator.nowAt(HomePanelsScreen)
        Base.helper.waitForTabsButton()

        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)

        Base.helper.waitForExistence(UIElements.wikipediaCollectionCell)
        let numTabsOpen = userState.numTabs
        TestCheck.numbersAreEqual(numTabsOpen, 1, failureMessage: "New tab not open.")
    }

    func testTopSitesBookmarkDefaultTopSite() {
        // Bookmark a default TopSite, Wikipedia, third top site
        Base.helper.longTapOnElement(UIElements.fourthTopSiteCell, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.goto(MobileBookmarks)
        TestCheck.elementIsPresent(UIElements.bookmarkListWikipedia)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.nowAt(LibraryPanel_Bookmarks)
        navigator.performAction(Action.CloseBookmarkPanel)

        Base.helper.longTapOnElement(UIElements.wikipediaTopSiteCell, forSeconds: 2)
        TestCheck.elementIsPresent(UIElements.contextMenuRemoveBookmark)

        // Unbookmark it
        Base.helper.selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        TestCheck.elementIsNotPresent(UIElements.bookmarkListWikipedia)
    }

    func testTopSitesBookmarkNewTopSite() {
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupMozillaCell, forSeconds: 1)
        Base.helper.selectOptionFromContextMenu(option: "Bookmark")

        // Check that it appears under Bookmarks menu
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(MobileBookmarks)
        TestCheck.elementIsPresent(UIElements.bookmarkListInternetForPeople)

        // Check that longtapping on the TopSite gives the option to remove it
        navigator.performAction(Action.ExitMobileBookmarksFolder)
        navigator.goto(HomePanelsScreen)
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupMozillaCell, forSeconds: 1)

        // Unbookmark it
        Base.helper.selectOptionFromContextMenu(option: "Remove Bookmark")
        navigator.goto(LibraryPanel_Bookmarks)
        TestCheck.elementIsNotPresent(UIElements.bookmarkListInternetForPeople)
    }

    func testTopSitesShareDefaultTopSite() {
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupWikipediaCell, forSeconds: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it
        Base.helper.selectOptionFromContextMenu(option: "Share")
        
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }

    func testContextMenuInLandscape() {
        Base.helper.changeDeviceOrientation(.landscapeLeft)
        Base.helper.longTapOnElement(UIElements.topSiteCellGroupAppleLabel, forSeconds: 1)
        XCTAssertLessThanOrEqual(UIElements.contextMenuTable.frame.size.height, Base.app.otherElements["Action Sheet"].frame.size.height)

        // Go back to portrait mode
        Base.helper.changeDeviceOrientation(.portrait)
    }
    
    // MARK: - Commented test cases
    // Disable #5554
    /*
    func testTopSitesShareNewTopSite() {
        navigator.goto(HomePanelsScreen)
        let topSiteCells = UIElements.topSiteCellGroup.cells
        Base.helper.waitForExistence(topSiteCells[newTopSite["topSiteLabel"]!])
        topSiteCells[newTopSite["topSiteLabel"]!].press(forDuration: 1)

        // Tap on Share option and verify that the menu is shown and it is possible to cancel it....
        selectOptionFromContextMenu(option: "Share")
        // Comenting out until share sheet can be managed with automated tests issue #5477
        //if !iPad() {
        //    Base.app.buttons["Cancel"].tap()
        //}
    }*/
    
}
