/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar2000"

class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        waitforExistence(app.textFields["address"])
        app.textFields["address"].typeText(text)
    }

    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforNoExistence(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Disable Search suggestion
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        suggestionsOnOff()

        // Suggestions should not be shown
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Verify that previous choice is remembered
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)

        // Reset suggestion button, set it to on
        suggestionsOnOff()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)

        // Suggestions prompt should appear
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }

    // Promt does not appear once Search has been enabled by default, see bug: 1411184
    func testDismissPromptPresence() {
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.staticTexts[LabelPrompt])

        app.buttons["No"].tap()
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        app.buttons["Go"].tap()
        navigator.nowAt(BrowserTab)
        // Verify that it is possible to enable suggestions after selecting No
        suggestionsOnOff()
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }

    func testDoNotShowSuggestionsWhenEnteringURL() {
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string,
        // the suggestions are shown again
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        waitforNoExistence(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Typing / should stop showing suggestions
        app.textFields["address"].typeText("/")
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])

        // Typing space and char after / should show suggestions again
        app.textFields["address"].typeText(" b")
        waitforExistence(app.tables["SiteTable"].buttons["foobar burn cd"])
    }

    func testCopyPasteComplete() {
        // Copy, Paste and Go to url
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.mozilla.org")
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        app.buttons["goBack"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        app.textFields["address"].tap()
        waitforExistence(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()

        // Verify that the Paste shows the search controller with prompt
        waitforNoExistence(app.staticTexts[LabelPrompt])
        app.typeText("\r")

        // Check that the website is loaded
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org")

        // Go back, write part of moz, check the autocompletion
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "moz")
        waitForValueContains(app.textFields["address"], value: "mozilla.org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "mozilla.org")
    }

    private func changeSearchEngine(searchEngine: String) {
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).tap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts[searchEngine].tap()

        navigator.openURL(urlString: "foo")
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: searchEngine.lowercased())

        // Go here so that next time it is possible to access settings
        navigator.goto(BrowserTabMenu)
        }

    func testSearchEngine() {
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        changeSearchEngine(searchEngine: "DuckDuckGo")
        changeSearchEngine(searchEngine: "Google")
        changeSearchEngine(searchEngine: "Twitter")
        changeSearchEngine(searchEngine: "Wikipedia")
        changeSearchEngine(searchEngine: "Amazon.com")
        changeSearchEngine(searchEngine: "Yahoo")
    }

    func testDefaultSearchEngine() {
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
    }
}
