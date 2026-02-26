// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

private let LabelPrompt = "Turn on search suggestions?"
private let SuggestedSite = "foobar meaning"
private let SuggestedSite2 = "foobar google"
private let SuggestedSite3 = "foobar"

private let SuggestedSite4 = "foobar buffer length"
private let SuggestedSite5 = "foobar burn cd"
private let SuggestedSite6 = "foobar/ b"

class SearchTests: FeatureFlaggedTestBase {
    var toolbarScreen: ToolbarScreen!
    var browserScreen: BrowserScreen!
    var firefoxHomePageScreen: FirefoxHomePageScreen!
    var searchScreen: SearchScreen!
    var searchSettingsScreen: SearchSettingsScreen!
    var settingsScreen: SettingScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        searchSettingsScreen = SearchSettingsScreen(app: app)
        searchScreen = SearchScreen(app: app)
    }

    private func typeOnSearchBar(text: String) {
        browserScreen.tapOnAddressBar()
        browserScreen.getAddressBarElement().tapAndTypeText(text)
    }

    private func enterTextOnSearchBar(text: String) {
        browserScreen.tapOnAddressBar()
        browserScreen.typeOnSearchBar(text: text)
        browserScreen.typeOnSearchBar(text: "\r")
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
        typeOnSearchBar(text: typeText)

        // In the search suggestion, "text" should be displayed
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", "localhost")
        let elementQuery = app.staticTexts.containing(predicate)
        mozWaitForElementToExist(elementQuery.element)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436093
    func testPromptPresence() {
        // Suggestion is on by default (starting on Oct 24th 2017), so the prompt should not appear
        app.launch()
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
        app.launch()
        // According to bug 1192155 if a string contains /, do not show suggestions, if there a space an a string,
        // the suggestions are shown again
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
        app.launch()
        typeOnSearchBar(text: "www.mozilla.org")
        if #available(iOS 17, *), ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 17
            || iPad() {
            urlBarAddress.waitAndTap()
            urlBarAddress.waitAndTap()
        } else {
            urlBarAddress.press(forDuration: 1)
        }
        if !app.menuItems["Select All"].waitForExistence(timeout: 3) {
            urlBarAddress.waitAndTap()
        }
        app.menuItems["Select All"].waitAndTap()
        app.menuItems["Copy"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()

        navigator.nowAt(HomePanelsScreen)
        mozWaitForElementToExist(
            app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        )
        navigator.goto(URLBarOpen)

        if !iPad() {
            urlBarAddress.waitAndTap()
        }
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
        waitForTabsButton()
        typeOnSearchBar(text: "moz")
        mozWaitForValueContains(urlBarAddress, value: "moz")
        let value = urlBarAddress.value
        XCTAssertEqual(value as? String, "mozilla.org")
    }

    private func changeSearchEngine(searchEngine: String) {
        let toolbarScreen = ToolbarScreen(app: app)
        let browserScreen = BrowserScreen(app: app)
        let searchSettingsScreen = SearchSettingsScreen(app: app)

        toolbarScreen.assertSettingsButtonExists(timeout: TIMEOUT)
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(SearchSettings)
        // Open the list of default search engines and select the desired
        app.tables.cells.element(boundBy: 0).waitAndTap()
        let tablesQuery2 = app.tables
        tablesQuery2.staticTexts.elementContainingText(searchEngine).waitAndTap()

        searchSettingsScreen.waitForSearchEngineSelectionComplete()

        navigator.goto(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL("foo bar")
        mozWaitForElementToExist(app.webViews.firstMatch)
        browserScreen.addressToolbarContainValue(value: searchEngine.lowercased())
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306940
    // Smoketest
    func testSearchEngine() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        // Change to the each search engine and verify the search uses it
        changeSearchEngine(searchEngine: "Bing")
        changeSearchEngine(searchEngine: "DuckDuckGo")
        changeSearchEngine(searchEngine: "Google")
        changeSearchEngine(searchEngine: "Perplexity")
        changeSearchEngine(searchEngine: "Wikipedia")
        changeSearchEngine(searchEngine: "eBay")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353246
    func testDefaultSearchEngine() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2436091
    func testSearchWithFirefoxOption() {
        app.launch()
        navigator.openURL(path(forTestPage: "test-mozilla-book.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.staticTexts["cloud"])
        // Select some text and long press to find the option
        app.webViews.staticTexts["cloud"].press(forDuration: 1)
        // Click on the > button to get to that option only on iPhone
        if #available(iOS 26, *) {
            while !app.collectionViews.buttons["Search with Firefox"].exists {
                app.buttons["Forward"].firstMatch.waitAndTap()
                waitForElementsToExist(
                    [
                        app.buttons["Forward"].firstMatch,
                        app.collectionViews.buttons.firstMatch
                    ]
                )
            }
        } else if #available(iOS 16, *) {
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
        if #available(iOS 26, *) {
            app.buttons["Search with Firefox"].waitAndTap()
        } else {
            app.menuItems["Search with Firefox"].waitAndTap()
        }
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
        let browserScreen = BrowserScreen(app: app)
        let fooText = "foo bar"
        app.launch()
        navigator.goto(URLBarOpen)
        app.typeText(fooText)
        app.typeText(XCUIKeyboardKey.return.rawValue)
        browserScreen.assertAddressBarContains(value: "google", timeout: TIMEOUT)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306943
    func testSearchIconOnAboutHome() throws {
        app.launch()
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
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
            XCTAssertEqual(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].label, "New Tab")
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
            mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton])
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.searchButton])
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
        let browserScreen = BrowserScreen(app: app)
        let toolbarScreen = ToolbarScreen(app: app)
        app.launch()
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
        browserScreen.assertCancelButtonOnUrlBarExists()
        toolbarScreen.assertTabsButtonExists()
        browserScreen.tapCancelButtonIfExist()
        validateSearchSuggestionText(typeText: "localhost")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306886
    // SmokeTest
    func testBottomVIewURLBar() throws {
        let toolbarScreen = ToolbarScreen(app: app)
        let browserScreen = BrowserScreen(app: app)
        let firefoxHomePageScreen = FirefoxHomePageScreen(app: app)

        app.launch()
        if iPad() {
            throw XCTSkip("Toolbar option not available for iPad")
        } else {
            // Tap on toolbar bottom setting
            navigator.nowAt(NewTabScreen)
            navigator.goto(ToolbarSettings)
            navigator.performAction(Action.SelectToolbarBottom)
            navigator.goto(HomePanelsScreen)
            navigator.goto(URLBarOpen)

            // URL bar is moved to the bottom of the screen
            let menuSettingsButton = toolbarScreen.getToolbarSettingsMenuButtonElement()
            let firstTopSite = app.links.element(boundBy: 0)
            toolbarScreen.assertSettingsButtonExists()
            let urlBar = browserScreen.getAddressBarElement()
            XCTAssertTrue(urlBar.isAbove(element: menuSettingsButton))
            XCTAssertTrue(urlBar.isBelow(element: firstTopSite))

            // In a new tab, tap on the URL bar
            navigator.goto(NewTabScreen)
            navigator.nowAt(HomePanelsScreen)
            navigator.goto(URLBarOpen)
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
            firefoxHomePageScreen.assertTopSitesItemCellExist()

            // Tap the back icon <
            browserScreen.tapCancelButtonOnUrlBarExist()

            // The focused is dismissed from the URL bar
            browserScreen.assertKeyboardFocusState(isFocusedOniPad: false)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306942
    func testSearchSuggestions() throws {
        guard #available(iOS 17.0, *) else { return }

        // Tap on URL Bar and type "g"
        app.launch()
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)

        // Tap on the "Append Arrow button"
        app.tables.buttons[StandardImageIdentifiers.Large.appendUpLeft].firstMatch.waitAndTap()

        // The search suggestion fills the URL bar but does not conduct the search
        waitForValueContains(urlBarAddress, value: "g")
        XCTAssertEqual(app.tables.cells.count, 4, "There should be 4 search suggestions")

        // Delete the text and type "g"
        app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
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
        navigator.nowAt(BrowserTab)
        createNewTabAfterModifyingSearchSuggestions(turnOnSwitch: true)

        // Search suggestions are displayed
        // Firefox suggest adds 2, 3 more cells
        typeTextAndValidateSearchSuggestions(text: "g", isSwitchOn: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2576803
    func testFirefoxSuggest() {
        // In history: mozilla.org
        app.launch()
        navigator.openURL("https://www.mozilla.org/en-US/")
        waitUntilPageLoad()

        // Bookmark The Book of Mozilla (on localhost)
        navigator.createNewTab()
        navigator.openURL("localhost:\(serverPort)/test-fixture/test-mozilla-book.html")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // navigator.goto(SaveBrowserTabMenu)
        navigator.performAction(Action.Bookmark)

        // Close all tabs so that the search result does not include
        // current tabs.
        navigator.performAction(Action.AcceptRemovingAllTabs)

        // Type partial match ("mo") of the history and the bookmark
        navigator.goto(TabTray)
        navigator.goto(HomePanelsScreen)
        typeOnSearchBar(text: "mo")

        // Google Search appears
        mozWaitForElementToExist(app.tables["SiteTable"].otherElements["Google Search"])

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
        navigator.nowAt(BrowserTab)
        navigator.goto(SearchSettings)
        turnOnOffSearchSuggestions(turnOnSwitch: turnOnSwitch)
        navigator.nowAt(SearchSettings)
        navigator.goto(BrowserTab)
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

    // https://mozilla.testrail.io/index.php?/cases/view/2753105
    func testPrivateModeSearchSuggestsOnOffAndGeneralSearchSuggestsOn_feltPrivacySimplifiedUIExperimentOn() {
        addLaunchArgument(jsonFileName: "feltPrivacySimplifiedUIOn", featureName: "felt-privacy-feature")
        app.launch()
        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        // By default, disable search suggest in private mode
        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[
            AccessibilityIdentifiers.Settings.Search.showPrivateSuggestions
        ].switches.firstMatch
        mozWaitForElementToExist(privateModeSearchSuggestSwitch)

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")

        let dimmingView = app.otherElements[AccessibilityIdentifiers.PrivateMode.dimmingView]
        mozWaitForElementToExist(dimmingView)

        // Enable search suggest in private mode
        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        mozWaitForElementToNotExist(app.tables["SiteTable"])
        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
        privateModeSearchSuggestSwitch.tap()

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")

        mozWaitForElementToNotExist(dimmingView)
        mozWaitForElementToExist(app.tables["SiteTable"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3374353
    func testPrivateModeSearchSuggestsOnOffAndGeneralSearchSuggestsOff_feltPrivacySimplifiedUIExperimentOn() {
        addLaunchArgument(jsonFileName: "feltPrivacySimplifiedUIOn", featureName: "felt-privacy-feature")
        app.launch()
        // Disable general search suggests
        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)
        app.tables.switches["Show Search Suggestions"].waitAndTap()

        // By default, disable search suggest in private mode
        let privateModeSearchSuggestSwitch = app.otherElements.tables.cells[
            AccessibilityIdentifiers.Settings.Search.showPrivateSuggestions
        ].switches.firstMatch
        mozWaitForElementToExist(privateModeSearchSuggestSwitch)

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        navigator.nowAt(NewTabScreen)
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(BrowserTab)
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")

        let dimmingView = app.otherElements[AccessibilityIdentifiers.PrivateMode.dimmingView]
        mozWaitForElementToExist(dimmingView)

        // Enable search suggest in private mode
        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        mozWaitForElementToNotExist(app.tables["SiteTable"])
        mozWaitForElementToExist(privateModeSearchSuggestSwitch)
        privateModeSearchSuggestSwitch.tap()

        app.navigationBars["Search"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons[AccessibilityIdentifiers.Settings.navigationBarItem].tap()

        navigator.nowAt(NewTabScreen)
        navigator.goto(URLBarOpen)
        urlBarAddress.typeText("ex")

        mozWaitForElementToNotExist(dimmingView)
        mozWaitForElementToExist(app.tables["SiteTable"])
    }

    // MARK: - Pre Search (Trending Searches + Recent Searches)
    // https://mozilla.testrail.io/index.php?/cases/view/3296489
    func testTrendingSearches_trendingSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "trending-searches-feature")

        app.launch()

        navigateToWebPage()

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()

        // Trending Search appears
        searchScreen.assertSearchTableVisible()
        searchScreen.assertTrendingSearchesSectionTitle(with: "Google")
        searchScreen.tapOnFirstCell()

        waitUntilPageLoad()

        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForElementToExist(url)
        browserScreen.assertAddressBarContains(value: "google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296488
    func testTrendingSearchesSettingsToggleOn_trendingSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "trending-searches-feature")

        app.launch()
        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        // By default, Trending Searches is Enabled
        searchSettingsScreen.assertTrendingSearchesSwitchIsOn()
        searchSettingsScreen.assertRecentSearchesSwitchDoesNotExist()

        searchSettingsScreen.assertNavBarVisible()

        dismissSearchSettingsScreen()

        navigateToWebPage()

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()
        searchScreen.assertTrendingSearchesSectionTitle(with: "Google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296487
    func testTrendingSearchesSettingsToggleOff_trendingSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "trending-searches-feature")
        app.launch()

        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        searchSettingsScreen.assertTrendingSearchesSwitchIsOn()
        searchSettingsScreen.assertRecentSearchesSwitchDoesNotExist()

        // Disable Trending Searches in Settings
        searchSettingsScreen.tapOnTrendingSearchesSwitch()

        dismissSearchSettingsScreen()

        navigateToWebPage()

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()
        searchScreen.assertTrendingSearchesSectionTitleDoesNotExist(with: "Google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296486
    func testTrendingSearches_afterClearingURL_trendingSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "trending-searches-feature")

        app.launch()

        navigateToWebPage()

        typeOnSearchBar(text: "example")

        // Search Suggestions appears
        searchScreen.assertSearchSectionVisible(with: "Google")

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()
        browserScreen.clearURL()

        // Trending Search appears
        searchScreen.assertTrendingSearchesSectionTitle(with: "Google")
        searchScreen.tapOnFirstCell()
        waitUntilPageLoad()

        browserScreen.assertAddressBarContains(value: "google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296485
    func testRecentSearches_recentSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "recent-searches-feature")

        app.launch()
        navigateToWebPage()

        enterTextOnSearchBar(text: "example")

        browserScreen.tapOnAddressBar()
        browserScreen.clearURL()

        // Recent Search appears
        searchScreen.assertSearchTableVisible()
        searchScreen.assertRecentSearchesSectionTitle()
        searchScreen.tapOnFirstCell()

        waitUntilPageLoad()

        browserScreen.assertAddressBarContains(value: "google")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296482
    func testRecentSearchesWithNoRecentSearches_recentSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "recent-searches-feature")

        app.launch()
        navigateToWebPage()

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()

        searchScreen.assertSearchTableVisible()
        searchScreen.assertRecentSearchesSectionTitleDoesNotExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296480
    func testRecentSearchesSettingsToggleOn_recentSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "recent-searches-feature")

        app.launch()

        enterTextOnSearchBar(text: "example")

        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        // By default, enable trending searches
        searchSettingsScreen.assertRecentSearchesSwitchIsOn()
        searchSettingsScreen.assertTrendingSearchesSwitchDoesNotExist()

        searchSettingsScreen.assertNavBarVisible()

        dismissSearchSettingsScreen()

        navigateToWebPage()

        browserScreen.tapOnAddressBar()
        searchScreen.assertRecentSearchesSectionTitle()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296479
    func testRecentSearchesSettingsToggleOff_recentSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "recent-searches-feature")
        app.launch()

        enterTextOnSearchBar(text: "example")

        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        searchSettingsScreen.assertRecentSearchesSwitchIsOn()
        searchSettingsScreen.assertTrendingSearchesSwitchDoesNotExist()

        // Disable Recent Searches in Settings
        searchSettingsScreen.tapOnRecentSearchesSwitch()

        dismissSearchSettingsScreen()

        navigateToWebPage()

        browserScreen.tapOnAddressBar()
        searchScreen.assertRecentSearchesSectionTitleDoesNotExist()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3296478
    func testTrendingSearchesAndRecentSearchesSettingsToggleOn_trendingSearchesAndRecentSearchesExperimentOn() {
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "trending-searches-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOn", featureName: "recent-searches-feature")

        app.launch()

        enterTextOnSearchBar(text: "example")

        navigator.goto(SearchSettings)
        navigator.nowAt(SearchSettings)

        // Both Recent Searches + Trending Searches are On
        searchSettingsScreen.assertTrendingSearchesSwitchIsOn()
        searchSettingsScreen.assertRecentSearchesSwitchIsOn()

        dismissSearchSettingsScreen()
        navigateToWebPage()

        browserScreen.assertAddressBarExists()
        browserScreen.tapOnAddressBar()
        searchScreen.assertTrendingSearchesSectionTitle(with: "Google")
        searchScreen.assertRecentSearchesSectionTitle()
    }

    private func dismissSearchSettingsScreen() {
        searchSettingsScreen.tapOnBackButton()
        settingsScreen.closeSettingsWithDoneButton()
    }

    private func navigateToWebPage() {
        let urlPath = path(forTestPage: "https://www.mozilla.org/en-US/")
        enterTextOnSearchBar(text: urlPath)
        waitUntilPageLoad()
    }
}
