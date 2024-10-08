// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class URLValidationTests: BaseTestCase {
    let urlTypes = ["www.mozilla.org", "www.mozilla.org/", "https://www.mozilla.org", "www.mozilla.org/en", "www.mozilla.org/en-",
                    "www.mozilla.org/en-US", "https://www.mozilla.org/", "https://www.mozilla.org/en", "https://www.mozilla.org/en-US"]
    let urlHttpTypes = ["http://example.com", "http://example.com/"]
    let url = XCUIApplication().textFields[AccessibilityIdentifiers.Browser.UrlBar.url]

    override func setUp() {
        super.setUp()
        continueAfterFailure = true
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
        scrollToElement(app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"])
        app.tables.switches["FirefoxSuggestShowNonSponsoredSuggestions"].tap()
        navigator.goto(NewTabScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2460854
    // Smoketest
    func testDifferentURLTypes() {
        for i in urlTypes {
            navigator.openURL(i)
            waitUntilPageLoad()
            mozWaitForElementToExist(app.otherElements.staticTexts["Mozilla"])
            mozWaitForElementToExist(app.buttons["Menu"])
            mozWaitForValueContains(url, value: "www.mozilla.org/en-US/")
            clearURL()
        }

        for i in urlHttpTypes {
            navigator.openURL(i)
            waitUntilPageLoad()
            mozWaitForElementToExist(app.otherElements.staticTexts["Example Domain"])
            mozWaitForValueContains(url, value: "example.com/")
            clearURL()
        }
    }

    private func clearURL() {
        if iPad() {
            navigator.goto(URLBarOpen)
            mozWaitForElementToExist(app.buttons["Clear text"])
            app.buttons["Clear text"].tap()
        }
    }
}
