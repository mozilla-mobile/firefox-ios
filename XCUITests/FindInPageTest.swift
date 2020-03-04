/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class FindInPageTests: BaseTestCase {
    private func openFindInPageFromMenu() {
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()
        navigator.goto(PageOptionsMenu)
        navigator.goto(FindInPage)

        Base.helper.waitForExistence(Base.app.buttons["FindInPage.find_next"], timeout: 5)
        Base.helper.waitForExistence(Base.app.buttons["FindInPage.find_previous"], timeout: 5)
        XCTAssertTrue(Base.app.textFields["FindInPage.searchField"].exists)
    }

    func testFindInLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        // Workaround until FxSGraph is fixed to allow the previos way with goto
        navigator.nowAt(BrowserTab)

        Base.helper.waitForExistence(Base.app/*@START_MENU_TOKEN@*/.buttons["TabLocationView.pageOptionsButton"]/*[[".buttons[\"Page Options Menu\"]",".buttons[\"TabLocationView.pageOptionsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/, timeout: 15)
        Base.app/*@START_MENU_TOKEN@*/.buttons["TabLocationView.pageOptionsButton"]/*[[".buttons[\"Page Options Menu\"]",".buttons[\"TabLocationView.pageOptionsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        Base.helper.waitForExistence(Base.app.tables["Context Menu"].cells["menu-FindInPage"], timeout: 10)
        Base.app.tables["Context Menu"].cells["menu-FindInPage"].tap()

        // Enter some text to start finding
        Base.app.textFields["FindInPage.searchField"].typeText("Book")
        Base.helper.waitForExistence(Base.app.textFields["Book"], timeout: 15)
        XCTAssertEqual(Base.app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
    }

    // Smoketest
    func testFindFromMenu() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu()

        // Enter some text to start finding
        Base.app.textFields["FindInPage.searchField"].typeText("Book")

        // Once there are matches, test previous/next buttons
        Base.helper.waitForExistence(Base.app.staticTexts["1/6"])
        XCTAssertTrue(Base.app.staticTexts["1/6"].exists)

        let nextInPageResultButton = Base.app.buttons["FindInPage.find_next"]
        nextInPageResultButton.tap()
        Base.helper.waitForExistence(Base.app.staticTexts["2/6"])
        XCTAssertTrue(Base.app.staticTexts["2/6"].exists)

        nextInPageResultButton.tap()
        Base.helper.waitForExistence(Base.app.staticTexts["3/6"])
        XCTAssertTrue(Base.app.staticTexts["3/6"].exists)

        let previousInPageResultButton = Base.app.buttons["FindInPage.find_previous"]
        previousInPageResultButton.tap()

        Base.helper.waitForExistence(Base.app.staticTexts["2/6"])
        XCTAssertTrue(Base.app.staticTexts["2/6"].exists)

        previousInPageResultButton.tap()
        Base.helper.waitForExistence(Base.app.staticTexts["1/6"])
        XCTAssertTrue(Base.app.staticTexts["1/6"].exists)

        // Tapping on close dismisses the search bar
        navigator.goto(BrowserTab)
        Base.helper.waitForNoExistence(Base.app.textFields["Book"])
    }

    func testFindInPageTwoWordsSearch() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu()
        // Enter some text to start finding
        Base.app.textFields["FindInPage.searchField"].typeText("The Book of")

        // Once there are matches, test previous/next buttons
        Base.helper.waitForExistence(Base.app.staticTexts["1/6"])
        XCTAssertTrue(Base.app.staticTexts["1/6"].exists)
    }

    func testFindInPageTwoWordsSearchLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        // Workaround until FxSGraph is fixed to allow the previos way with goto
        Base.helper.waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        Base.helper.waitForExistence(Base.app/*@START_MENU_TOKEN@*/.buttons["TabLocationView.pageOptionsButton"]/*[[".buttons[\"Page Options Menu\"]",".buttons[\"TabLocationView.pageOptionsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/, timeout: 15)
        Base.app/*@START_MENU_TOKEN@*/.buttons["TabLocationView.pageOptionsButton"]/*[[".buttons[\"Page Options Menu\"]",".buttons[\"TabLocationView.pageOptionsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        // Enter some text to start finding
        Base.app.tables["Context Menu"].cells["menu-FindInPage"].tap()
        Base.app.textFields["FindInPage.searchField"].typeText("The Book of")
        Base.helper.waitForExistence(Base.app.textFields["The Book of"], timeout: 15)
        XCTAssertEqual(Base.app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
    }

    func testFindInPageResultsPageShowHideContent() {
        userState.url = "lorem2.com"
        openFindInPageFromMenu()
        // Enter some text to start finding
        Base.app.textFields["FindInPage.searchField"].typeText("lorem")

        // There should be matches
        Base.helper.waitForExistence(Base.app.staticTexts["1/5"])
        XCTAssertTrue(Base.app.staticTexts["1/5"].exists)
    }

    func testQueryWithNoMatches() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu()

        // Try to find text which does not match and check that there are not results
        Base.app.textFields["FindInPage.searchField"].typeText("foo")
        Base.helper.waitForExistence(Base.app.staticTexts["0/0"])
        XCTAssertTrue(Base.app.staticTexts["0/0"].exists, "There should not be any matches")
    }

    func testBarDissapearsWhenReloading() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu()

        // Before reloading, it is necessary to hide the keyboard
        Base.app.textFields["url"].tap()
        Base.app.textFields["address"].typeText("\n")

        // Once the page is reloaded the search bar should not appear
        Base.helper.waitForNoExistence(Base.app.textFields[""])
        XCTAssertFalse(Base.app.textFields[""].exists)
    }

    func testBarDissapearsWhenOpeningTabsTray() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu()

        // Dismiss keyboard
        Base.app.buttons["FindInPage.close"].tap()
        navigator.nowAt(BrowserTab)

        // Going to tab tray and back to the website hides the search field.
        navigator.goto(TabTray)

        Base.helper.waitForExistence(Base.app.collectionViews.cells["The Book of Mozilla"])
        Base.app.collectionViews.cells["The Book of Mozilla"].tap()
        XCTAssertFalse(Base.app.textFields[""].exists)
        XCTAssertFalse(Base.app.buttons["FindInPage.find_next"].exists)
        XCTAssertFalse(Base.app.buttons["FindInPage.find_previous"].exists)
    }

    func testFindFromSelection() {
        userState.url = Base.helper.path(forTestPage: "test-mozilla-book.html")
        navigator.goto(BrowserTab)
        let textToFind = "from"

        // Long press on the word to be found
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.webViews.staticTexts[textToFind])
        let stringToFind = Base.app.webViews.staticTexts.matching(identifier: textToFind)
        let firstStringToFind = stringToFind.element(boundBy: 0)
        firstStringToFind.press(forDuration: 3)
        Base.helper.waitForExistence(Base.app.menuItems["Copy"])
        // Find in page is correctly launched, bar with text pre-filled and
        // the buttons to find next and previous
        if (Base.app.menuItems["Find in Page"].exists) {
            Base.app.menuItems["Find in Page"].tap()
        } else {
            Base.app.menus.children(matching: .menuItem).element(boundBy: 3).tap()
            Base.helper.waitForExistence(Base.app.menuItems["Find in Page"])
            Base.app.menuItems["Find in Page"].tap()
        }
        Base.helper.waitForExistence(Base.app.textFields[textToFind])
        XCTAssertTrue(Base.app.textFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        XCTAssertTrue(Base.app.buttons["FindInPage.find_previous"].exists, "Find previous button exists")
        XCTAssertTrue(Base.app.buttons["FindInPage.find_next"].exists, "Find next button exists")
    }
}
