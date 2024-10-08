// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let testBasicHTTPAuthURL = "https://jigsaw.w3.org/HTTP/Basic/"

class AuthenticationTest: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2360560
    func testBasicHTTPAuthenticationPromptVisible() {
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
        navigator.nowAt(NewTabScreen)
        navigator.openURL(testBasicHTTPAuthURL)
        mozWaitForElementToExist(app.staticTexts["Authentication required"], timeout: 100)
        mozWaitForElementToExist(app.staticTexts[
            "A username and password are being requested by jigsaw.w3.org. The site says: test"
        ])

        let placeholderValueUsername = app.alerts.textFields.element(boundBy: 0)
        let placeholderValuePassword = app.alerts.secureTextFields.element(boundBy: 0)

        mozWaitForValueContains(placeholderValueUsername, value: "Username")
        mozWaitForValueContains(placeholderValuePassword, value: "Password")

        mozWaitForElementToExist(app.alerts.buttons["Cancel"])
        mozWaitForElementToExist(app.alerts.buttons["Log in"])

        // Skip login due to HTTP Basic Authentication crash in #5757
        // Dismiss authentication prompt
        app.alerts.buttons["Cancel"].tap()
        mozWaitForElementToNotExist(app.alerts.buttons["Cancel"])
    }
}
