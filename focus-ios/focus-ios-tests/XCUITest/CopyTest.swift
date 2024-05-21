/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

// Note: this test is tested as part of the base test case, and thus is disabled here.

class CopyTest: BaseTestCase {
    func testCopyMenuItem() throws {
        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage("https://www.example.com")
        waitForWebPageLoad()

        // Must offset textfield press to support 5S.
        urlBarTextField.press(forDuration: 2)
        waitForExistence(app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        waitForNoExistence(app.menuItems["Copy"])

        loadWebPage("bing.com")
        waitForWebPageLoad()
        urlBarTextField.tap()
        urlBarTextField.press(forDuration: 2)
        waitForExistence(app.collectionViews.menuItems.firstMatch)
        waitForHittable(app.buttons["Forward"].firstMatch)
        app.buttons["Forward"].firstMatch.tap()
        if !iPad() {
            waitForExistence(app.collectionViews.menuItems.firstMatch)
            waitForHittable(app.buttons["Forward"].firstMatch)
            app.buttons["Forward"].firstMatch.tap()
        }
        waitForExistence(app.collectionViews.menuItems.firstMatch)
        waitForHittable(app.menuItems["Paste & Go"])
        app.menuItems["Paste & Go"].tap()

        waitForWebPageLoad()
        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }

        XCTAssert(text == "www.example.com")
    }
}
