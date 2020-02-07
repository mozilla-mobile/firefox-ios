/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PocketTest: BaseTestCase {

    func testPocketEnabledByDefault() {
        navigator.goto(NewTabScreen)
        Base.helper.waitForExistence(Base.app.staticTexts["pocketTitle"])
        XCTAssertEqual(Base.app.staticTexts["pocketTitle"].label, "Trending on Pocket")

        // There should be two stories on iPhone and three on iPad
        let numPocketStories = Base.app.collectionViews.containing(.cell, identifier:"TopSitesCell").children(matching: .cell).count-1
        if Base.helper.iPad() {
            XCTAssertEqual(numPocketStories, 9)
        } else {
            XCTAssertEqual(numPocketStories, 3)
        }

        // Disable Pocket
        navigator.performAction(Action.TogglePocketInNewTab)
        navigator.goto(NewTabScreen)
        Base.helper.waitForNoExistence(Base.app.staticTexts["pocketTitle"])
        // Enable it again
        navigator.performAction(Action.TogglePocketInNewTab)
        navigator.goto(NewTabScreen)
        Base.helper.waitForExistence(Base.app.staticTexts["pocketTitle"])

        // Tap on the first Pocket element
        Base.app.collectionViews.containing(.cell, identifier:"TopSitesCell").children(matching: .cell).element(boundBy: 1).tap()
        Base.helper.waitUntilPageLoad()
        // The url textField is not empty
        XCTAssertNotEqual(Base.app.textFields["url"].value as! String, "", "The url textField is empty")
    }

    func testTapOnMore() {
        // Tap on More should show Pocket website
        navigator.goto(NewTabScreen)
        Base.helper.waitForExistence(Base.app.buttons["More"], timeout: 5)
        Base.app.buttons["More"].tap()
        Base.helper.waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 15)
        let value = Base.app.textFields["url"].value as! String
        XCTAssertEqual(value, "getpocket.com/explore/trending?src=ff_ios&cdn=0")
    }
}
