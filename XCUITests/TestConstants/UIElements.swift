//
//  UIElements.swift
//  XCUITests
//
//  Created by horatiu purec on 04/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class UIElements {
    
    // General UI elements
    static let contextMenuRemoveButton = Base.app.tables["Context Menu"].cells["Remove"]
    
    // For ActivityStreamTest
    static let topSiteCellGroup = XCUIApplication().collectionViews.cells["TopSitesCell"]
    static let topSiteCellGroupTwitterCell = topSiteCellGroup.cells["twitter"]
    static let topSiteCellGroupAmazonCell = topSiteCellGroup.cells["amazon"]
    static let topSiteCellGroupWikipediaCell = topSiteCellGroup.cells["wikipedia"]
    static let topSiteCellGroupYoutubeCell = topSiteCellGroup.cells["youtube"]
    static let topSiteCellGroupFacebookCell = topSiteCellGroup.cells["facebook"]
    static let urlBarViewBackButton = Base.app.buttons["URLBarView.backButton"]
    static let tabToolbarBackButton = Base.app.buttons["TabToolbar.backButton"]
    static let topSiteCellGroupExampleCell = topSiteCellGroup.cells["example"]
    static let topSiteCellGroupTopSiteLabel = topSiteCellGroup.cells["wikipedia"]
    static let topSiteCellGroupBookmarkLabel = topSiteCellGroup.cells["Wikipedia"]
    static let topSiteCell = topSiteCellGroup.cells["TopSite"]
    static let topSiteCells = topSiteCellGroup.cells.matching(identifier: "TopSite")
    static let facebookCell = Base.app.cells["facebook"]
    static let mozillaCollectionCell = Base.app.collectionViews.cells["mozilla"]

    // For BookmarkingTests
    static let doneButton = Base.app.buttons["Done"]
    static let siteTablesFirstTextField = Base.app.tables["SiteTable"].cells.textFields.firstMatch
    static let urlTextField = Base.app.tables["SiteTable"].cells.textFields["https://"]
    static let newBookmarkNavigationBar = Base.app.navigationBars["New Bookmark"]
    static let tabTrayButton = Base.app.buttons["TopTabsViewController.tabsButton"].waitForExistence(timeout: Constants.defaultWaitTime) ?
        Base.app.buttons["TopTabsViewController.tabsButton"] : Base.app.buttons["TabToolbar.tabsButton"]
    
}
