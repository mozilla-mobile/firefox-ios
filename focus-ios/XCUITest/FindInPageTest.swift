/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class FindInPageTest: BaseTestCase {
    func testFindInPageURLBarElement() {
        // Navigate to website
        loadWebPage("https://www.example.com")
        waitForWebPageLoad()

        // Activate the find in page bar
        app.textFields["Search or enter address"].tap()
        app.textFields["Search or enter address"].typeText("domain")

        // Try all functions of find in page bar
        waitForHittable(app.buttons["FindInPageBar.button"])
        app.buttons["FindInPageBar.button"].tap()

        waitForHittable(app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()

        waitForHittable(app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()

        waitForHittable(app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()

        // Ensure find in page bar is dismissed
        waitForNoExistence(app.buttons["FindInPage.close"])
    }

    func testActivityMenuFindInPageAction() {
        // Navigate to website
        loadWebPage("https://www.example.com")
        waitForExistence(app.buttons["URLBar.pageActionsButton"])
        app.buttons["URLBar.pageActionsButton"].tap()

        // Activate find in page activity item and search for a keyword
        waitForHittable(app.cells["Find in Page"])
        app.cells["Find in Page"].tap()
        app.typeText("Domain")

        // Try all functions of find in page bar
        waitForHittable(app.buttons["FindInPage.find_previous"])
        app.buttons["FindInPage.find_previous"].tap()

        waitForHittable(app.buttons["FindInPage.find_next"])
        app.buttons["FindInPage.find_next"].tap()

        waitForHittable(app.buttons["FindInPage.close"])
        app.buttons["FindInPage.close"].tap()

        // Ensure find in page bar is dismissed
        waitForNoExistence(app.buttons["FindInPage.close"])
    }
}
