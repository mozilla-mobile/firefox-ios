// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SecurityTests: BaseTestCase {
    private enum WebStrings {
        static let pocHtml = "https://storage.googleapis.com/mobile_test_assets/public/poc.html"
        static let signInToGoogleButton = "Sign In to Google"
        static let signInToMozillaText = "Sign in to Mozilla"
        static let toContinueText = "To continue to www.google.com"
        static let passwordField = "Password"
        static let signInButton = "Sign In"
        static let aboutBlank = "about:blank"
        static let googleDotCom = "google.com"
    }

    func testLoadSpoofingHtmlReturnURL() {
        let browserScreen = BrowserScreen(app: app)
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
        } else {
            browserScreen.assertAddressBarContains(value: WebStrings.googleDotCom)
            browserScreen.assertWebElements(
                shouldExist: false,
                app.webViews.staticTexts[WebStrings.signInToMozillaText],
                app.webViews.staticTexts[WebStrings.toContinueText],
                app.webViews.secureTextFields[WebStrings.passwordField],
                app.webViews.buttons[WebStrings.signInButton]
            )
        }
        browserScreen.assertAddressBar_LockIconExist()
    }
}
