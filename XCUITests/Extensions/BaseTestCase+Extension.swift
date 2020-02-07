//
//  BaseTestCase+Extension.swift
//  XCUITests
//
//  Created by horatiu purec on 05/02/2020.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import XCTest

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return Base.app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["TabToolbar.tabsButton"]
    }
}
