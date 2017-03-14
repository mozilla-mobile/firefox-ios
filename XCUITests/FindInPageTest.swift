/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class FindInPageTests: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        super.tearDown()
    }

    private func openFindInPageFromMenu() {
        navigator.goto(BrowserTabMenu)
        let collectionViewsQuery = app.collectionViews
        waitforExistence(collectionViewsQuery.cells["Find In Page"])

        collectionViewsQuery.cells["Find In Page"].tap()
        XCTAssertTrue(app.textFields[""].exists)
    }

    func testFindFromMenu() {
        openFindInPageFromMenu()
        // Enter some text to start finding
        app.textFields[""].typeText("Book")

        // Once there are matches, test previous/next buttons
        waitforExistence(app.staticTexts["1/5"])
        XCTAssertTrue(app.staticTexts["1/5"].exists)

        let nextInPageResultButton = app.buttons["Next in-page result"]
        nextInPageResultButton.tap()
        waitforExistence(app.staticTexts["2/5"])
        XCTAssertTrue(app.staticTexts["2/5"].exists)

        nextInPageResultButton.tap()
        waitforExistence(app.staticTexts["3/5"])
        XCTAssertTrue(app.staticTexts["3/5"].exists)

        let previousInPageResultButton = app.buttons["Previous in-page result"]
        previousInPageResultButton.tap()

        waitforExistence(app.staticTexts["2/5"])
        XCTAssertTrue(app.staticTexts["2/5"].exists)

        previousInPageResultButton.tap()
        waitforExistence(app.staticTexts["1/5"])
        XCTAssertTrue(app.staticTexts["1/5"].exists)

        // Tapping on close dismisses the search bar
        app.buttons["Done"].tap()
        waitforNoExistence(app.textFields["Book"])
    }

    func testQueryWithNoMatches() {
        openFindInPageFromMenu()

        // Try to find text which does not match and check that there are not results
        app.textFields[""].typeText("foo")
        waitforExistence(app.staticTexts["0/0"])
        XCTAssertTrue(app.staticTexts["0/0"].exists, "There should not be any matches")
    }

    func testBarDissapearsWhenReloading() {
        openFindInPageFromMenu()

        // Before reloading, it is necessary to hide the keyboard
        app.textFields["url"].tap()
        app.textFields["address"].typeText("\n")

        // Once the page is reloaded the search bar should not appear
        waitforNoExistence(app.textFields[""])
        XCTAssertFalse(app.textFields[""].exists)
    }

    func testBarDissapearsWhenOpeningTabsTray() {
        openFindInPageFromMenu()

        // Going to tab tray and back to the website hides the search field.
        navigator.nowAt(BrowserTab)
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells["The Book of Mozilla"])
        app.collectionViews.cells["The Book of Mozilla"].tap()
        XCTAssertFalse(app.textFields[""].exists)
    }

    func testFindFromSelection() {
        navigator.goto(BrowserTab)
        let textToFind = "from"

        // Long press on the word to be found
        let stringToFind = app.webViews.staticTexts.matching(identifier: textToFind)
        let firstStringToFind = stringToFind.element(boundBy: 0)
        firstStringToFind.press(forDuration: 5)

        // Find in page is correctly launched, bar with text pre-filled and the buttons to find next and previous
        waitforExistence(app.menuItems["Find in Page"])
        app.menuItems["Find in Page"].tap()
        waitforExistence(app.textFields[textToFind])
        XCTAssertTrue(app.textFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        XCTAssertTrue(app.buttons["Previous in-page result"].exists, "Find previus button exists")
        XCTAssertTrue(app.buttons["Next in-page result"].exists, "Find next button exists")
    }
}
