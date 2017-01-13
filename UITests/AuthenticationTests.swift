/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class AuthenticationTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

    /**
     * Tests HTTP authentication credentials and auto-fill.
     */
    func testAuthentication() {
        loadAuthPage()

        // Make sure that 3 invalid credentials result in authentication failure.
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "foo", password: "bar")
        enterCredentials(usernameValue: "foo", passwordValue: "•••", username: "foo2", password: "bar2")
        enterCredentials(usernameValue: "foo2", passwordValue: "••••", username: "foo3", password: "bar3")
        tester().waitForWebViewElementWithAccessibilityLabel("auth fail")

        // Enter valid credentials and ensure the page loads.
        tester().tapView(withAccessibilityLabel: "Reload")
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Save the credentials.
        tester().tapView(withAccessibilityLabel: "Save Login")

        logOut()
        loadAuthPage()

        // Make sure the credentials were saved and auto-filled.
        tester().tapView(withAccessibilityLabel: "Log in")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Add a private tab.
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")

        loadAuthPage()

        // Make sure the auth prompt is shown.
        // Note that in the future, we might decide to auto-fill authentication credentials in private browsing mode,
        // but that's not currently supported. We assume the username and password fields are empty.
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

    }

    fileprivate func loadAuthPage() {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(webRoot)/auth.html\n")
    }

    fileprivate func logOut() {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(webRoot)/auth.html?logout=1\n")
        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    fileprivate func enterCredentials(usernameValue: String, passwordValue: String, username: String, password: String) {
        let usernameField = tester().waitForViewWithAccessibilityValue(usernameValue) as! UITextField
        let passwordField = tester().waitForViewWithAccessibilityValue(passwordValue) as! UITextField
        usernameField.text = username
        passwordField.text = password
        tester().tapView(withAccessibilityLabel: "Log in")
    }
}
