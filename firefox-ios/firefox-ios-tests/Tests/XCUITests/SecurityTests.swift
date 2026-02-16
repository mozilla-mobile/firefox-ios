// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class SecurityTests: BaseTestCase {
    let pocHtml = "https://storage.googleapis.com/mobile_test_assets/public/poc.html"

    func testLoadSpoofingHtmlReturnURL() {
        let browserScreen = BrowserScreen(app: app)
        navigator.openURL(pocHtml)
        waitUntilPageLoad()
        browserScreen.tapWebViewButton(buttonText: "Sign In to Google")
        waitUntilPageLoad()
        if #available(iOS 26.2, *) {
            browserScreen.assertAddressBarContains(value: "about:blank")
            browserScreen.assertWebElements(
                app.webViews.staticTexts["Sign in to Mozilla"],
                app.webViews.staticTexts["To continue to www.google.com"],
                app.webViews.secureTextFields["Password"],
                app.webViews.buttons["Sign In"]
            )
        } else {
            browserScreen.assertAddressBarContains(value: "google.com")
            browserScreen.assertWebElements(
                shouldExist: false,
                app.webViews.staticTexts["Sign in to Mozilla"],
                app.webViews.staticTexts["To continue to www.google.com"],
                app.webViews.secureTextFields["Password"],
                app.webViews.buttons["Sign In"],
            )
        }
        browserScreen.assertAddressBar_LockIconExist()
    }
}
