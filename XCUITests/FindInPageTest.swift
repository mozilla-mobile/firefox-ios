/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class FindInPageTests: BaseTestCase {
    private func openFindInPageFromMenu() {
        navigator.goto(BrowserTab)
        waitUntilPageLoad()
        navigator.goto(PageOptionsMenu)
        navigator.goto(FindInPage)

        waitforExistence(app.buttons["FindInPage.find_next"])
        waitforExistence(app.buttons["FindInPage.find_previous"])
        XCTAssertTrue(app.textFields[""].exists)
    }

    func testFindInLargeDoc() {
        userState.url = "http://localhost:6571/find-in-page-test.html"
        sleep(1)
        openFindInPageFromMenu()

        // Enter some text to start finding
        app.textFields[""].typeText("Book")
        var i = 0
        repeat {
            i = i+1
        } while (app.textFields["Book"].exists == false && i < 5)
        XCTAssertEqual(app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
    }

    func testFindFromMenu() {
        openFindInPageFromMenu()

        // Enter some text to start finding
        app.textFields[""].typeText("Book")

        // Once there are matches, test previous/next buttons
        waitforExistence(app.staticTexts["1/6"])
        XCTAssertTrue(app.staticTexts["1/6"].exists)

        let nextInPageResultButton = app.buttons["FindInPage.find_next"]
        nextInPageResultButton.tap()
        waitforExistence(app.staticTexts["2/6"])
        XCTAssertTrue(app.staticTexts["2/6"].exists)

        nextInPageResultButton.tap()
        waitforExistence(app.staticTexts["3/6"])
        XCTAssertTrue(app.staticTexts["3/6"].exists)

        let previousInPageResultButton = app.buttons["FindInPage.find_previous"]
        previousInPageResultButton.tap()

        waitforExistence(app.staticTexts["2/6"])
        XCTAssertTrue(app.staticTexts["2/6"].exists)

        previousInPageResultButton.tap()
        waitforExistence(app.staticTexts["1/6"])
        XCTAssertTrue(app.staticTexts["1/6"].exists)

        // Tapping on close dismisses the search bar
        navigator.goto(BrowserTab)
        waitforNoExistence(app.textFields["Book"])
    }

    func testFindInPageTwoWordsSearch() {
        openFindInPageFromMenu()
        // Enter some text to start finding
        app.textFields[""].typeText("The Book of")

        // Once there are matches, test previous/next buttons
        waitforExistence(app.staticTexts["1/6"])
        XCTAssertTrue(app.staticTexts["1/6"].exists)
    }

    func testFindInPageTwoWordsSearchLargeDoc() {
        userState.url = "http://localhost:6571/find-in-page-test.html"
        openFindInPageFromMenu()

        // Enter some text to start finding
        app.textFields[""].typeText("The Book of")
        var i = 0
        repeat {
            i = i+1
        } while (app.textFields["The Book of"].exists == false && i < 5)

        XCTAssertEqual(app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
    }

    func testFindInPageResultsPageShowHideContent() {
        userState.url = "lorem2.com"
        openFindInPageFromMenu()
        // Enter some text to start finding
        app.textFields[""].typeText("lorem")

        // There should be matches
        waitforExistence(app.staticTexts["1/5"])
        XCTAssertTrue(app.staticTexts["1/5"].exists)
    }

    func testQueryWithNoMatches() {
        openFindInPageFromMenu()

        // Try to find text which does not match and check that there are not results
        app.textFields["FindInPage.searchField"].typeText("foo")
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

        // Dismiss keyboard
        app.otherElements["contentView"].tap()
        navigator.nowAt(BrowserTab)

        // Going to tab tray and back to the website hides the search field.
        navigator.goto(TabTray)

        waitforExistence(app.collectionViews.cells["The Book of Mozilla"])
        app.collectionViews.cells["The Book of Mozilla"].tap()
        XCTAssertFalse(app.textFields[""].exists)
        XCTAssertFalse(app.buttons["FindInPage.find_next"].exists)
        XCTAssertFalse(app.buttons["FindInPage.find_previous"].exists)
    }

    func testFindFromSelection() {
        navigator.goto(BrowserTab)
        let textToFind = "from"

        // Long press on the word to be found
        waitUntilPageLoad()
        waitforExistence(app.webViews.staticTexts[textToFind])
        let stringToFind = app.webViews.staticTexts.matching(identifier: textToFind)
        let firstStringToFind = stringToFind.element(boundBy: 0)
        firstStringToFind.press(forDuration: 3)

        // Find in page is correctly launched, bar with text pre-filled and
        // the buttons to find next and previous
        waitforExistence(app.menuItems["Find in Page"])
        app.menuItems["Find in Page"].tap()
        waitforExistence(app.textFields[textToFind])
        XCTAssertTrue(app.textFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        XCTAssertTrue(app.buttons["FindInPage.find_previous"].exists, "Find previous button exists")
        XCTAssertTrue(app.buttons["FindInPage.find_next"].exists, "Find next button exists")
    }
}
