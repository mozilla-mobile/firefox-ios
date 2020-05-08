/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let mozDeveloperWebsite = "https://developer.mozilla.org/en-US"
let searchFieldPlaceholder = "Search MDN"
class ThirdPartySearchTest: BaseTestCase {
    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        app.buttons["Done"].tap()
    }

    func testCustomSearchEngines() {
        navigator.performAction(Action.AddCustomSearchEngine)
        waitForExistence(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()

        waitForExistence(app.navigationBars["Search"].buttons["Settings"], timeout: 3)
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
            
        // Perform a search using a custom search engine
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
               app.textFields.firstMatch.press(forDuration: 1)
               app.staticTexts["Paste"].tap()
        app.scrollViews.otherElements.buttons["Mozilla Engine search"].tap()
        waitUntilPageLoad()

        var url = app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineAsDefault() {
        navigator.performAction(Action.AddCustomSearchEngine)
        waitForExistence(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()

        // Go to settings and set MDN as the default
        waitForExistence(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()
        waitForExistence(app.tables.staticTexts["Mozilla Engine"])
        app.tables.staticTexts["Mozilla Engine"].tap()
        DismissSearchScreen()

        // Perform a search to check
        app.textFields["url"].tap()

        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste & Go"].tap()

        waitUntilPageLoad()

        // Ensure that the default search is MDN
        var url = app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineDeletion() {
        navigator.performAction(Action.AddCustomSearchEngine)
        waitForExistence(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()

        waitForExistence(app.navigationBars["Search"].buttons["Settings"], timeout: 3)

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()
        waitForExistence(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertTrue(app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)
                                
        // Need to go step by step to Search Settings. The ScreenGraph will fail to go to the Search Settings Screen
        app.buttons["urlBar-cancel"].tap()
        app.buttons["TabToolbar.menuButton"].tap()
        app.tables["Context Menu"].staticTexts["Settings"].tap()
        app.tables.staticTexts["Google"].tap()
        navigator.performAction(Action.RemoveCustomSearchEngine)
        DismissSearchScreen()
        
        // Perform a search to check
        waitForExistence(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        waitForExistence(app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()

        waitForNoExistence(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertFalse(app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)
    }
    
    private func DismissSearchScreen() {
        waitForExistence(app.navigationBars["Search"].buttons["Settings"])
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testCustomEngineFromIncorrectTemplate() {
        navigator.goto(AddCustomSearchSettings)
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")
        
        UIPasteboard.general.string = "http://www.google.com/search?q=&btnI"
        
        let tablesQuery = app.tables
        let customengineurlTextView = tablesQuery.textViews["customEngineUrl"]
        customengineurlTextView.staticTexts["URL (Replace Query with %s)"].tap()
        customengineurlTextView.press(forDuration: 1.0)
        waitForExistence(app.staticTexts["Paste"], timeout: 5)
        app.staticTexts["Paste"].tap()
        sleep(2)
        app.navigationBars.buttons["customEngineSaveButton"].tap()

        waitForExistence(app.alerts.element(boundBy: 0))
        XCTAssert(app.alerts.element(boundBy: 0).label == "Failed")
    }
}
