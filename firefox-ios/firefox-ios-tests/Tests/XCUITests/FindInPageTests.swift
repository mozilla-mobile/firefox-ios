// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class FindInPageTests: BaseTestCase {
    private func openFindInPageFromMenu(openSite: String) {
        navigator.openURL(openSite)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)

        navigator.goto(FindInPage)

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton])
        mozWaitForElementToExist(app.searchFields["find.searchField"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323463
    func testFindInLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        // Workaround until FxSGraph is fixed to allow the previous way with goto
        navigator.nowAt(BrowserTab)

        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        mozWaitForElementToExist(app.tables["Context Menu"]
            .otherElements[StandardImageIdentifiers.Large.search])
        app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.search].tap()

        // Enter some text to start finding
        app.searchFields["find.searchField"].typeText("Book")
        mozWaitForElementToExist(app.searchFields["Book"])
        XCTAssertEqual(app.staticTexts["find.resultLabel"].label, "1 of 1,000", "The book word count does match")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306851
    // Smoketest
    func testFindFromMenu() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Enter some text to start finding
        app.searchFields["find.searchField"].typeText("Book")

        // Once there are matches, test previous/next buttons
        mozWaitForElementToExist(app.staticTexts["1 of 6"])
        XCTAssertTrue(app.staticTexts["1 of 6"].exists)

        let nextInPageResultButton = app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton]
        nextInPageResultButton.tap()
        mozWaitForElementToExist(app.staticTexts["2 of 6"])
        XCTAssertTrue(app.staticTexts["2 of 6"].exists)

        nextInPageResultButton.tap()
        mozWaitForElementToExist(app.staticTexts["3 of 6"])
        XCTAssertTrue(app.staticTexts["3 of 6"].exists)

        let previousInPageResultButton = app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton]
        previousInPageResultButton.tap()

        mozWaitForElementToExist(app.staticTexts["2 of 6"])
        XCTAssertTrue(app.staticTexts["2 of 6"].exists)

        previousInPageResultButton.tap()
        mozWaitForElementToExist(app.staticTexts["1 of 6"])
        XCTAssertTrue(app.staticTexts["1 of 6"].exists)

        // Tapping on close dismisses the search bar
        navigator.goto(BrowserTab)
        mozWaitForElementToNotExist(app.textFields["Book"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323705
    func testFindInPageTwoWordsSearch() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)
        // Enter some text to start finding
        app.searchFields["find.searchField"].typeText("The Book of")

        // Once there are matches, test previous/next buttons
        mozWaitForElementToExist(app.staticTexts["1 of 6"])
        XCTAssertTrue(app.staticTexts["1 of 6"].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323714
    func testFindInPageTwoWordsSearchLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        // Workaround until FxSGraph is fixed to allow the previous way with goto
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        // Enter some text to start finding
        app.tables["Context Menu"].otherElements[StandardImageIdentifiers.Large.search].tap()
        app.searchFields["find.searchField"].typeText("The Book of")
        mozWaitForElementToExist(app.searchFields["The Book of"])
        XCTAssertEqual(app.staticTexts["find.resultLabel"].label, "1 of 1,000", "The book word count does match")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323718
    func testFindInPageResultsPageShowHideContent() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)
        // Enter some text to start finding
        app.searchFields["find.searchField"].typeText("Mozilla")

        // There should be matches
        mozWaitForElementToExist(app.staticTexts["1 of 6"])
        XCTAssertTrue(app.staticTexts["1 of 6"].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323801
    func testQueryWithNoMatches() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Try to find text which does not match and check that there are not results
        app.searchFields["find.searchField"].typeText("foo")
        mozWaitForElementToExist(app.staticTexts["0"])
        XCTAssertTrue(app.staticTexts["0"].exists, "There should not be any matches")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323802
    func testBarDisappearsWhenReloading() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Before reloading, it is necessary to hide the keyboard
        app.textFields["url"].tap()
        app.textFields["address"].typeText("\n")

        // Once the page is reloaded the search bar should not appear
        mozWaitForElementToNotExist(app.searchFields["find.searchField"])
        XCTAssertFalse(app.searchFields["find.searchField"].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323803
    func testBarDisappearsWhenOpeningTabsTray() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Dismiss keyboard
        app.buttons[AccessibilityIdentifiers.FindInPage.findInPageCloseButton].tap()
        navigator.nowAt(BrowserTab)

        // Going to tab tray and back to the website hides the search field.
        navigator.goto(TabTray)

        mozWaitForElementToExist(app.cells.staticTexts["The Book of Mozilla"])
        app.cells.staticTexts["The Book of Mozilla"].firstMatch.tap()
        XCTAssertFalse(app.searchFields["find.searchField"].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323467
    func testFindFromLongTap() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)
        let textToFind = "from"

        // Long press on the word to be found
        mozWaitForElementToExist(app.webViews.staticTexts[textToFind])
        let stringToFind = app.webViews.staticTexts.matching(identifier: textToFind)
        let firstStringToFind = stringToFind.element(boundBy: 0)
        firstStringToFind.press(forDuration: 3)
        mozWaitForElementToExist(app.menuItems["Copy"])
        // Find in page is correctly launched, bar with text pre-filled and
        // the buttons to find next and previous
        while !app.menuItems["Find in Page"].exists {
            if #available(iOS 16, *) {
                app.buttons["Forward"].firstMatch.tap()
            } else {
                app.menuItems["show.next.items.menu.button"].tap()
            }
            mozWaitForElementToExist(app.menuItems.firstMatch)
            if #available(iOS 16, *) {
                mozWaitForElementToExist(app.buttons["Forward"])
            } else {
                mozWaitForElementToExist(app.menuItems["show.next.items.menu.button"])
            }
        }
        mozWaitForElementToExist(app.menuItems["Find in Page"])
        app.menuItems["Find in Page"].tap()
        mozWaitForElementToExist(app.searchFields[textToFind])
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton])
        XCTAssertTrue(app.searchFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton])
    }
}
