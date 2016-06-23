/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class LoginInputTests: KIFTestCase {
    private var webRoot: String!
    private var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        clearLogins()
    }

    private func clearLogins() {
        profile.logins.removeAll().value
    }

    func testLoginFormDisplaysNewSnackbar() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("password", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForViewWithAccessibilityLabel("Save login \(username) for \(webRoot)?")
        tester().tapViewWithAccessibilityIdentifier("SaveLoginPrompt.dontSaveButton")
    }

    func testLoginFormDisplaysUpdateSnackbarIfPreviouslySaved() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = "password2"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForViewWithAccessibilityLabel("Save login \(username) for \(webRoot)?")
        tester().tapViewWithAccessibilityIdentifier("SaveLoginPrompt.saveLoginButton")

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForViewWithAccessibilityLabel("Update login \(username) for \(webRoot)?")
        tester().tapViewWithAccessibilityIdentifier("UpdateLoginPrompt.updateButton")
    }

    func testLoginFormDoesntOfferSaveWhenEmptyPassword() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        // Wait a bit then verify that we haven't shown the prompt
        tester().waitForTimeInterval(2)
        XCTAssertFalse(tester().viewExistsWithLabel("Save login \(username) for \(webRoot)?"))
    }

    func testLoginFormDoesntOfferUpdateWhenEmptyPassword() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = ""
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForViewWithAccessibilityLabel("Save login \(username) for \(webRoot)?")
        tester().tapViewWithAccessibilityIdentifier("SaveLoginPrompt.saveLoginButton")

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        // Wait a bit then verify that we haven't shown the prompt
        tester().waitForTimeInterval(2)
        XCTAssertFalse(tester().viewExistsWithLabel("Save login \(username) for \(webRoot)?"))
    }
}
