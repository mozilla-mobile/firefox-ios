// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar meaning"
private let SuggestedSite2: String = "foobar google"
private let SuggestedSite3: String = "foobar2000"

private let SuggestedSite4: String = "foo bar baz"
private let SuggestedSite5: String = "foo bar baz qux"
private let SuggestedSite6: String = "foobar bit perfect"

class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        mozWaitForElementToExist(app.textFields.firstMatch, timeout: 10)
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(text)
    }

    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].tap()
        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
    }

    private func validateSearchSuggestionText(typeText: String) {
        // Open a new tab and start typing "text"
        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
        typeOnSearchBar(text: typeText)

        // In the search suggestion, "text" should be displayed
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", "http://localhost:")
        let elementQuery = app.staticTexts.containing(predicate)
        XCTAssertTrue(elementQuery.element.exists)
    }

    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        mozWaitForElementToExist(app.tables["SiteTable"].cells.firstMatch)
        XCTAssertTrue(app.tables["SiteTable"].cells.firstMatch.exists)

        // Disable Search suggestion
        app.buttons["urlBar-cancel"].tap()

        waitForTabsButton()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        navigator.nowAt(BrowserTabMenu)
        suggestionsOnOff()

        // Suggestions should not be shown
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells.firstMatch)
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells.firstMatch)
        XCTAssertFalse(app.tables["SiteTable"].cells.firstMatch.exists)

        // Verify that previous choice is remembered
        app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells[SuggestedSite])
        XCTAssertFalse(app.tables["SiteTable"].cells.firstMatch.exists)

        app.buttons["urlBar-cancel"].tap()
        waitForTabsButton()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].tap()
        navigator.nowAt(BrowserTabMenu)

        // Reset suggestion button, set it to on
        suggestionsOnOff()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        // Suggestions prompt should appear
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToExist(app.tables["SiteTable"].cells.firstMatch)
        XCTAssertTrue(app.tables["SiteTable"].cells.firstMatch.exists)
    }

    func testDoNotShowSuggestionsWhenEnteringURL() {
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string,
        // the suggestions are shown again
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        mozWaitForElementToExist(app.tables["SiteTable"])
        if !(app.tables["SiteTable"].cells.staticTexts[SuggestedSite].exists) {
            if !(app.tables["SiteTable"].cells.staticTexts[SuggestedSite2].exists) {
                mozWaitForElementToExist(app.tables["SiteTable"].cells.staticTexts[SuggestedSite3], timeout: 5)
            }
        }

        // Typing / should stop showing suggestions
        app.textFields["address"].typeText("/")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells[SuggestedSite])

        // Typing space and char after / should show suggestions again
        app.textFields["address"].typeText(" b")
        mozWaitForElementToExist(app.tables["SiteTable"])
        if !(app.tables["SiteTable"].cells.staticTexts[SuggestedSite4].exists) {
            if !(app.tables["SiteTable"].cells.staticTexts[SuggestedSite5].exists) {
                mozWaitForElementToExist(app.tables["SiteTable"].cells.staticTexts[SuggestedSite6])
            }
        }
    }

    func testCopyPasteComplete() throws {
        // Copy, Paste and Go to url
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.mozilla.org")
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        mozWaitForElementToExist(app.menuItems["Copy"], timeout: 3)
        app.menuItems["Copy"].tap()
        mozWaitForElementToExist(app.buttons["urlBar-cancel"])
        app.buttons["urlBar-cancel"].tap()

        navigator.nowAt(HomePanelsScreen)
        mozWaitForElementToExist(app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell], timeout: 10)
        mozWaitForElementToExist(app.textFields["url"], timeout: 3)
        app.textFields["url"].tap()
        mozWaitForElementToExist(app.textFields["address"], timeout: 3)
        app.textFields["address"].tap()

        mozWaitForElementToExist(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()

        // Verify that the Paste shows the search controller with prompt
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])
        app.typeText("\r")
        waitUntilPageLoad()

        // Check that the website is loaded
        mozWaitForValueContains(app.textFields["url"], value: "www.mozilla.org")
        waitUntilPageLoad()

        // Go back, write part of moz, check the autocompletion
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()
        typeOnSearchBar(text: "moz")
        mozWaitForValueContains(app.textFields["address"], value: "mozilla.org")
        let value = app.textFields["address"].value
        XCTAssertEqual(value as? String, "mozilla.org")
    }

    private func changeSearchEngine(searchEngine: String) {
        sleep(2)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).tap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts[searchEngine].tap()

        navigator.openURL("foo bar")
        // Workaroud needed after xcode 11.3 update Issue 5937
        // mozWaitForElementToExist(app.webViews.firstMatch, timeout: 3)
        mozWaitForValueContains(app.textFields["url"], value: searchEngine.lowercased())
    }

    // Smoketest
    func testSearchEngine() {
        navigator.nowAt(NewTabScreen)
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        changeSearchEngine(searchEngine: "DuckDuckGo")
        changeSearchEngine(searchEngine: "Google")
        changeSearchEngine(searchEngine: "eBay")
        changeSearchEngine(searchEngine: "Wikipedia")
        // Last check failing intermittently, temporary disabled
        // changeSearchEngine(searchEngine: "Amazon.com")
    }

    func testDefaultSearchEngine() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
    }

    func testSearchWithFirefoxOption() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["cloud"], timeout: 10)
        // Select some text and long press to find the option
        app.webViews.staticTexts["cloud"].press(forDuration: 1)
        // Click on the > button to get to that option only on iPhone
        while !app.collectionViews.menuItems["Search with Firefox"].exists {
            app.buttons["Forward"].firstMatch.tap()
            mozWaitForElementToExist(app.collectionViews.menuItems.firstMatch)
            mozWaitForElementToExist(app.buttons["Forward"])
        }

        mozWaitForElementToExist(app.menuItems["Search with Firefox"])
        app.menuItems["Search with Firefox"].tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "google")
        // Now there should be two tabs open
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)
    }
    // Bug https://bugzilla.mozilla.org/show_bug.cgi?id=1541832 scenario 4
    func testSearchStartAfterTypingTwoWords() {
        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(app.textFields["url"], timeout: 10)
        app.typeText("foo bar")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        mozWaitForElementToExist(app.textFields["url"], timeout: 20)
        mozWaitForValueContains(app.textFields["url"], value: "google")
    }

    func testSearchIconOnAboutHome() throws {
        if iPad() {
            throw XCTSkip("iPad does not have search icon")
        } else {
            waitForTabsButton()

            // Search icon is displayed.
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].exists)
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].tap()

            let addressBar = app.textFields["address"]
            mozWaitForElementToExist(addressBar)
            XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
            let keyboardCount = app.keyboards.count
            XCTAssert(keyboardCount > 0, "The keyboard is not shown")

            app.textFields["address"].typeText("www.google.com\n")
            waitUntilPageLoad()

            // Reload icon is displayed.
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].label, "Home")
            app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].tap()
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.backButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.backButton].tap()

            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].label, "Home")
            app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].tap()
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].tap()

            mozWaitForElementToExist(addressBar)
            XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
            let keyboardsCount = app.keyboards.count
            XCTAssert(keyboardsCount > 0, "The keyboard is not shown")
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306989
    // Smoketest
    func testOpenTabsInSearchSuggestions() {
        // Go to localhost website and check the page displays correctly
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        // Open new tab
        validateSearchSuggestionText(typeText: "localhost")
        restartInBackground()
        // Open new tab
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton], timeout: TIMEOUT)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        validateSearchSuggestionText(typeText: "localhost")
    }
