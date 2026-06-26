// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let testBasicHTTPAuthURL = "https://jigsaw.w3.org/HTTP/Basic/"

class AuthenticationTest: BaseTestCase {
    let username = "Username"
    let password = "Password"
    // https://mozilla.testrail.io/index.php?/cases/view/2360560
    func testBasicHTTPAuthenticationPromptVisibleAndLogin() {
        let browserScreen = BrowserScreen(app: app)
        navigator.openURL(testBasicHTTPAuthURL)
        waitUntilPageLoad()

        // Wait for the element to appear within the timeout
        if !app.staticTexts["Authentication required"].mozWaitForElementToExist(timeout: 5, failOnTimeout: false) {
            // User already logged, tap on reload button
            app.buttons["TabLocationView.reloadButton"].waitAndTap()
            waitUntilPageLoad()
        }
        browserScreen.tapWebViewTextIfExists(text: "Verify you are human")
        waitUntilPageLoad()
        mozWaitForElementToExist(app.staticTexts[
            "A username and password are being requested by jigsaw.w3.org. The site says: test"
        ])
        let placeholderValueUsername = app.alerts.textFields.element(boundBy: 0)
        let placeholderValuePassword = app.alerts.secureTextFields.element(boundBy: 0)
        mozWaitForValueContains(placeholderValueUsername, value: username)
        mozWaitForValueContains(placeholderValuePassword, value: password)
        waitForElementsToExist(
            [
                app.alerts.buttons["Cancel"],
                app.alerts.buttons["Log in"]
            ]
        )
        logIn()
        waitUntilPageLoad()
        /* There is no other way to verify basic auth is successful as the webview is
         inaccessible after sign in to verify the success text. */
        mozWaitForElementToNotExist(app.alerts.buttons["Cancel"], timeout: 5)
        mozWaitForElementToNotExist(app.alerts.buttons["Log in"], timeout: 5)
        // Added this check to ensure the BasicAuth login is persisting after app restart as well.
        forceRestartApp()
        navigator.openURL(testBasicHTTPAuthURL)
        waitUntilPageLoad()
        navigator.nowAt(NewTabScreen)
        if app.alerts.buttons["Log in"].exists {
            logIn()
            waitUntilPageLoad()
        }
        mozWaitForElementToExist(app.webViews["Web content"].staticTexts["Your browser made it!"])
    }

    private func logIn() {
        let guestLabel = "guest"
        let LoginLabel = "Log in"
        app.alerts.textFields[username].typeText(guestLabel)
        app.alerts.secureTextFields[password].tapAndTypeText(guestLabel)
        app.alerts.buttons[LoginLabel].firstMatch.waitAndTap()
    }
}
