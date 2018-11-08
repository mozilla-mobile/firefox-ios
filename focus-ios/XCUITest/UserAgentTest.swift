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

    func testSignInWithGoogle() {
        loadWebPage("https://getpocket.com/login?s=homepage/")
        let signInButton = app.webViews.buttons["Log In with Google"]
        waitforExistence(element: signInButton)
        signInButton.tap()
        waitForWebPageLoad()
        waitforNoExistence(element: app.webViews.staticTexts["Error: disallowed_useragent"])
    }

}
