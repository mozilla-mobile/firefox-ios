/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class UserAgentTest: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testSignUpWithGoogle() {
        loadWebPage("getpocket.com")
        let signUpButton = app.webViews.buttons["Sign Up with Google"]
        waitforExistence(element: signUpButton)
        signUpButton.tap()
        waitForWebPageLoad()
        waitforNoExistence(element: app.webViews.staticTexts["Error: disallowed_useragent"])
    }

}
