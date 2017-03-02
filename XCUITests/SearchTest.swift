/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar2000.org"

class SearchTests: BaseTestCase {
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
    
    private func typeOnSearchBar(text: String) {
        navigator.goto(URLBarOpen)
        app.textFields["address"].typeText(text)
    }
    
    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
    }
    
    func testPromptPresence() {
        // Suggestion is off by default, so the prompt should appear
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.staticTexts[LabelPrompt])
        
        // No suggestions should be shown
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        
        // Enable Search suggestion
        app.buttons["Yes"].tap()
        
        // Suggestions should be shown
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        
        // Verify that previous choice is remembered
        navigator.goto(NewTabScreen)
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        
        // Reset suggestion button, set it to off
        navigator.goto(NewTabScreen)
        suggestionsOnOff()
        typeOnSearchBar(text: "foobar")
        
        // Suggestions prompt should not appear
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }
    
    func testDismissPromptPresence() {
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.staticTexts[LabelPrompt])
        
        app.buttons["No"].tap()
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        
        // Verify that it is possible to enable suggestions after selecting No
        navigator.goto(NewTabMenu)
        suggestionsOnOff()
        typeOnSearchBar(text: "foobar")
        
        waitforExistence(app.tables["SiteTable"].buttons[SuggestedSite])
    }
  
    func testDoNotShowSuggestionsWhenEnteringURL() {
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string, the suggestions are shown again
        typeOnSearchBar(text: "foobar")
        waitforExistence(app.staticTexts[LabelPrompt])
        
        // No suggestions should be shown
        waitforNoExistence(app.tables["SiteTable"].buttons[SuggestedSite])
        
        // Enable Search suggestion
        app.buttons["Yes"].tap()
        
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
        typeOnSearchBar(text: "www.mozilla.org")
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].tap()
        
        navigator.goto(URLBarOpen)
        app.textFields["address"].tap()
        app.menuItems["Paste"].tap()
        
        // Verify that the Paste shows the search controller with prompt
        waitforExistence(app.staticTexts[LabelPrompt])
        app.typeText("\r")
        
        // Check that the website is loaded
        waitForValueContains(app.textFields["url"], value: "https://www.mozilla.org/")
        
        // Go back, write part of moz, check the autocompletion
        app.buttons["TabToolbar.backButton"].tap()
        navigator.nowAt(NewTabScreen)
        typeOnSearchBar(text: "moz")
        waitForValueContains(app.textFields["address"], value: "mozilla.org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "mozilla.org/")
    }

    private func changeSearchEngine(searchEngine: String) {
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).tap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts[searchEngine].tap()
        
        navigator.openURL(urlString: "foo")
        waitForValueContains(app.textFields["url"], value: searchEngine.lowercased())
        
        // Go here so that next time it is possible to access settings
        navigator.goto(BrowserTabMenu2)
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
        XCTAssert(app.tables.staticTexts["Yahoo"].exists)
    }
}
