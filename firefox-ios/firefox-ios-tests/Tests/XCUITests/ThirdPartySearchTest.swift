// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let mozDeveloperWebsite = "https://developer.mozilla.org/en-US"
let searchFieldPlaceholder = "Search MDN"
class ThirdPartySearchTest: BaseTestCase {
    fileprivate func dismissKeyboardAssistant(forApp app: XCUIApplication) {
        app.buttons["Done"].tap()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2443998
    func testCustomSearchEngines() {
        addCustomSearchEngine()

        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"], timeout: 3)
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        // Perform a search using a custom search engine
        app.textFields["url"].tap()
        mozWaitForElementToExist(app.buttons["urlBar-cancel"])
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

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2444328
    func testCustomSearchEngineAsDefault() {
        addCustomSearchEngine()

        // Go to settings and set MDN as the default
        mozWaitForElementToExist(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()
        mozWaitForElementToExist(app.tables.staticTexts["Mozilla Engine"])
        app.tables.staticTexts["Mozilla Engine"].tap()
        dismissSearchScreen()

        // Perform a search to check
        app.textFields["url"].tap()
        app.textFields.firstMatch.typeText("window\n")

        waitUntilPageLoad()

        // Ensure that the default search is MDN
        var url = app.textFields["url"].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306941
    func testCustomSearchEngineDeletion() {
        addCustomSearchEngine()
        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"], timeout: 3)

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
        app.textFields["url"].tap()
        mozWaitForElementToExist(app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()
        mozWaitForElementToExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertTrue(app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)

        // Need to go step by step to Search Settings. The ScreenGraph will fail to go to the Search Settings Screen
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 3)
        app.buttons["urlBar-cancel"].tap()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        app.tables["Context Menu"].otherElements["Settings"].tap()
        mozWaitForElementToExist(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()

        navigator.performAction(Action.RemoveCustomSearchEngine)
        dismissSearchScreen()

        // Perform a search to check
        mozWaitForElementToExist(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        mozWaitForElementToExist(app.buttons["urlBar-cancel"])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()

        mozWaitForElementToNotExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        XCTAssertFalse(app.scrollViews.otherElements.buttons["Mozilla Engine search"].exists)
    }

    private func addCustomSearchEngine() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.AddCustomSearchEngine)
        mozWaitForElementToExist(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()
    }

    private func dismissSearchScreen() {
        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"])
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2444333
    func testCustomEngineFromIncorrectTemplate() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(AddCustomSearchSettings)
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")

        let searchUrl = "http://www.google.com/search?q=&btnI"
        let tablesQuery = app.tables
        let customengineurlTextView = tablesQuery.textViews["customEngineUrl"].staticTexts["URL (Replace Query with %s)"]

        XCTAssertTrue(customengineurlTextView.exists)

        UIPasteboard.general.string = searchUrl
        customengineurlTextView.tap()
        customengineurlTextView.press(forDuration: 2.0)
        app.staticTexts["Paste"].tap()

        mozWaitForElementToExist(app.buttons["customEngineSaveButton"], timeout: 3)
        app.buttons["customEngineSaveButton"].tap()
        mozWaitForElementToExist(app.navigationBars["Add Search Engine"], timeout: 3)
        app.navigationBars["Add Search Engine"].buttons["Save"].tap()

        mozWaitForElementToExist(app.alerts.element(boundBy: 0))
        XCTAssertTrue(app.alerts.staticTexts["Failed"].exists, "Alert title is missing or is incorrect")
        XCTAssertTrue(app.alerts.staticTexts["Please fill all fields correctly."].exists, "Alert message is missing or is incorrect")
    }
}
