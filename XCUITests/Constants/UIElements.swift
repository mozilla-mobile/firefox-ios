//
//  UIElements.swift
//  XCUITests
//
//  Created by horatiu purec on 04/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

class UIElements {
    static let doneButton = Base.app.buttons["Done"]
    static let siteTablesFirstTextField = Base.app.tables["SiteTable"].cells.textFields.firstMatch
    static let urlTextField = Base.app.tables["SiteTable"].cells.textFields["https://"]
    static let newBookmarkNavigationBar = Base.app.navigationBars["New Bookmark"]
}
