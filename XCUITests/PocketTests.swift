/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PocketTest: BaseTestCase {

    func testPocketEnabledByDefault() {
        navigator.goto(NewTabScreen)
        waitForExistence(app.staticTexts["pocketTitle"])
        XCTAssertEqual(app.staticTexts["pocketTitle"].label, "Trending on Pocket")

        // There should be two stories on iPhone and three on iPad
        let numPocketStories = app.collectionViews.containing(.cell, identifier:"TopSitesCell").children(matching: .cell).count-1
        if iPad() {
            XCTAssertEqual(numPocketStories, 9)
        } else {
            XCTAssertEqual(numPocketStories, 3)
        }

        // Disable Pocket
        navigator.performAction(Action.TogglePocketInNewTab)
        navigator.goto(NewTabScreen)
        waitForNoExistence(app.staticTexts["pocketTitle"])
        // Enable it again
        navigator.performAction(Action.TogglePocketInNewTab)
        navigator.goto(NewTabScreen)
        waitForExistence(app.staticTexts["pocketTitle"])

        // Tap on the first Pocket element
        app.collectionViews.containing(.cell, identifier:"TopSitesCell").children(matching: .cell).element(boundBy: 1).tap()
        waitUntilPageLoad()
        // The url textField is not empty
        XCTAssertNotEqual(app.textFields["url"].value as! String, "", "The url textField is empty")
    }

    func testTapOnMore() {
        // Tap on More should show Pocket website
        navigator.goto(NewTabScreen)
        waitForExistence(app.buttons["More"], timeout: 5)
        app.buttons["More"].tap()
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        waitForExistence(app.textFields["url"], timeout: 15)
        waitForValueContains(app.textFields["url"], value: "getpocket.com/explore")
    }
}
