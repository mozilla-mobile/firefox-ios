/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class FindInPageTest: BaseTestCase {
    func testFindInPageURLBarElement() {
        // Navigate to website
        loadWebPage("http://localhost:6573/licenses.html\n")
        waitForWebPageLoad()
        
        let searchOrEnterAddressTextField = app.textFields["Search or enter address"]
        // Activate the find in page bar
        app.textFields["Search or enter address"].tap()
        app.textFields["Search or enter address"].typeText("mozilla")

        // Try all functions of find in page bar
        waitforHittable(element: app.buttons["FindInPageBar.button"])
        app.buttons["FindInPageBar.button"].tap()

        waitforHittable(element: app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()

        waitforHittable(element: app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()

        waitforHittable(element: app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()

        // Ensure find in page bar is dismissed
        waitforNoExistence(element: app.buttons["FindInPage.close"])
    }

    func testActivityMenuFindInPageAction() {
        // Navigate to website
        loadWebPage("http://localhost:6573/licenses.html\n")
        waitforExistence(element: app.buttons["URLBar.pageActionsButton"])
        app.buttons["URLBar.pageActionsButton"].tap()

        // Activate find in page activity item and search for a keyword
        waitforHittable(element: app.cells["Find in Page"])
        app.cells["Find in Page"].tap()
        app.typeText("Moz")

        // Try all functions of find in page bar
        waitforHittable(element: app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()

        waitforHittable(element: app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()

        waitforHittable(element: app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()

        // Ensure find in page bar is dismissed
        waitforNoExistence(element: app.buttons["FindInPage.close"])
    }
}