// TODO: Add UI Tests back when felt privay simplified UI feature flag is enabled or when we support feature flags for tests
//    func testPrivateModeSearchSuggestsOnOffAndGeneralSearchSuggestsOn() {
//        navigator.nowAt(NewTabScreen)
//        navigator.goto(SearchSettings)
//        navigator.nowAt(SearchSettings)
//
//        // By default, disable search suggest in private mode
//        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[AccessibilityIdentifiers.Settings.Search.disableSearchSuggestsInPrivateMode]
//        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
//
//        app.navigationBars["Search"].buttons["Settings"].tap()
//        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
//
//        navigator.nowAt(NewTabScreen)
//        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
//        navigator.goto(URLBarOpen)
//        app.textFields["address"].typeText("ex")
//
//        let dimmingView = app.otherElements[AccessibilityIdentifiers.PrivateMode.dimmingView]
//        mozWaitForElementToExist(dimmingView)
//
//        // Enable search suggest in private mode
//        navigator.goto(SearchSettings)
//        navigator.nowAt(SearchSettings)
//
//        mozWaitForElementToNotExist(app.tables["SiteTable"])
//        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
//        privateModeSearchSuggestSwitch.tap()
//
//        app.navigationBars["Search"].buttons["Settings"].tap()
//        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
//
//        navigator.nowAt(NewTabScreen)
//        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
//        navigator.goto(URLBarOpen)
//        app.textFields["address"].typeText("ex")
//
//        mozWaitForElementToNotExist(dimmingView)
//        mozWaitForElementToExist(app.tables["SiteTable"])
//    }
//
//    func testPrivateModeSearchSuggestsOnOffAndGeneralSearchSuggestsOff() {
//        // Disable general search suggests
//        suggestionsOnOff()
//        navigator.nowAt(NewTabScreen)
//        navigator.goto(SearchSettings)
//        navigator.nowAt(SearchSettings)
//
//        // By default, disable search suggest in private mode
//        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[AccessibilityIdentifiers.Settings.Search.disableSearchSuggestsInPrivateMode]
//        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
//
//        app.navigationBars["Search"].buttons["Settings"].tap()
//        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
//
//        navigator.nowAt(NewTabScreen)
//        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
//        navigator.goto(URLBarOpen)
//        app.textFields["address"].typeText("ex")
//
//        let dimmingView = app.otherElements[AccessibilityIdentifiers.PrivateMode.dimmingView]
//        mozWaitForElementToExist(dimmingView)
//
//        // Enable search suggest in private mode
//        navigator.goto(SearchSettings)
//        navigator.nowAt(SearchSettings)
//
//        mozWaitForElementToNotExist(app.tables["SiteTable"])
//        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
//        privateModeSearchSuggestSwitch.tap()
//
//        app.navigationBars["Search"].buttons["Settings"].tap()
//        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()
//
//        navigator.nowAt(NewTabScreen)
//        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
//        navigator.goto(URLBarOpen)
//        app.textFields["address"].typeText("ex")
//
//        mozWaitForElementToNotExist(dimmingView)
//        mozWaitForElementToExist(app.tables["SiteTable"])
//    }
}
