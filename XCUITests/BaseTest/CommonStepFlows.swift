//
//  CommonFlows.swift
//  XCUITests
//
//  Created by horatiu purec on 11/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class CommonStepFlows {
    
    static func bookmark() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Bookmark This Page"], timeout: 15)
        Base.app.tables.cells["Bookmark This Page"].tap()
        navigator.nowAt(BrowserTab)
    }

    static func unbookmark() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Remove Bookmark"])
        Base.app.cells["Remove Bookmark"].tap()
        navigator.nowAt(BrowserTab)
    }

    static func addNewBookmark() {
        navigator.goto(MobileBookmarksAdd)
        navigator.performAction(Action.AddNewBookmark)
        Base.helper.waitForExistence(Base.app.navigationBars["New Bookmark"], timeout: 3)
        // Enter the bookmarks details
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).tap()
        Base.app.tables["SiteTable"].cells.textFields.element(boundBy: 0).typeText("BBC")

        Base.app.tables["SiteTable"].cells.textFields["https://"].tap()
        Base.app.tables["SiteTable"].cells.textFields["https://"].typeText("bbc.com")
        navigator.performAction(Action.SaveCreatedBookmark)
        Base.app.buttons["Done"].tap()
        TestCheck.checkItemsInBookmarksList(items: 1)
    }

    static func typeOnSearchBar(text: String) {
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
        sleep(1)
        Base.app.textFields["address"].tap()
        Base.app.textFields["address"].typeText(text)
    }
    
    /**
     Removes all default top sites
     */
    static func removeAllDefaultTopSites() {
        Base.helper.waitForExistence(UIElements.facebookCell)
        
        for element in Constants.allDefaultTopSites {
            TestStep.longTapOnElement(UIElements.topSiteCellGroup.cells[element], forSeconds: 1)
            TestStep.selectOptionFromContextMenu(option: "Remove")
        }
    }
}
