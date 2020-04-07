/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar meaning"
private let SuggestedSite2: String = "foobar2000"
private let SuggestedSite3: String = "foobar2000 mac"

private let SuggestedSite4: String = "foo bar baz"
private let SuggestedSite5: String = "foo bar baz qux"
private let SuggestedSite6: String = "foobar bit perfect"



class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        Base.helper.waitForExistence(Base.app.textFields.firstMatch, timeout: 10)
        Base.app.textFields.firstMatch.tap()
        Base.app.textFields.firstMatch.tap()
        Base.app.textFields.firstMatch.typeText(text)
    }

    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        Base.app.tables.switches["Show Search Suggestions"].tap()
        Base.app.navigationBars["Search"].buttons["Settings"].tap()
        Base.app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForNoExistence(Base.app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        Base.helper.waitForExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])

        // Disable Search suggestion
        Base.app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(HomePanelsScreen)
        suggestionsOnOff()

        // Suggestions should not be shown
        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])

        // Verify that previous choice is remembered
        Base.app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])
        Base.app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(HomePanelsScreen)

        // Reset suggestion button, set it to on
        suggestionsOnOff()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)

        // Suggestions prompt should appear
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])
    }

    // Promt does not appear once Search has been enabled by default, see bug: 1411184
    func testDismissPromptPresence() {
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForExistence(Base.app.staticTexts[LabelPrompt])

        Base.app.buttons["No"].tap()
        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])
        Base.app.buttons["Go"].tap()
        navigator.nowAt(BrowserTab)
        // Verify that it is possible to enable suggestions after selecting No
        suggestionsOnOff()
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])
    }

    func testDoNotShowSuggestionsWhenEnteringURL() {
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string,
        // the suggestions are shown again
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        Base.helper.waitForNoExistence(Base.app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        Base.helper.waitForExistence(Base.app.tables["SiteTable"])
        if !(Base.app.tables["SiteTable"].buttons[SuggestedSite].exists) {
            if !(Base.app.tables["SiteTable"].buttons[SuggestedSite2].exists) {
                Base.helper.waitForExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite3])
            }
        }

        // Typing / should stop showing suggestions
        Base.app.textFields["address"].typeText("/")
        Base.helper.waitForNoExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite])

        // Typing space and char after / should show suggestions again
        Base.app.textFields["address"].typeText(" b")
        Base.helper.waitForExistence(Base.app.tables["SiteTable"])
        if !(Base.app.tables["SiteTable"].buttons[SuggestedSite4].exists) {
            if !(Base.app.tables["SiteTable"].buttons[SuggestedSite5].exists) {
                Base.helper.waitForExistence(Base.app.tables["SiteTable"].buttons[SuggestedSite6])
            }
        }
    }
    /* Disabled due to issue 5581
    func testCopyPasteComplete() {
        // Copy, Paste and Go to url
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.mozilla.org")
        Base.app.textFields["address"].press(forDuration: 5)
        Base.app.menuItems["Select All"].tap()
        Base.app.menuItems["Copy"].tap()
        Base.helper.waitForExistence(Base.app.buttons["urlBar-cancel"])
        Base.app.buttons["urlBar-cancel"].tap()

        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].tap()
        Base.helper.waitForExistence(Base.app.menuItems["Paste"])
        Base.app.menuItems["Paste"].tap()

        // Verify that the Paste shows the search controller with prompt
        Base.helper.waitForNoExistence(Base.app.staticTexts[LabelPrompt])
        Base.app.typeText("\r")

        // Check that the website is loaded
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "www.mozilla.org")

        // Go back, write part of moz, check the autocompletion
        if iPad() {
            Base.app.buttons["URLBarView.backButton"].tap()
        } else {
            Base.app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "moz")
        Base.helper.waitForValueContains(Base.app.textFields["address"], value: "mozilla.org")
        let value = Base.app.textFields["address"].value
        XCTAssertEqual(value as? String, "mozilla.org")
    }*/

    private func changeSearchEngine(searchEngine: String) {
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        Base.app.tables.cells.element(boundBy: 0).tap()
        let tablesQuery2 = Base.app.tables
        tablesQuery2.staticTexts[searchEngine].tap()

        navigator.openURL("foo")
        // Workaroud needed after xcode 11.3 update Issue 5937
        Base.helper.waitForExistence(Base.app.webViews.firstMatch, timeout: 3)
        // Base.helper.waitForValueContains(Base.app.textFields["url"], value: searchEngine.lowercased())
        }

    // Smoketest
    func testSearchEngine() {
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        // Lets keep only one search engine test, xcode 11.3 update Issue 5937
        // changeSearchEngine(searchEngine: "DuckDuckGo")
        // Temporary disabled due to intermittent issue on BB
        // changeSearchEngine(searchEngine: "Google")
        // changeSearchEngine(searchEngine: "Twitter")
        // changeSearchEngine(searchEngine: "Wikipedia")
        // changeSearchEngine(searchEngine: "Amazon.com")
    }

    func testDefaultSearchEngine() {
        navigator.goto(SearchSettings)
        XCTAssert(Base.app.tables.staticTexts["Google"].exists)
    }

    func testSearchWithFirefoxOption() {
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-book.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.webViews.staticTexts["cloud"], timeout: 10)
        // Select some text and long press to find the option
        Base.app.webViews.staticTexts["cloud"].press(forDuration: 1)
        if !Base.helper.iPad() {
            Base.helper.waitForExistence(Base.app.menuItems["show.next.items.menu.button"], timeout: 5)
            Base.app.menuItems["show.next.items.menu.button"].tap()
        }
        Base.helper.waitForExistence(Base.app.menuItems["Search with Firefox"])
        Base.app.menuItems["Search with Firefox"].tap()
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "google")
        // Now there should be two tabs open
        let numTab = Base.app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)
    }
    // Bug https://bugzilla.mozilla.org/show_bug.cgi?id=1541832 scenario 4
    func testSearchStartAfterTypingTwoWords() {
        navigator.goto(URLBarOpen)
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 10)
        Base.app.typeText("foo bar")
        Base.app.typeText(XCUIKeyboardKey.return.rawValue)
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 20)
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "google")
    }
}
