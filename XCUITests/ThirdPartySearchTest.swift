/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ThirdPartySearchTest: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        super.tearDown()
    }

    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        if app.buttons["Done"].exists {
            // iPhone
            app.buttons["Done"].tap()
        } else {
            // iPad
            app.buttons["Dismiss"].tap()
        }
    }

    func testCustomSearchEngines() {
        let app = XCUIApplication()

        // Visit MDN to add a custom search engine
        loadWebPage("https://developer.mozilla.org/en-US/search", waitForLoadToFinish: true)

        app.webViews.searchFields.element(boundBy: 0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].isEnabled)
        dismissKeyboardAssistant(forApp: app)

        // Perform a search using a custom search engine
        tabTrayButton(forApp: app).tap()
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

        app.webViews.searchFields.element(boundBy: 0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].isEnabled)
        dismissKeyboardAssistant(forApp: app)

        // Go to settings and set MDN as the default
        tabTrayButton(forApp: app).tap()
        app.buttons["TabTrayController.menuButton"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()
        tablesQuery.cells.element(boundBy: 0).tap()
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

        app.webViews.searchFields.element(boundBy: 0).tap()
        app.buttons["AddSearch"].tap()
        app.alerts["Add Search Provider?"].buttons["OK"].tap()
        XCTAssertFalse(app.buttons["AddSearch"].isEnabled)
        dismissKeyboardAssistant(forApp: app)

        let tabTrayButton = self.tabTrayButton(forApp: app)

        tabTrayButton.tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        app.textFields["url"].tap()
        app.typeText("window")
        
        // For timing issue, we need a wait statement
        waitforExistence(app.scrollViews.otherElements.buttons["developer.mozilla.org search"])
        XCTAssert(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)
        app.typeText("\r")

        // Go to settings and set MDN as the default
        tabTrayButton.tap(force: true)
        app.buttons["TabTrayController.menuButton"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()

        app.navigationBars["Search"].buttons["Edit"].tap()
        tablesQuery.buttons["Delete developer.mozilla.org"].tap()
        tablesQuery.buttons["Delete"].tap()

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()

        // Perform a search to check
        XCUIApplication().buttons["TabTrayController.addTabButton"].tap()
        
        app.textFields["url"].tap()
        app.typeText("window")
        sleep(2)
        XCTAssertFalse(app.scrollViews.otherElements.buttons["developer.mozilla.org search"].exists)

    }
    // Test failing in 10.3 due to timing issue when doing the last assert, it is done later than expected and so the text is different and fails
    /*func testCustomEngineFromCorrectTemplate() {
        let app = XCUIApplication()
        
        app.buttons["Menu"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()
        app.tables.cells["customEngineViewButton"].tap()
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")
        app.textViews["customEngineUrl"].tap()
        app.typeText("http://www.google.com/search?q=%s&btnI")
        
        app.navigationBars.buttons["customEngineSaveButton"].tap()

        waitforExistence(app.navigationBars["Search"])
        XCTAssert(app.navigationBars["Search"].buttons["Settings"].exists)

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
        
        // Perform a search using a custom search engine
        tabTrayButton(forApp: app).tap()
        app.buttons["TabTrayController.addTabButton"].tap()
        app.textFields["url"].tap()

        app.typeText("strange charm")
        app.scrollViews.otherElements.buttons["Feeling Lucky search"].tap()
        // Ensure that correct search is done
        let url = app.textFields["url"].value as! String
        XCTAssert(url.hasSuffix("&btnI"), "The URL should indicate that the search was performed using IFL")
    }
    */
    
    func testCustomEngineFromIncorrectTemplate() {
        let app = XCUIApplication()
        
        app.buttons["Menu"].tap()
        app.collectionViews.cells["Settings"].tap()
        let tablesQuery = app.tables
        tablesQuery.cells["Search"].tap()
        app.tables.cells["customEngineViewButton"].tap()
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")
        app.textViews["customEngineUrl"].tap()
        app.typeText("http://www.google.com/search?q=&btnI") //Occurunces of %s != 1

        app.navigationBars.buttons["customEngineSaveButton"].tap()
        
        waitforExistence(app.alerts.element(boundBy: 0))
        XCTAssert(app.alerts.element(boundBy: 0).label == "Failed")
    }
}
