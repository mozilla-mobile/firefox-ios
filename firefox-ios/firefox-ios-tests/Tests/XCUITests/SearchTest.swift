// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

private let LabelPrompt = "Turn on search suggestions?"
private let SuggestedSite = "foobar meaning"
private let SuggestedSite2 = "foobar google"
private let SuggestedSite3 = "foobar2000"

private let SuggestedSite4 = "foobar buffer length"
private let SuggestedSite5 = "foobar burn cd"
private let SuggestedSite6 = "foobar bomb baby"

class SearchTests: BaseTestCase {
    private func typeOnSearchBar(text: String) {
        app.textFields.firstMatch.waitAndTap()
        app.textFields.firstMatch.tapAndTypeText(text)
    }

    private func suggestionsOnOff() {
        navigator.goto(SearchSettings)
        app.tables.switches["Show Search Suggestions"].waitAndTap()
        app.navigationBars["Search"].buttons["Settings"].waitAndTap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
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
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

        waitForTabsButton()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        navigator.nowAt(BrowserTabMenu)
        suggestionsOnOff()

        // Suggestions should not be shown
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells.firstMatch)
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells.firstMatch)

        // Verify that previous choice is remembered
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()

        typeOnSearchBar(text: "foobar")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells[SuggestedSite])

        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        waitForTabsButton()
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
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
        urlBarAddress.typeText("/")
        mozWaitForElementToNotExist(app.tables["SiteTable"].cells[SuggestedSite])

        // Typing space and char after / should show suggestions again
        urlBarAddress.typeText(" b")
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
        if #available(iOS 17, *), ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 17
            || iPad() {
            urlBarAddress.waitAndTap()
            urlBarAddress.waitAndTap()
        } else {
            urlBarAddress.press(forDuration: 5)
        }
        app.menuItems["Select All"].waitAndTap()
        app.menuItems["Copy"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

        navigator.nowAt(HomePanelsScreen)
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].waitAndTap()
        urlBarAddress.waitAndTap()

        app.menuItems["Paste"].waitAndTap()

        // Verify that the Paste shows the search controller with prompt
        mozWaitForElementToNotExist(app.staticTexts[LabelPrompt])
        app.typeText("\r")
        waitUntilPageLoad()

        // Check that the website is loaded
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "mozilla.org")
        waitUntilPageLoad()

        // Go back, write part of moz, check the autocompletion
        app.buttons[AccessibilityIdentifiers.Toolbar.backButton].waitAndTap()
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()
        typeOnSearchBar(text: "moz")
        mozWaitForValueContains(urlBarAddress, value: "mozilla.org")
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "mozilla.org")
    }

    private func changeSearchEngine(searchEngine: String) {
        sleep(2)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton])
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).waitAndTap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts[searchEngine].waitAndTap()

        navigator.openURL("foo bar")
        mozWaitForElementToExist(app.webViews.firstMatch)
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
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
        changeSearchEngine(searchEngine: "Wikipedia")
        changeSearchEngine(searchEngine: "eBay")
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
                app.buttons["Forward"].firstMatch.waitAndTap()
                waitForElementsToExist(
                    [
                        app.collectionViews.menuItems.firstMatch,
                        app.buttons["Forward"]
                    ]
                )
            }
        } else {
            while !app.menuItems["Search with Firefox"].exists {
                app.menuItems["Show more items"].firstMatch.waitAndTap()
                waitForElementsToExist(
                    [
                        app.menuItems.firstMatch,
                        app.menuItems["Show more items"]
                    ]
                )
            }
        }

        app.menuItems["Search with Firefox"].waitAndTap()
        waitUntilPageLoad()
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "google")
        // Now there should be two tabs open
        let numTab = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value as? String
        XCTAssertEqual("2", numTab)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436092
    // Smoketest
    func testSearchStartAfterTypingTwoWords() {
        navigator.goto(URLBarOpen)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        app.typeText("foo bar")
        app.typeText(XCUIKeyboardKey.return.rawValue)
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
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

            let addressBar = urlBarAddress
            mozWaitForElementToExist(addressBar)
            XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
            let keyboardCount = app.keyboards.count
            XCTAssert(keyboardCount > 0, "The keyboard is not shown")

            urlBarAddress.typeText("www.google.com\n")
            waitUntilPageLoad()

            // Reload icon is displayed.
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].label, "Home")
            app.buttons[AccessibilityIdentifiers.Toolbar.homeButton].waitAndTap()
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].label, "Search")
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton].waitAndTap()

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
            let urlBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
            XCTAssertTrue(urlBar.isBelow(element: customizeHomepage))
            XCTAssertTrue(urlBar.isAbove(element: menuSettingsButton))

            // In a new tab, tap on the URL bar
            navigator.goto(NewTabScreen)
            urlBar.waitAndTap()

            // The URL bar is focused and the keyboard is displayed
            validateUrlHasFocusAndKeyboardIsDisplayed()

            // Open a website
            navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")

            // The keyboard is dismissed and page is correctly loaded
            let keyboardCount = app.keyboards.count
            XCTAssert(keyboardCount == 0, "The keyboard is shown")
            waitUntilPageLoad()

            // Tap on the URL bar
            urlBar.waitAndTap()

            // The URL bar is focused, Top Sites panel is displayed and the keyboard pops-up
            validateUrlHasFocusAndKeyboardIsDisplayed()
            mozWaitForElementToExist(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])

            // Tap the back icon <
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

            // The focused is dismissed from the URL bar
            let addressBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
            XCTAssertFalse(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306942
    func testSearchSuggestions() throws {
        guard #available(iOS 17.0, *) else { return }

        // Tap on URL Bar and type "g"
        navigator.nowAt(NewTabScreen)
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

        // Tap on the "Append Arrow button"
        app.tables.buttons[StandardImageIdentifiers.Large.appendUpLeft].firstMatch.waitAndTap()

        // The search suggestion fills the URL bar but does not conduct the search
        waitForValueContains(urlBarAddress, value: "g")
        XCTAssertEqual(app.tables.cells.count, 4, "There should be 4 search suggestions")

        // Delete the text and type "g"
        app.textFields.firstMatch.waitAndTap()
        app.buttons["Clear text"].waitAndTap()
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

        // Tap on the text letter "g"
        app.tables.cells.firstMatch.waitAndTap()
        waitUntilPageLoad()

        // The search is conducted through the default search engine
        let urlBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        waitForValueContains(urlBar, value: "google.com")

        // Disable "Show search suggestions" from Settings and type text in a new tab
        createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: false)

        // No search suggestions are displayed
        // Firefox suggest adds 2, 3 more cells
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: false)

        // Enable "Show search suggestions" from Settings and type text in a new tab
        app.tables.cells.firstMatch.waitAndTap()
        waitUntilPageLoad()
        createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: true)

        // Search suggestions are displayed
        // Firefox suggest adds 2, 3 more cells
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2576803
    func testFirefoxSuggest() {
        // In history: mozilla.org
        navigator.openURL("https://www.mozilla.org/en-US/")
        waitUntilPageLoad()

        // Bookmark The Book of Mozilla (on localhost)
        navigator.openNewURL(urlString: "localhost:\(serverPort)/test-fixture/test-mozilla-book.html")
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        navigator.goto(SaveBrowserTabMenu)
        navigator.performAction(Action.Bookmark)

        // Close all tabs so that the search result does not include
        // current tabs.
        navigator.performAction(Action.AcceptRemovingAllTabs)

        // Type partial match ("mo") of the history and the bookmark
        navigator.goto(NewTabScreen)
        typeOnSearchBar(text: "mo")

        // Google Search appears
        mozWaitForElementToExist(app.tables["SiteTable"].otherElements["Google Search"])
        mozWaitForElementToExist(app.tables["SiteTable"].buttons[StandardImageIdentifiers.Large.appendUpLeft])

        // Firefox Suggest appears
        mozWaitForElementToExist(app.tables["SiteTable"].otherElements["Firefox Suggest"])
        mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["The Book of Mozilla"]) // Bookmark
        mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["www.mozilla.org/"]) // History
    }

    private func turnOnOffSearchSuggestions(turnOnSwitch: Bool) {
        let showSearchSuggestions = app.switches[AccessibilityIdentifiers.Settings.Search.showSearchSuggestions]
        mozWaitForElementToExist(showSearchSuggestions)
        let switchValue = showSearchSuggestions.value
        if switchValue as? String == "0", true && turnOnSwitch == true {
            showSearchSuggestions.waitAndTap()
        } else if switchValue as? String == "1", true && turnOnSwitch == false {
            showSearchSuggestions.waitAndTap()
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
        let appendArrowBtn = app.tables.cells.buttons.matching(identifier: "appendUpLeftLarge")
        if isSwitchOn {
            mozWaitForElementToExist(app.staticTexts.elementContainingText("google"))
            mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Google Search"])
            XCTAssertTrue(app.staticTexts.elementContainingText("google").exists)
            mozWaitForElementToExist(app.tables.cells.staticTexts["g"])
            XCTAssertTrue(appendArrowBtn.count == 3)
        } else {
            mozWaitForElementToNotExist(app.tables.buttons[StandardImageIdentifiers.Large.appendUpLeft])
            mozWaitForElementToExist(app.tables["SiteTable"].staticTexts["Firefox Suggest"])
            mozWaitForElementToExist(app.tables.cells.firstMatch)
            // If "Append Arrow buttons" are missing, then google search suggestions are missing
            mozWaitForElementToNotExist(appendArrowBtn.element)
            mozWaitForElementToNotExist(app.tables.cells.staticTexts["g"])
        }
    }

    private func validateUrlHasFocusAndKeyboardIsDisplayed() {
        let addressBar = urlBarAddress
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
//        urlBarAddress.typeText("ex")
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
//        urlBarAddress.typeText("ex")
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
//        urlBarAddress.typeText("ex")
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
//        urlBarAddress.typeText("ex")
//
//        mozWaitForElementToNotExist(dimmingView)
//        mozWaitForElementToExist(app.tables["SiteTable"])
//    }
}
