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
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Save Login"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.SnackButton")!))
            .perform(grey_tap())
        
        logOut()
        loadAuthPage()

        // Make sure the credentials were saved and auto-filled.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Log in"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("logged in")

        // Add a private tab.
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel("New Private Tab"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.MenuItemCollectionViewCell")!))
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
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\(webRoot!)/auth.html\n"))
    }

    fileprivate func logOut() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\(webRoot!)/auth.html?logout=1\n"))
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
		
		// Wait until the dialog shows up
		let dialogAppeared = GREYCondition(name: "Wait the login dialog to appear", block: { () -> Bool in
			var errorOrNil: NSError?
			let matcher = grey_allOf([grey_accessibilityValue(usernameValue),
				grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher).assert(grey_notNil(), error: &errorOrNil)
			let success = errorOrNil == nil
			return success
        })
		
        let success = dialogAppeared?.wait(withTimeout: 20)
		GREYAssertTrue(success!, reason: "Failed to display login dialog")
		
        let usernameField = EarlGrey.select(elementWithMatcher: grey_accessibilityValue(usernameValue))
        let passwordField = EarlGrey.select(elementWithMatcher: grey_accessibilityValue(passwordValue))
        
        if usernameValue != "Username" {
            usernameField.perform(grey_doubleTap())
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Select All"))
                .inRoot(grey_kindOfClass(NSClassFromString("UICalloutBarButton")!))
                .perform(grey_tap())
        }
        
        usernameField.perform(grey_typeText(username))
        passwordField.perform(grey_typeText(password))
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Log in"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .perform(grey_tap())
	}
}
