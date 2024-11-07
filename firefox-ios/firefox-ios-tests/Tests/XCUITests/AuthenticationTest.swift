// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let testBasicHTTPAuthURL = "https://jigsaw.w3.org/HTTP/Basic/"

class AuthenticationTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2360560
    func testBasicHTTPAuthenticationPromptVisibleAndLogin() {
        navigator.openURL(testBasicHTTPAuthURL)
        mozWaitForElementToExist(app.staticTexts["Authentication required"], timeout: 100)
        mozWaitForElementToExist(app.staticTexts[
            "A username and password are being requested by jigsaw.w3.org. The site says: test"
        ])
        let placeholderValueUsername = app.alerts.textFields.element(boundBy: 0)
        let placeholderValuePassword = app.alerts.secureTextFields.element(boundBy: 0)
        mozWaitForValueContains(placeholderValueUsername, value: "Username")
        mozWaitForValueContains(placeholderValuePassword, value: "Password")
        waitForElementsToExist(
            [
                app.alerts.buttons["Cancel"],
                app.alerts.buttons["Log in"]
            ]
        )
        app.alerts.textFields["Username"].typeText("guest")
        app.alerts.secureTextFields["Password"].tapAndTypeText("guest")
        app.alerts.buttons["Log in"].tap()
        /* There is no other way to verify basic auth is successful as the webview is
         inaccessible after sign in to verify the success text. */
        waitForNoExistence(app.alerts.buttons["Cancel"], timeoutValue: 5)
        waitForNoExistence(app.alerts.buttons["Log in"], timeoutValue: 5)
        // Added this check to ensure the BasicAuth login is persisting after app restart as well.
        app.terminate()
        app.launch()
        navigator.openURL(testBasicHTTPAuthURL)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.webViews["Web content"].staticTexts["Your browser made it!"])
    }
}
