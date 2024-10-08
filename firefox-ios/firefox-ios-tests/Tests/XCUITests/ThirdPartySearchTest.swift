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

    // https://mozilla.testrail.io/index.php?/cases/view/2443998
    func testCustomSearchEngines() {
        addCustomSearchEngine()

        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"])
        app.navigationBars["Search"].buttons["Settings"].tap()
        mozWaitForElementToExist(app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem])
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        // Perform a search using a custom search engine
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()
        app.scrollViews.otherElements.buttons["Mozilla Engine search"].tap()
        waitUntilPageLoad()

        var url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2444328
    func testCustomSearchEngineAsDefault() {
        addCustomSearchEngine()

        // Go to settings and set MDN as the default
        mozWaitForElementToExist(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()
        mozWaitForElementToExist(app.tables.staticTexts["Mozilla Engine"])
        app.tables.staticTexts["Mozilla Engine"].tap()
        dismissSearchScreen()

        // Perform a search to check
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].tap()
        app.textFields.firstMatch.typeText("window\n")

        waitUntilPageLoad()

        // Ensure that the default search is MDN
        var url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].value as! String
        if url.hasPrefix("https://") == false {
            url = "https://\(url)"
        }
        XCTAssert(url.hasPrefix("https://developer.mozilla.org/en-US/search"), "The URL should indicate that the search was performed on MDN and not the default")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306941
    func testCustomSearchEngineDeletion() {
        addCustomSearchEngine()
        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"])

        app.navigationBars["Search"].buttons["Settings"].tap()
        mozWaitForElementToExist(app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem])
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        UIPasteboard.general.string = "window"
        app.textFields.firstMatch.press(forDuration: 1)
        app.staticTexts["Paste"].tap()
        mozWaitForElementToExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])

        // Need to go step by step to Search Settings. The ScreenGraph will fail to go to the Search Settings Screen
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        app.tables["Context Menu"].otherElements["Settings"].tap()
        mozWaitForElementToExist(app.tables.staticTexts["Google"])
        app.tables.staticTexts["Google"].tap()

        // Action.RemoveCustomSearchEngine does not work on iOS 15
        if #available(iOS 16, *) {
            navigator.performAction(Action.RemoveCustomSearchEngine)
            dismissSearchScreen()

            // Perform a search to check
            mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
            app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].tap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
            UIPasteboard.general.string = "window"
            app.textFields.firstMatch.press(forDuration: 1)
            app.staticTexts["Paste"].tap()

            mozWaitForElementToNotExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
        }
    }

    private func addCustomSearchEngine() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.AddCustomSearchEngine)
        mozWaitForElementToExist(app.buttons["customEngineSaveButton"])
        app.buttons["customEngineSaveButton"].tap()
        if #unavailable(iOS 16) {
            // Wait for "Fennec pasted from XCUITests-Runner" banner to disappear
            sleep(2)
        }
    }

    private func dismissSearchScreen() {
        mozWaitForElementToExist(app.navigationBars["Search"].buttons["Settings"])
        app.navigationBars["Search"].buttons["Settings"].tap()
        mozWaitForElementToExist(app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem])
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2444333
    func testCustomEngineFromIncorrectTemplate() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(AddCustomSearchSettings)
        app.textViews["customEngineTitle"].tap()
        app.typeText("Feeling Lucky")

        let searchUrl = "http://www.google.com/search?q=&btnI"
        let tablesQuery = app.tables
        let customengineurlTextView = tablesQuery
            .textViews["customEngineUrl"]
            .staticTexts["URL (Replace Query with %s)"]

        mozWaitForElementToExist(customengineurlTextView)

        UIPasteboard.general.string = searchUrl
        customengineurlTextView.tap()
        customengineurlTextView.press(forDuration: 2.0)
        let pasteOption = app.menuItems["Paste"]
        if pasteOption.exists {
            pasteOption.tap()
        } else {
            var nrOfTaps = 3
            while !pasteOption.exists && nrOfTaps > 0 {
                customengineurlTextView.press(forDuration: 2.0)
                nrOfTaps -= 1
            }
            pasteOption.tap()
        }

        mozWaitForElementToExist(app.buttons["customEngineSaveButton"])
        app.buttons["customEngineSaveButton"].tap()
        mozWaitForElementToExist(app.navigationBars["Add Search Engine"])
        app.navigationBars["Add Search Engine"].buttons["Save"].tap()

        // The alert appears on iOS 15 but it disappears by itself immediately.
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.alerts.element(boundBy: 0))
            XCTAssertTrue(
                app.alerts.staticTexts["Failed"].exists,
                "Alert title is missing or is incorrect"
            )
            XCTAssertTrue(
                app.alerts.staticTexts["Please fill all fields correctly."].exists,
                "Alert message is missing or is incorrect"
            )
        }
    }
}
