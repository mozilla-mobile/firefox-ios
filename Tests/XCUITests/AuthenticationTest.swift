// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let testBasicHTTPAuthURL = "https://jigsaw.w3.org/HTTP/Basic/"

class AuthenticationTest: BaseTestCase {
    func testBasicHTTPAuthenticationPromptVisible() {
        mozWaitForElementToExist(app.textFields["url"], timeout: 5)
        navigator.nowAt(NewTabScreen)
        navigator.openURL(testBasicHTTPAuthURL)
        mozWaitForElementToExist(app.staticTexts["Authentication required"], timeout: 100)
        mozWaitForElementToExist(app.staticTexts["A username and password are being requested by jigsaw.w3.org. The site says: test"])

        let placeholderValueUsername = app.alerts.textFields.element(boundBy: 0).value as! String
        let placeholderValuePassword = app.alerts.secureTextFields.element(boundBy: 0).value as! String

        XCTAssertEqual(placeholderValueUsername, "Username")
        XCTAssertEqual(placeholderValuePassword, "Password")

        mozWaitForElementToExist(app.alerts.buttons["Cancel"])
        mozWaitForElementToExist(app.alerts.buttons["Log in"])

        // Skip login due to HTTP Basic Authentication crash in #5757
        // Dismiss authentication prompt
        app.alerts.buttons["Cancel"].tap()
        mozWaitForElementToNotExist(app.alerts.buttons["Cancel"])
    }
}
