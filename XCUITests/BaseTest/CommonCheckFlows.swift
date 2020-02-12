//
//  CommonCheckFlows.swift
//  XCUITests
//
//  Created by horatiu purec on 11/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class CommonCheckFlows {
    
    static func checkBookmarked() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Remove Bookmark"])
        if Base.helper.iPad() {
            Base.app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }

    static func checkUnbookmarked() {
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables.cells["Bookmark This Page"])
        if Base.helper.iPad() {
            Base.app.otherElements["PopoverDismissRegion"].tap()
            navigator.nowAt(BrowserTab)
        } else {
            navigator.goto(BrowserTab)
        }
    }
    
    static func checkItemsInBookmarksList(items: Int) {
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"], timeout: 3)
        XCTAssertEqual(Base.app.tables["Bookmarks List"].cells.count, items)
    }
    
    static func checkEmptyBookmarkList() {
        let list = Base.app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 0, "There should not be any entry in the bookmarks list")
    }

    static func checkItemInBookmarkList() {
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"])
        let list = Base.app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
        XCTAssertTrue(Base.app.tables["Bookmarks List"].staticTexts[Constants.url_2["bookmarkLabel"] ?? "no url!"].exists)
    }
    
}
