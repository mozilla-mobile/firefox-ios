/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class LoginInputTests: KIFTestCase {
    fileprivate var webRoot: String!
    fileprivate var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        super.tearDown()
        clearLogins()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

    fileprivate func clearLogins() {
        profile.logins.removeAll().value
    }

    func testLoginFormDisplaysNewSnackbar() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("password", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForView(withAccessibilityLabel: "Save login \(username) for \(webRoot)?")
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.dontSaveButton")
    }

    func testLoginFormDisplaysUpdateSnackbarIfPreviouslySaved() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = "password2"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForView(withAccessibilityLabel: "Save login \(username) for \(webRoot)?")
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForView(withAccessibilityLabel: "Update login \(username) for \(webRoot)?")
        tester().tapView(withAccessibilityIdentifier: "UpdateLoginPrompt.updateButton")
    }

    func testLoginFormDoesntOfferSaveWhenEmptyPassword() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        // Wait a bit then verify that we haven't shown the prompt
        tester().wait(forTimeInterval: 2)
        XCTAssertFalse(tester().viewExistsWithLabel("Save login \(username) for \(webRoot)?"))
    }

    func testLoginFormDoesntOfferUpdateWhenEmptyPassword() {
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = ""
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForView(withAccessibilityLabel: "Save login \(username) for \(webRoot)?")
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        // Wait a bit then verify that we haven't shown the prompt
        tester().wait(forTimeInterval: 2)
        XCTAssertFalse(tester().viewExistsWithLabel("Save login \(username) for \(webRoot)?"))
    }
}
