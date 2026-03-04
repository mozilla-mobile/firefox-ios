// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SecurityTests: BaseTestCase {
    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    private enum WebStrings {
        static let pocHtml = "https://storage.googleapis.com/mobile_test_assets/public/poc.html"
        static let netlify90URL = "https://test-port90.netlify.app/"
        static let netifly204URL = "https://test-http204.netlify.app/"
        static let netifly204AltURL = "https://test-http204alt.netlify.app/"
        static let netifly204Alt2URL = "https://test-http204alt2.netlify.app/"
        static let netifly800URL = "https://test-port800form.netlify.app/"
        static let netifly1121Reloaded = "https://test-same1121reload.netlify.app/"
        static let w3schoolURL = "https://www.w3schools.com/jsref/met_win_open.asp"
        static let expectedURL90 = "test-port90.netlif"
        static let expectedURL204 = "test-http204.netlify.app"
        static let expectedURL204Alt = "test-http204alt.netlify.app"
        static let expected1121ReloadedURL = "test-same1121reload.netlify.app"
        static let expectedW3SchoolURL = "w3schools.com"
        static let signInToGoogleButton = "Sign In to Google"
        static let signInToMozillaText = "Sign in to Mozilla"
        static let toContinueText = "To continue to www.google.com"
        static let passwordField = "Password"
        static let signInButton = "Sign In"
        static let aboutBlank = "about:blank"
        static let googleDotCom = "google.com"
        static let appleDotCom = "apple.com"
        static let startTestButton = "Start Test"
        static let submitButton = "Submit"
        static let errorDomain = "NSURLErrorDomain"
        static let demoText = "Demo: Address bar shows google.com, but content below is attacker-controlled."
        static let fakeHomePageText = "Fake Google Homepage!"
        static let fakeContentText = "Fake Content!!"
        static let inputAppleIdText = "Please input your Apple ID here:"
        static let usernameField = "username"
        static let passwordField2 = "password"
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395565
    func testLoadSpoofingHtmlReturnURL() {
        navigator.openURL(WebStrings.pocHtml)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.signInToGoogleButton)
        waitUntilPageLoad()
        if #available(iOS 26.2, *) {
            browserScreen.assertAddressBarContains(value: WebStrings.aboutBlank)
            browserScreen.assertWebElements(
                app.webViews.staticTexts[WebStrings.signInToMozillaText],
                app.webViews.staticTexts[WebStrings.toContinueText],
                app.webViews.secureTextFields[WebStrings.passwordField],
                app.webViews.buttons[WebStrings.signInButton]
            )
            browserScreen.assertAddressBar_LockIconOffExist()
        } else {
            browserScreen.assertAddressBarContains(value: WebStrings.googleDotCom)
            browserScreen.assertWebElements(
                shouldExist: false,
                app.webViews.staticTexts[WebStrings.signInToMozillaText],
                app.webViews.staticTexts[WebStrings.toContinueText],
                app.webViews.secureTextFields[WebStrings.passwordField],
                app.webViews.buttons[WebStrings.signInButton]
            )
            browserScreen.assertAddressBar_LockIconExist()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395566
    func testNetlify90() {
        navigator.openURL(WebStrings.netlify90URL)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.startTestButton)
        validateURLAndPageContent(URL: WebStrings.aboutBlank, elementsShouldExists: false)
        waitUntilPageLoad()
        validateURLAndPageContent(URL: WebStrings.expectedURL90, elementsShouldExists: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395567
    func testNetlify204() {
        navigator.openURL(WebStrings.netifly204URL)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.startTestButton)
        if #available(iOS 26.2, *) {
            validateURLAndPageContent(URL: WebStrings.aboutBlank, elementsShouldExists: true)
            waitUntilPageLoad()
            validateURLAndPageContent(URL: WebStrings.expectedURL204, elementsShouldExists: true)
        } else {
            waitUntilPageLoad()
            validateURLAndPageContent(URL: WebStrings.googleDotCom, elementsShouldExists: false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395568
    func testNetlify204Alt() {
        navigator.openURL(WebStrings.netifly204AltURL)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.startTestButton)
        if #available(iOS 26.2, *) {
            validateURLAndPageContent(URL: WebStrings.aboutBlank, elementsShouldExists: false)
            waitUntilPageLoad()
            browserScreen.assertAddressBarContains(value: WebStrings.expectedURL204Alt)
            browserScreen.assertWebElements(
                app.webViews.staticTexts[WebStrings.demoText]
            )
            browserScreen.assertWebElements(
                shouldExist: false,
                app.webViews.textFields[WebStrings.usernameField],
                app.webViews.secureTextFields[WebStrings.passwordField2]
            )
        } else {
            validateURLAndPageContent(URL: WebStrings.googleDotCom, elementsShouldExists: false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395569
    func testNetlify204Alt2() {
        navigator.openURL(WebStrings.netifly204Alt2URL)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.startTestButton)
        if #available(iOS 26.2, *) {
            validateURLAndPageContent(URL: WebStrings.aboutBlank, elementsShouldExists: false)
            waitUntilPageLoad()
            browserScreen.assertAddressBarContains(value: WebStrings.aboutBlank)
            browserScreen.assertWebElements(
                app.webViews.staticTexts[WebStrings.demoText],
                app.images.firstMatch
            )
            browserScreen.assertWebElements(
                shouldExist: false,
                app.webViews.textFields[WebStrings.usernameField],
                app.webViews.secureTextFields[WebStrings.passwordField2]
            )
        } else {
            validateURLAndPageContent(URL: WebStrings.googleDotCom, elementsShouldExists: false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395570
    func testNetlify800() {
        navigator.openURL(WebStrings.netifly800URL)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: WebStrings.submitButton)
        browserScreen.assertAddressBar_LockIconExist()
        browserScreen.assertAddressBarContains(value: WebStrings.aboutBlank)
        browserScreen.assertWebElements(
            app.webViews.staticTexts[WebStrings.fakeHomePageText]
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395571
    func testNetlify1121rReloaded() {
        let progressIndicator = app.progressIndicators.element(boundBy: 0)
        let endTime = Date().addingTimeInterval(TIMEOUT)
        navigator.openURL(WebStrings.netifly1121Reloaded)
        waitUntilPageLoad()
        while progressIndicator.exists && Date() < endTime {
            browserScreen.assertAddressBarContains(value: WebStrings.expected1121ReloadedURL)
            browserScreen.assertAddressBar_LockIconExist()
            browserScreen.assertWebElements(
                app.webViews.staticTexts[WebStrings.fakeContentText],
                app.webViews.staticTexts[WebStrings.inputAppleIdText]
            )
            RunLoop.current.run(until: (Date().addingTimeInterval(2.5)))
        }
        waitUntilPageLoad()
        if browserScreen.isAddressBarLockIconOffPresent() {
            browserScreen.assertAddressBarContains(value: WebStrings.appleDotCom)
            browserScreen.assertWebElements(
                app.webViews.staticTexts[WebStrings.errorDomain]
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3395576
    func testW3schoolsURL() {
        navigator.openURL(WebStrings.w3schoolURL)
        waitUntilPageLoad()
        browserScreen.assertAddressBarContains(value: WebStrings.expectedW3SchoolURL)
        browserScreen.assertAddressBar_LockIconExist()
        browserScreen.assertWebElements(
            app.webViews.firstMatch
        )
    }

    private func validateURLAndPageContent(URL: String, elementsShouldExists: Bool) {
        browserScreen.assertAddressBar_LockIconExist()
        browserScreen.assertAddressBarContains(value: URL)
        browserScreen.assertWebElements(
            shouldExist: elementsShouldExists,
            app.webViews.staticTexts[WebStrings.demoText],
            app.webViews.textFields[WebStrings.usernameField],
            app.webViews.secureTextFields[WebStrings.passwordField2]
        )
    }
}
