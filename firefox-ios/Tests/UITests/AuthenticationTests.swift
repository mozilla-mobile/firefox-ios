// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class AuthenticationTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        tester().wait(forTimeInterval: 10)
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
	}

    override func tearDown() {
        tester().wait(forTimeInterval: 3)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
		super.tearDown()
    }

    /**
     * Tests HTTP authentication credentials and auto-fill.
     */
    func testAuthentication() {
        tester().wait(forTimeInterval: 10)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        loadAuthPage()
        tester().wait(forTimeInterval: 3)
        // Make sure that 3 invalid credentials result in authentication failure.
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "foo", password: "bar")
        enterCredentials(usernameValue: "foo", passwordValue: "•••", username: "foo2", password: "bar2")
        enterCredentials(usernameValue: "foo2", passwordValue: "••••", username: "foo3", password: "bar3")

        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        // Use KIFTest framework for checking elements within webView
        tester().waitForWebViewElementWithAccessibilityLabel("auth fail")

        // Enter valid credentials and ensure the page loads.
        tester().tapView(withAccessibilityLabel: "Reload")
		enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Save the credentials.
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        logOut()
        loadAuthPage()

        // Make sure the credentials were saved and auto-filled.
        tester().tapView(withAccessibilityLabel: "Log in")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Add a private tab.
        tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.Toolbar.tabsButton)
        tester().tapView(withAccessibilityLabel: "smallPrivateMask")
        tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.TabTray.newTabButton)
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 10)
        loadAuthPage()

        // Make sure the auth prompt is shown.
        // Note that in the future, we might decide to auto-fill authentication credentials in private browsing mode,
        // but that's not currently supported. We assume the username and password fields are empty.
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")
    }

    fileprivate func loadAuthPage() {
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: "\(webRoot!)/auth.html")
    }

    fileprivate func logOut() {
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: "\(webRoot!)/auth.html?logout=1")
        // Wait until the dialog shows up
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    fileprivate func enterCredentials(usernameValue: String, passwordValue: String, username: String, password: String) {

        // In case of IPad, Earl Grey complains that UI Loop has not been finished for password field, reverting.
        let usernameField = tester().waitForViewWithAccessibilityValue(usernameValue) as! UITextField
        let passwordField = tester().waitForViewWithAccessibilityValue(passwordValue) as! UITextField
        usernameField.text = username
        passwordField.text = password
        tester().tapView(withAccessibilityLabel: "Log in")
	}
}
