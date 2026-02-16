// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class FindInPageTests: BaseTestCase {
    var browserScreen: BrowserScreen!
    var findInPageScreen: FindInPageScreen!

    private func navigateToOpenFindInPage(openSite: String) {
        navigator.openURL(openSite)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)

        navigator.goto(FindInPage)
    }

    private func openFindInPageFromMenu(openSite: String) {
        navigator.openURL(openSite)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)

        navigator.goto(FindInPage)

        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton],
                app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton]
            ]
        )
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.searchFields["find.searchField"])
        } else {
            mozWaitForElementToExist(app.textFields["FindInPage.searchField"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323463
    func testFindInLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from XCUITests-Runner"])
        navigator.goto(FindInPage)

        // Enter some text to start finding
        if #available(iOS 16, *) {
            app.searchFields["find.searchField"].typeText("Book")
            mozWaitForElementToExist(app.searchFields["Book"])
            XCTAssertEqual(app.staticTexts["find.resultLabel"].label, "1 of 1,000", "The book word count does match")
        } else {
            app.textFields["FindInPage.searchField"].typeText("Book")
            mozWaitForElementToExist(app.textFields["Book"])
            XCTAssertEqual(app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306851
    // Smoketest
    func testFindFromMenu() {
        browserScreen = BrowserScreen(app: app)
        findInPageScreen = FindInPageScreen(app: app)
        let searchTerm = "Book"
        userState.url = path(forTestPage: "test-mozilla-book.html")
        navigateToOpenFindInPage(openSite: userState.url!)

        findInPageScreen.waitForFindInPageBarToAppear()
        findInPageScreen.searchForText(searchTerm)

        findInPageScreen.assertResultsCountIsDisplayed("1 of 6")

        findInPageScreen.tapNextResult()
        findInPageScreen.assertResultsCountIsDisplayed("2 of 6")

        findInPageScreen.tapNextResult()
        findInPageScreen.assertResultsCountIsDisplayed("3 of 6")

        findInPageScreen.tapPreviousResult()
        findInPageScreen.assertResultsCountIsDisplayed("2 of 6")

        findInPageScreen.tapPreviousResult()
        findInPageScreen.assertResultsCountIsDisplayed("1 of 6")

        navigator.goto(BrowserTab)
        findInPageScreen.assertSearchBarDisappeared(searchKeyword: searchTerm)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323705
    func testFindInPageTwoWordsSearch() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)
        // Enter some text to start finding
        if #available(iOS 16, *) {
            app.searchFields["find.searchField"].typeText("The Book of")

            // Once there are matches, test previous/next buttons
            mozWaitForElementToExist(app.staticTexts["1 of 6"])
            XCTAssertTrue(app.staticTexts["1 of 6"].exists)
        } else {
            app.textFields["FindInPage.searchField"].typeText("The Book of")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323714
    func testFindInPageTwoWordsSearchLargeDoc() {
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(FindInPage)

        if #available(iOS 16, *) {
            app.searchFields["find.searchField"].typeText("The Book of")
            mozWaitForElementToExist(app.searchFields["The Book of"])
            XCTAssertEqual(app.staticTexts["find.resultLabel"].label, "1 of 1,000", "The book word count does match")
        } else {
            app.textFields["FindInPage.searchField"].typeText("The Book of")
            mozWaitForElementToExist(app.textFields["The Book of"])
            XCTAssertEqual(app.staticTexts["FindInPage.matchCount"].label, "1/500+", "The book word count does match")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323718
    func testFindInPageResultsPageShowHideContent() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)
        // Enter some text to start finding
        if #available(iOS 16, *) {
            app.searchFields["find.searchField"].typeText("Mozilla")

            // There should be matches
            mozWaitForElementToExist(app.staticTexts["1 of 6"])
            XCTAssertTrue(app.staticTexts["1 of 6"].exists)
        } else {
            app.textFields["FindInPage.searchField"].typeText("Mozilla")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323801
    func testQueryWithNoMatches() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Try to find text which does not match and check that there are not results
        if #available(iOS 16, *) {
            app.searchFields["find.searchField"].typeText("foo")
            mozWaitForElementToExist(app.staticTexts["0"])
            XCTAssertTrue(app.staticTexts["0"].exists, "There should not be any matches")
        } else {
            app.textFields["FindInPage.searchField"].typeText("foo")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323802
    func testBarDisappearsWhenReloading() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Before reloading, it is necessary to hide the keyboard
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].waitAndTap()
        urlBarAddress.typeText("\n")

        // Once the page is reloaded the search bar should not appear
        if #available(iOS 16, *) {
            mozWaitForElementToNotExist(app.searchFields["find.searchField"])
            XCTAssertFalse(app.searchFields["find.searchField"].exists)
        } else {
            mozWaitForElementToNotExist(app.searchFields["FindInPage.searchField"])
            XCTAssertFalse(app.searchFields["FindInPage.searchField"].exists)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323803
    func testBarDisappearsWhenOpeningTabsTray() {
        userState.url = path(forTestPage: "test-mozilla-book.html")
        openFindInPageFromMenu(openSite: userState.url!)

        // Dismiss keyboard
        app.buttons[AccessibilityIdentifiers.FindInPage.findInPageCloseButton].waitAndTap()
        navigator.nowAt(BrowserTab)

        // Going to tab tray and back to the website hides the search field.
        navigator.goto(TabTray)

        app.cells.elementContainingText("The Book of Mozilla").waitAndTap()
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
        if #available(iOS 26, *) {
            while !app.buttons["Find in Page"].exists {
                app.buttons["Forward"].firstMatch.waitAndTap()
                mozWaitForElementToExist(app.collectionViews.firstMatch)
            }
            app.buttons["Find in Page"].waitAndTap()
        } else {
            while !app.menuItems["Find in Page"].exists {
                if #available(iOS 16, *) {
                    app.buttons["Forward"].firstMatch.waitAndTap()
                } else {
                    app.menuItems["show.next.items.menu.button"].waitAndTap()
                }
                mozWaitForElementToExist(app.menuItems.firstMatch)
                if #available(iOS 16, *) {
                    mozWaitForElementToExist(app.buttons["Forward"])
                } else {
                    mozWaitForElementToExist(app.menuItems["show.next.items.menu.button"])
                }
            }
            app.menuItems["Find in Page"].waitAndTap()
        }
        if #available(iOS 16, *) {
            mozWaitForElementToExist(app.searchFields[textToFind])
        } else {
            mozWaitForElementToExist(app.textFields[textToFind])
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findPreviousButton])
        if #available(iOS 16, *) {
            XCTAssertTrue(app.searchFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        } else {
            XCTAssertTrue(app.textFields[textToFind].exists, "The bar does not appear with the text selected to be found")
        }
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.FindInPage.findNextButton])
    }
}
