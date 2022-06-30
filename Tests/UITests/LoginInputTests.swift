// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import Client

class LoginInputTests: KIFTestCase {
    fileprivate var webRoot: String!
    fileprivate var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        _ = profile.logins.wipeLocal().value
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }

    func testLoginFormDisplaysNewSnackbar() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("password", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().waitForView(withAccessibilityLabel: "Save login \(username) for \(self.webRoot!)?")

        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.dontSaveButton")
    }

    func testLoginFormDisplaysUpdateSnackbarIfPreviouslySaved() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = "password2"

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().waitForAnimationsToFinish()
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 1)
        tester().waitForAnimationsToFinish(withTimeout: 3)
        
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 1)
        tester().waitForView(withAccessibilityLabel: "Update login \(username) for \(self.webRoot!)?")
        tester().tapView(withAccessibilityIdentifier: "UpdateLoginPrompt.updateButton")
    }

    func testLoginFormDoesntOfferSaveWhenEmptyPassword() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Save login \(username) for \(self.webRoot!)?")
    }

    func testLoginFormDoesntOfferUpdateWhenEmptyPassword() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = ""

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().waitForView(withAccessibilityLabel: "Save login \(username) for \(self.webRoot!)?")
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Save login \(username) for \(self.webRoot!)?")
    }
}
