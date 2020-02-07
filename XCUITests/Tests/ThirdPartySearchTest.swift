/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let mozDeveloperWebsite = "https://developer.mozilla.org/en-US"
let searchFieldPlaceholder = "Search MDN"
class ThirdPartySearchTest: BaseTestCase {
    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        Base.app.buttons["Done"].tap()
    }

    func testCustomSearchEngines() {
        navigator.performAction(Action.AddCustomSearchEngine)
        Base.helper.waitForExistence(Base.app.buttons["customEngineSaveButton"], timeout: 3)
        Base.app.buttons["customEngineSaveButton"].tap()

        Base.helper.waitForExistence(Base.app.navigationBars["Search"].buttons["Settings"], timeout: 3)
        Base.app.navigationBars["Search"].buttons["Settings"].tap()
        Base.app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
            
        // Perform a search using a custom search engine
        Base.app.textFields["url"].tap()
        Base.helper.waitForExistence(Base.app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
               Base.app.textFields.firstMatch.press(forDuration: 1)
               Base.app.staticTexts["Paste"].tap()
        Base.app.scrollViews.otherElements.buttons["Mozilla Engine search"].tap()
        Base.helper.waitUntilPageLoad()

        var url = Base.app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineAsDefault() {
        navigator.performAction(Action.AddCustomSearchEngine)
        Base.helper.waitForExistence(Base.app.buttons["customEngineSaveButton"], timeout: 3)
        Base.app.buttons["customEngineSaveButton"].tap()

        // Go to settings and set MDN as the default
        Base.helper.waitForExistence(Base.app.tables.staticTexts["Google"])
        Base.app.tables.staticTexts["Google"].tap()
        Base.helper.waitForExistence(Base.app.tables.staticTexts["Mozilla Engine"])
        Base.app.tables.staticTexts["Mozilla Engine"].tap()
        DismissSearchScreen()

        // Perform a search to check
        Base.app.textFields["url"].tap()

        UIPasteboard.general.string = "window"
        Base.app.textFields.firstMatch.press(forDuration: 1)
        Base.app.staticTexts["Paste & Go"].tap()

        Base.helper.waitUntilPageLoad()

        // Ensure that the default search is MDN
        var url = Base.app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    func testCustomSearchEngineDeletion() {
        navigator.performAction(Action.AddCustomSearchEngine)
        Base.helper.waitForExistence(Base.app.buttons["customEngineSaveButton"], timeout: 3)
        Base.app.buttons["customEngineSaveButton"].tap()

        Base.helper.waitForExistence(Base.app.navigationBars["Search"].buttons["Settings"], timeout: 3)

        Base.app.navigationBars["Search"].buttons["Settings"].tap()
        Base.app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
        Base.app.textFields["url"].tap()
        Base.helper.waitForExistence(Base.app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        Base.app.textFields.firstMatch.press(forDuration: 1)
        Base.app.staticTexts["Paste"].tap()
        Base.helper.waitForExistence(Base.app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertTrue(Base.app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)
                                
        // Need to go step by step to Search Settings. The ScreenGraph will fail to go to the Search Settings Screen
        Base.app.buttons["urlBar-cancel"].tap()
        Base.app.buttons["TabToolbar.menuButton"].tap()
        Base.app.tables["Context Menu"].staticTexts["Settings"].tap()
        Base.app.tables.staticTexts["Google"].tap()
        navigator.performAction(Action.RemoveCustomSearchEngine)
        DismissSearchScreen()
        
        // Perform a search to check
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 3)
        Base.app.textFields["url"].tap()
        Base.helper.waitForExistence(Base.app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        Base.app.textFields.firstMatch.press(forDuration: 1)
        Base.app.staticTexts["Paste"].tap()

        Base.helper.waitForNoExistence(Base.app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertFalse(Base.app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)
    }
    
    private func DismissSearchScreen() {
        Base.helper.waitForExistence(Base.app.navigationBars["Search"].buttons["Settings"])
        Base.app.navigationBars["Search"].buttons["Settings"].tap()
        Base.app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testCustomEngineFromIncorrectTemplate() {
        navigator.goto(AddCustomSearchSettings)
        Base.app.textViews["customEngineTitle"].tap()
        Base.app.typeText("Feeling Lucky")
        
        UIPasteboard.general.string = "http://www.google.com/search?q=&btnI"
        
        let tablesQuery = Base.app.tables
        let customengineurlTextView = tablesQuery.textViews["customEngineUrl"]
        customengineurlTextView.staticTexts["URL (Replace Query with %s)"].tap()
        customengineurlTextView.press(forDuration: 1.0)
        Base.app.staticTexts["Paste"].tap()
        sleep(2)
        Base.app.navigationBars.buttons["customEngineSaveButton"].tap()

        Base.helper.waitForExistence(Base.app.alerts.element(boundBy: 0))
        XCTAssert(Base.app.alerts.element(boundBy: 0).label == "Failed")
    }
}
