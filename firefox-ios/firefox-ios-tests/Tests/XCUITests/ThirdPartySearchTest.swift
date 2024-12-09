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

        app.navigationBars["Search"].buttons["Settings"].waitAndTap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()

        // Perform a search using a custom search engine
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        app.textFields.firstMatch.waitAndTap()
        app.textFields.firstMatch.typeText("window")
        app.scrollViews.otherElements.buttons["Mozilla Engine search"].tap()
        waitUntilPageLoad()

        guard let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the browser's URL bar")
            return
        }
        XCTAssertEqual(url, "developer.mozilla.org", "The URL should indicate that the search was performed on MDN and not the default")
        mozWaitForElementToExist(app.staticTexts["MDN"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2444328
    func testCustomSearchEngineAsDefault() {
        addCustomSearchEngine()

        // Go to settings and set MDN as the default
        app.tables.staticTexts["Google"].waitAndTap()
        app.tables.staticTexts["Mozilla Engine"].waitAndTap()
        dismissSearchScreen()

        // Perform a search to check
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()
        app.textFields.firstMatch.typeText("window\n")

        waitUntilPageLoad()

        // Ensure that the default search is MDN
        guard let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value
                as? String else {
            XCTFail("Failed to retrieve the URL value from the browser's URL bar")
            return
        }
        XCTAssert(url.hasPrefix("developer.mozilla.org"), "The URL should indicate that the search was performed on MDN and not the default")
        mozWaitForElementToExist(app.staticTexts["MDN"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306941
    func testCustomSearchEngineDeletion() {
        addCustomSearchEngine()

        app.navigationBars["Search"].buttons["Settings"].waitAndTap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        app.textFields.firstMatch.waitAndTap()
        app.textFields.firstMatch.typeText("window")
        mozWaitForElementToExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])

        // Need to go step by step to Search Settings. The ScreenGraph will fail to go to the Search Settings Screen
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        navigator.goto(SearchSettings)

        navigator.performAction(Action.RemoveCustomSearchEngine)
        dismissSearchScreen()

        // Perform a search to check
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].waitAndTap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
        app.textFields.firstMatch.waitAndTap()
        app.textFields.firstMatch.typeText("window")
        mozWaitForElementToNotExist(app.scrollViews.otherElements.buttons["Mozilla Engine search"])
    }

    private func addCustomSearchEngine() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.AddCustomSearchEngine)
        app.buttons["customEngineSaveButton"].waitAndTap()
        if #unavailable(iOS 16) {
            // Wait for "Fennec pasted from XCUITests-Runner" banner to disappear
            sleep(2)
        }
    }

    private func dismissSearchScreen() {
        app.navigationBars["Search"].buttons["Settings"].waitAndTap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
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

        app.buttons["customEngineSaveButton"].waitAndTap()
        app.navigationBars["Add Search Engine"].buttons["Save"].waitAndTap()

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
