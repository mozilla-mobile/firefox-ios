/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
@testable import Client

class LoginInputTests: KIFTestCase {
    fileprivate var webRoot: String!
    fileprivate var profile: Profile!

    override func setUp() {
        super.setUp()
        profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        webRoot = SimplePageServer.start()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    override func tearDown() {
        _ = profile.logins.wipeLocal().value
        BrowserUtils.resetToAboutHome()
        BrowserUtils.clearPrivateData()
        super.tearDown()
    }

    func waitForLoginDialog(text: String, appears: Bool = true) {
        var success = false
        var failedReason = "Failed to display dialog"

        if appears == false {
            failedReason = "Dialog still displayed"
        }

        let saveLoginDialog = GREYCondition(name: "Check login dialog appears", block: {
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel(text),
                                              grey_sufficientlyVisible()])
            EarlGrey.selectElement(with: matcher)
                .assert(grey_notNil(), error: &errorOrNil)
            if appears == true {
                success = errorOrNil == nil
            } else {
                success = errorOrNil != nil
            }
            return success
        }).wait(withTimeout: 10)

        GREYAssertTrue(saveLoginDialog, reason: failedReason)
    }

    func testLoginFormDisplaysNewSnackbar() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"

        BrowserUtils.enterUrlAddressBar(typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("password", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        waitForLoginDialog(text: "Save login \(username) for \(self.webRoot!)?")
        EarlGrey.selectElement(with: grey_accessibilityID("SaveLoginPrompt.dontSaveButton")).perform(grey_tap())
    }

    func testLoginFormDisplaysUpdateSnackbarIfPreviouslySaved() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = "password2"

        BrowserUtils.enterUrlAddressBar(typeUrl: url)
        tester().waitForAnimationsToFinish()
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 1)
        waitForLoginDialog(text: "Save login \(username) for \(self.webRoot!)?")
        
        tester().tapView(withAccessibilityIdentifier: "SaveLoginPrompt.saveLoginButton")
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 1)
        waitForLoginDialog(text: "Update login \(username) for \(self.webRoot!)?")
        tester().tapView(withAccessibilityIdentifier: "UpdateLoginPrompt.updateButton")
    }

    func testLoginFormDoesntOfferSaveWhenEmptyPassword() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"

        BrowserUtils.enterUrlAddressBar(typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText("", intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")

        waitForLoginDialog(text: "Save login \(username) for \(self.webRoot!)?", appears: false)
    }

    func testLoginFormDoesntOfferUpdateWhenEmptyPassword() {
        let url = "\(webRoot!)/loginForm.html"
        let username = "test@user.com"
        let password1 = "password1"
        let password2 = ""

        BrowserUtils.enterUrlAddressBar(typeUrl: url)
        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password1, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        waitForLoginDialog(text: "Save login \(username) for \(self.webRoot!)?")
        EarlGrey.selectElement(with: grey_accessibilityID("SaveLoginPrompt.saveLoginButton"))
            .perform(grey_tap())

        tester().enterText(username, intoWebViewInputWithName: "username")
        tester().enterText(password2, intoWebViewInputWithName: "password")
        tester().tapWebViewElementWithAccessibilityLabel("submit_btn")
        waitForLoginDialog(text: "Save login \(username) for \(self.webRoot!)?", appears: false)
    }
}
