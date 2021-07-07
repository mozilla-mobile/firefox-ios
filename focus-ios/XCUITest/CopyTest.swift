/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

// Note: this test is tested as part of the base test case, and thus is disabled here.

class CopyTest: BaseTestCase {
    func testCopyMenuItem() throws {
        throw XCTSkip("This test needs to be updated or removed")
        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage("https://www.example.com")

        // Must offset textfield press to support 5S.
        urlBarTextField.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx: 10, dy: 0)).press(forDuration: 0.5)
        waitForExistence(app.menuItems["Copy"])
        app.menuItems["Copy"].tap()
        waitForNoExistence(app.menuItems["Copy"])

        loadWebPage("bing.com")
        urlBarTextField.tap()
        urlBarTextField.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx: 10, dy: 0)).press(forDuration: 1.5)
        waitForHittable(app.menuItems["Paste & Go"])
        app.menuItems["Paste & Go"].tap()

        waitForWebPageLoad()
        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }

        XCTAssert(text == "http://localhost:6573/licenses.html")
    }
}
