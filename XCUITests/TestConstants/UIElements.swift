//
//  UIElements.swift
//  XCUITests
//
//  Created by horatiu purec on 04/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class UIElements {
    
    // MARK: - General UI elements
    static let contextMenuTable = Base.app.tables["Context Menu"]
    static let contextMenuRemoveButton = contextMenuTable.cells["Remove"]
    static let contexMenuOpenInNewTab = contextMenuTable.cells["Open in New Tab"]
    static let contextMenuRemoveBookmark = contextMenuTable.cells["Remove Bookmark"]
    static let firstCollectionCell = Base.app.collectionViews.cells.firstMatch
    
    // MARK: - For ActivityStreamTest Suite
    static let topSiteCellGroup = Base.app.collectionViews.cells["TopSitesCell"]
    static let topSiteCellGroupTwitterCell = topSiteCellGroup.cells["twitter"]
    static let topSiteCellGroupAmazonCell = topSiteCellGroup.cells["amazon"]
    static let topSiteCellGroupWikipediaCell = topSiteCellGroup.cells["wikipedia"]
    static let topSiteCellGroupYoutubeCell = topSiteCellGroup.cells["youtube"]
    static let topSiteCellGroupFacebookCell = topSiteCellGroup.cells["facebook"]
    static let topSiteCellGroupMozillaCell = topSiteCellGroup.cells["mozilla"]
    static let urlBarViewBackButton = Base.app.buttons["URLBarView.backButton"]
    static let tabToolbarBackButton = Base.app.buttons["TabToolbar.backButton"]
    static let topSiteCellGroupExampleCell = topSiteCellGroup.cells["example"]
    static let topSiteCellGroupTopSiteLabel = topSiteCellGroup.cells["wikipedia"]
    static let topSiteCellGroupBookmarkLabel = topSiteCellGroup.cells["Wikipedia"]
    static let topSiteCellGroupAppleLabel = topSiteCellGroup.cells["apple"]
    static let topSiteCell = topSiteCellGroup.cells["TopSite"]
    static let topSiteCells = topSiteCellGroup.cells.matching(identifier: "TopSite")
    static let facebookCell = Base.app.cells["facebook"]
    static let mozillaCollectionCell = Base.app.collectionViews.cells["mozilla"]
    static let wikipediaTopSiteCell = Base.app.cells["TopSitesCell"].cells["wikipedia"]
    static let wikipediaCollectionCell = Base.app.collectionViews.cells["Wikipedia"]
    static let homeCollectionCell = Base.app.collectionViews.cells["Home"]
    static let topSiteFirstCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 0)
    static let topSiteSecondCell = Base.app.collectionViews.cells.collectionViews.cells.element(boundBy: 1)
    static let appleLabel = Base.app.staticTexts["apple"]
    static let firstTopSiteCell = Base.app.cells["TopSitesCell"].cells.element(boundBy: 0)
    static let secondTopSiteCell = Base.app.cells["TopSitesCell"].cells.element(boundBy: 1)
    static let thirdTopSiteCell = Base.app.cells["TopSitesCell"].cells.element(boundBy: 2)
    static let fourthTopSiteCell = Base.app.cells["TopSitesCell"].cells.element(boundBy: 3)
    static let wikipediaBookmarkLabelCell = Base.app.collectionViews.cells["Wikipedia"]
    static let appleCollectionView = Base.app.collectionViews["Apple"]
    static let appleCollectionCell = Base.app.collectionViews.cells["Apple"]
    static let urlTextInputField = Base.app.textFields["url"]
    static let showTabsButton = Base.app.buttons["Show Tabs"]
    static let bookmarkListWikipedia = Base.app.tables["Bookmarks List"].staticTexts["Wikipedia"]
    static let bookmarkListInternetForPeople = Base.app.tables["Bookmarks List"].staticTexts["Internet for people, not profit — Mozilla"]

    // MARK: - For BookmarkingTests Suite
    static let doneButton = Base.app.buttons["Done"]
    static let siteTablesFirstTextField = Base.app.tables["SiteTable"].cells.textFields.firstMatch
    static let urlTextField = Base.app.tables["SiteTable"].cells.textFields["https://"]
    static let newBookmarkNavigationBar = Base.app.navigationBars["New Bookmark"]
    static let tabTrayButton = Base.app.buttons["TopTabsViewController.tabsButton"].waitForExistence(timeout: Constants.defaultWaitTime) ?
        Base.app.buttons["TopTabsViewController.tabsButton"] : Base.app.buttons["TabToolbar.tabsButton"]
    
}
