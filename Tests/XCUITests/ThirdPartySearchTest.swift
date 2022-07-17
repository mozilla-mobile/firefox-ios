// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let mozDeveloperWebsite = "https://developer.mozilla.org/en-US"
let searchFieldPlaceholder = "Search MDN"
class ThirdPartySearchTest: BaseTestCase {
    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        app.buttons["Done"].tap()
    }

    func testCustomSearchEngines() {
        addCustomSearchEngine()

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
        addCustomSearchEngine()

        // Go to settings and set MDN as the default
        waitForExistence(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()
        waitForExistence(app.tables.staticTexts["Mozilla Engine"])
        app.tables.staticTexts["Mozilla Engine"].tap()
        dismissSearchScreen()

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
        addCustomSearchEngine()
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
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 3)
        app.buttons["urlBar-cancel"].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        app.tables["Context Menu"].otherElements["Settings"].tap()
        waitForExistence(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()

        navigator.performAction(Action.RemoveCustomSearchEngine)
        dismissSearchScreen()

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

    private func addCustomSearchEngine() {
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.AddCustomSearchEngine)
        waitForExistence(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()
        // Workaround for iOS14 need to wait for those elements and tap again
        if !iPad() {
            if #available(iOS 14.0, *) {
                waitForExistence(app.navigationBars["Add Search Engine"], timeout: 3)
                app.navigationBars["Add Search Engine"].buttons["Save"].tap()
            }
        }
    }

    private func dismissSearchScreen() {
        waitForExistence(app.navigationBars["Search"].buttons["Settings"])
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testCustomEngineFromIncorrectTemplate() {
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(AddCustomSearchSettings)
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")

        UIPasteboard.general.string = "http://www.google.com/search?q=&btnI"

        let tablesQuery = app.tables
        let customengineurlTextView = tablesQuery.textViews["customEngineUrl"].staticTexts["URL (Replace Query with %s)"]

        XCTAssertTrue(customengineurlTextView.exists)
        customengineurlTextView.tap()
        customengineurlTextView.press(forDuration: 2.0)
        app.staticTexts["Paste"].tap()

        waitForExistence(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()
        waitForExistence(app.navigationBars["Add Search Engine"], timeout: 3)
        app.navigationBars["Add Search Engine"].buttons["Save"].tap()

        waitForExistence(app.alerts.element(boundBy: 0))
        XCTAssert(app.alerts.element(boundBy: 0).label == "Failed")
    }
}
