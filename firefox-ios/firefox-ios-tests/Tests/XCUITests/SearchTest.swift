// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

private let LabelPrompt: String = "Turn on search suggestions?"
private let SuggestedSite: String = "foobar meaning"
private let SuggestedSite2: String = "foobar google"
private let SuggestedSite3: String = "foobar2000"

private let SuggestedSite4: String = "foobar buffer length"
private let SuggestedSite5: String = "foobar burn cd"
private let SuggestedSite6: String = "foobar bomb baby"

class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        app.textFields.firstMatch.waitAndTap()
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
        mozWaitForElementToExist(elementQuery.element)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436093
    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])

        // Suggestions should be shown
        mozWaitForElementToExist(app.tables["SiteTable"].cells.firstMatch)

        // Disable Search suggestion
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()

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

        // Verify that previous choice is remembered
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells[SuggestedSite])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()
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
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436094
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
                mozWaitForElementToExist(
                    app.tables["SiteTable"].cells.staticTexts[SuggestedSite3]
                )
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
                if #available(iOS 16, *) {
                    mozWaitForElementToExist(app.tables["SiteTable"].cells.staticTexts[SuggestedSite6])
                }
            }
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436095
    func testCopyPasteComplete() {
        // Copy, Paste and Go to url
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "www.mozilla.org")
        app.textFields["address"].press(forDuration: 5)
        app.menuItems["Select All"].tap()
        app.menuItems["Copy"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

        navigator.nowAt(HomePanelsScreen)
        mozWaitForElementToExist(
            app.collectionViews.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url].waitAndTap()
        app.textFields["address"].waitAndTap()

        app.menuItems["Paste"].waitAndTap()

        // Verify that the Paste shows the search controller with prompt
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])
        app.typeText("\r")
        waitUntilPageLoad()

        // Check that the website is loaded
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForValueContains(url, value: "www.mozilla.org")
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
        mozWaitForElementToExist(app.webViews.firstMatch)
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForValueContains(url, value: searchEngine.lowercased())
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306940
    // Smoketest
    func testSearchEngine() {
        navigator.nowAt(NewTabScreen)
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        changeSearchEngine(searchEngine: "DuckDuckGo")
        changeSearchEngine(searchEngine: "Google")
        changeSearchEngine(searchEngine: "eBay")
        changeSearchEngine(searchEngine: "Wikipedia")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353246
    func testDefaultSearchEngine() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436091
    func testSearchWithFirefoxOption() {
        navigator.nowAt(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["cloud"])
        // Select some text and long press to find the option
        app.webViews.staticTexts["cloud"].press(forDuration: 1)
        // Click on the > button to get to that option only on iPhone
        if #available(iOS 16, *) {
            while !app.collectionViews.menuItems["Search with Firefox"].exists {
                app.buttons["Forward"].firstMatch.tap()
                mozWaitForElementToExist(app.collectionViews.menuItems.firstMatch)
                mozWaitForElementToExist(app.buttons["Forward"])
            }
        } else {
            while !app.menuItems["Search with Firefox"].exists {
                app.menuItems["Show more items"].firstMatch.tap()
                mozWaitForElementToExist(app.menuItems.firstMatch)
                mozWaitForElementToExist(app.menuItems["Show more items"])
            }
        }

        app.menuItems["Search with Firefox"].waitAndTap()
        waitUntilPageLoad()
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForValueContains(url, value: "google")
        // Now there should be two tabs open
        let numTab = app.buttons["Show Tabs"].value as? String
        XCTAssertEqual("2", numTab)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436092
    // Smoketest
    func testSearchStartAfterTypingTwoWords() {
        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])
        app.typeText("foo bar")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        let url = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        mozWaitForElementToExist(url)
        mozWaitForValueContains(url, value: "google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306943
    func testSearchIconOnAboutHome() throws {
        if iPad() {
            throw XCTSkip("iPad does not have search icon")
        } else {
            waitForTabsButton()

            // Search icon is displayed.
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].waitAndTap()

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
            app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()

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

    // https://mozilla.testrail.io/index.php?/cases/view/2306989
    // Smoketest
    func testOpenTabsInSearchSuggestions() throws {
        if #unavailable(iOS 16) {
            throw XCTSkip("Test fails intermittently for iOS 15")
        }
        // Go to localhost website and check the page displays correctly
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        // Open new tab
        validateSearchSuggestionText(typeText: "localhost")
        restartInBackground()
        // Open new tab
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton]
        )
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        validateSearchSuggestionText(typeText: "localhost")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306886
    // SmokeTest
    func testBottomVIewURLBar() throws {
        if iPad() {
            throw XCTSkip("Toolbar option not available for iPad")
        } else {
            // Tap on toolbar bottom setting
            navigator.nowAt(NewTabScreen)
            navigator.goto(ToolbarSettings)
            navigator.performAction(Action.SelectToolbarBottom)
            navigator.goto(HomePanelsScreen)

            // URL bar is moved to the bottom of the screen
            let customizeHomepageElement = AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage
            let customizeHomepage = app.cells.otherElements.buttons[customizeHomepageElement]
            let menuSettingsButton = app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
            scrollToElement(customizeHomepage)
            mozWaitForElementToExist(customizeHomepage)
            let urlBar = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
            XCTAssertTrue(urlBar.isBelow(element: customizeHomepage))
            XCTAssertTrue(urlBar.isAbove(element: menuSettingsButton))

            // In a new tab, tap on the URL bar
            navigator.goto(NewTabScreen)
            urlBar.tap()

            // The URL bar is focused and the keyboard is displayed
            validateUrlHasFocusAndKeyboardIsDisplayed()

            // Open a website
            navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")

            // The keyboard is dismissed and page is correctly loaded
            let keyboardCount = app.keyboards.count
            XCTAssert(keyboardCount == 0, "The keyboard is shown")
            waitUntilPageLoad()

            // Tap on the URL bar
            urlBar.tap()

            // The URL bar is focused, Top Sites panel is displayed and the keyboard pops-up
            validateUrlHasFocusAndKeyboardIsDisplayed()
            mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])

            // Tap the back icon <
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].tap()

            // The focused is dismissed from the URL bar
            let addressBar = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
            XCTAssertFalse(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306942
    func testSearchSuggestions() {
        // Tap on URL Bar and type "g"
        navigator.nowAt(NewTabScreen)
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

        // Tap on the "Append Arrow button"
        app.tables.buttons["appendUpLeftLarge"].firstMatch.tap()

        // The search suggestion fills the URL bar but does not conduct the search
        let urlBarAddress = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.searchTextField]
        waitForValueContains(urlBarAddress, value: "g")
        XCTAssertEqual(app.tables.cells.count, 4, "There should be 4 search suggestions")

        // Delete the text and type "g"
        app.buttons["Clear text"].waitAndTap()
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

        // Tap on the text letter "g"
        app.tables.cells.firstMatch.tap()
        waitUntilPageLoad()

        // The search is conducted through the default search engine
        let urlBar = app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url]
        waitForValueContains(urlBar, value: "www.google.com/search?q=")

        // Disable "Show search suggestions" from Settings and type text in a new tab
        createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: false)

        // No search suggestions are displayed
        // Firefox suggest adds 2, 3 more cells
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: false)

        // Enable "Show search suggestions" from Settings and type text in a new tab
        app.tables.cells.firstMatch.tap()
        waitUntilPageLoad()
        createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: true)

        // Search suggestions are displayed
        // Firefox suggest adds 2, 3 more cells
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)
    }

    private func turnOnOffSearchSuggestions(turnOnSwitch: Bool) {
        let showSearchSuggestions = app.switches[AccessibilityIdentifiers.Settings.Search.showSearchSuggestions]
        mozWaitForElementToExist(showSearchSuggestions)
        let switchValue = showSearchSuggestions.value
        if switchValue as? String == "0", true && turnOnSwitch == true {
            showSearchSuggestions.tap()
        } else if switchValue as? String == "1", true && turnOnSwitch == false {
            showSearchSuggestions.tap()
        }
    }

    private func createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: Bool) {
        navigator.goto(SearchSettings)
        turnOnOffSearchSuggestions(turnOnSwitch: turnOnSwitch)
        navigator.goto(NewTabScreen)
        navigator.createNewTab()
        navigator.nowAt(NewTabScreen)
    }

    private func typeTextAndValidateSearchSuggestions(text: String, isSwitchOn: Bool) {
        typeOnSearchBar(text: text)
        // Search suggestions are shown
        if isSwitchOn {
            mozWaitForElementToExist(app.staticTexts.elementContainingText("google"))
            XCTAssertTrue(app.staticTexts.elementContainingText("google").exists)
            mozWaitForElementToExist(app.tables.cells.staticTexts["g"])
            XCTAssertTrue(app.tables.cells.count >= 4)
        } else {
            mozWaitForElementToNotExist(app.tables.buttons["appendUpLeftLarge"])
            mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Firefox Suggest"])
            XCTAssertTrue(app.tables.cells.count <= 3)
        }
    }

    private func validateUrlHasFocusAndKeyboardIsDisplayed() {
        let addressBar = app.textFields["address"]
        XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        let keyboardCount = app.keyboards.count
        XCTAssert(keyboardCount > 0, "The keyboard is not shown")
    }

// TODO: Add UI Tests back when felt privay simplified UI feature flag is enabled or when
// we support feature flags for tests
//    func testPrivateModeSearchSuggestsOnOffAndGeneralSearchSuggestsOn() {
//        navigator.nowAt(NewTabScreen)
//        navigator.goto(SearchSettings)
//        navigator.nowAt(SearchSettings)
//
//        // By default, disable search suggest in private mode
//        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[
//            AccessibilityIdentifiers.Settings.Search.disableSearchSuggestsInPrivateMode
//        ]
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
//        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[
//            AccessibilityIdentifiers.Settings.Search.disableSearchSuggestsInPrivateMode
//        ]
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
