/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ThirdPartySearchTest: BaseTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCustomSearchEngines() {
        let app = XCUIApplication()

        // Visit MDN to add a custom search engine
        loadWebPage("https://developer.mozilla.org/en-US/search", waitForLoadToFinish: true)

        app.webViews.textFields.elementBoundByIndex(0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].collectionViews.buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].enabled)
        app.buttons["Done"].tap()

        // Perform a search using a custom search engine
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        app.textFields["url"].tap()
        app.typeText("window")
        app.scrollViews.otherElements.buttons["developer.mozilla.org search"].tap()

        // Ensure that the search is done on MDN
        let url = app.textFields["url"].value as! String
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineAsDefault() {
        let app = XCUIApplication()

        // Visit MDN to add a custom search engine
        loadWebPage("https://developer.mozilla.org/en-US/search", waitForLoadToFinish: true)

        app.webViews.textFields.elementBoundByIndex(0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].collectionViews.buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].enabled)
        app.buttons["Done"].tap()

        // Go to settings and set MDN as the default
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.menuButton"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()
        tablesQuery.cells.elementBoundByIndex(0).tap()
        tablesQuery.staticTexts["developer.mozilla.org"].tap()
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()

        // Perform a search to check
        app.buttons["TabTrayController.addTabButton"].tap()
        app.textFields["url"].tap()
        app.typeText("window\r")

        // Ensure that the default search is MDN
        let url = app.textFields["url"].value as! String
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineDeletion() {
        let app = XCUIApplication()

        // Visit MDN to add a custom search engine
        loadWebPage("https://developer.mozilla.org/en-US/search", waitForLoadToFinish: true)

        app.webViews.textFields.elementBoundByIndex(0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].collectionViews.buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].enabled)
        app.buttons["Done"].tap()

        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        app.textFields["url"].tap()
        app.typeText("window")
        XCTAssert(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)
        app.typeText("\r")

        // Go to settings and set MDN as the default
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.menuButton"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()

        app.navigationBars["Search"].buttons["Edit"].tap()
        tablesQuery.buttons["Delete developer.mozilla.org"].tap()
        tablesQuery.buttons["Delete"].tap()

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()

        restart(app, reset: false)

        // Perform a search to check
        app.textFields["url"].tap()
        app.typeText("window")
        XCTAssertFalse(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)

    }

}
