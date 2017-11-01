/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey

class AuthenticationTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
		BrowserUtils.dismissFirstRunUI()
	}
	
    override func tearDown() {
		BrowserUtils.resetToAboutHome(tester())
		BrowserUtils.clearPrivateData(tester: tester())
		super.tearDown()
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
        
        // Use KIFTest framework for checking elements within webView
        tester().waitForWebViewElementWithAccessibilityLabel("auth fail")

        // Enter valid credentials and ensure the page loads.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reload")).perform(grey_tap())
		enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Save the credentials.
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")
        
        logOut()
        loadAuthPage()

        // Make sure the credentials were saved and auto-filled.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Log in"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Add a private tab.
        if BrowserUtils.iPad() {
            EarlGrey.select(elementWithMatcher:grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabTrayController.maskButton"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabTrayController.addTabButton"))
            .perform(grey_tap())
        loadAuthPage()

        // Make sure the auth prompt is shown.
        // Note that in the future, we might decide to auto-fill authentication credentials in private browsing mode,
        // but that's not currently supported. We assume the username and password fields are empty.
        enterCredentials(usernameValue: "Username", passwordValue: "Password", username: "user", password: "pass")
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

    }

    fileprivate func loadAuthPage() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText("\(webRoot!)/auth.html"))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
    }

    fileprivate func logOut() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText("\(webRoot!)/auth.html?logout=1"))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
        // Wait until the dialog shows up
		let dialogAppeared = GREYCondition(name: "Wait the login dialog to appear", block: { _ in
			var errorOrNil: NSError?
			let matcher = grey_allOf([grey_accessibilityLabel("Cancel"),
			                                 grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher)
				.inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
				.assert(grey_notNil(), error: &errorOrNil)
			let success = errorOrNil == nil
			return success
		}).wait(withTimeout: 20)
		
		GREYAssertTrue(dialogAppeared, reason: "Failed to display login dialog")

        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Cancel"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .perform(grey_tap())
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
