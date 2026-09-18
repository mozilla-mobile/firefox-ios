// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

let defaultSearchEngine1 = "Google"
let defaultSearchEngine2 = "Bing"
let customSearchEngine = ["name": "youtube", "url": "https://youtube.com/search?q=%s"]

class SearchSettingsUITests: BaseTestCase {
    private var settingScreen: SettingScreen!
    private var toolbarScreen: ToolbarScreen!
    private var mainMenuScreen: MainMenuScreen!

    override func setUp() async throws {
        try await super.setUp()
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        settingScreen = SettingScreen(app: app)
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.navigateToSearchSettings()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2435664
    func testDefaultSearchEngine() {
        // Check the default browser
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine1])

        // Change to another browser and check it is set as default
        defaultSearchEngine.waitAndTap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[defaultSearchEngine2].waitAndTap()
        mozWaitForElementToExist(app.tables.cells.staticTexts[defaultSearchEngine2])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353247
    func testCustomSearchEngineIsEditable() {
        // Add a custom search engine
        addCustomSearchEngine()
        // Check that the custom search appears on the list
        mozWaitForElementToExist(app.tables.cells.staticTexts[customSearchEngine["name"]!])

        // Check that it can be edited
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].waitAndTap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        if #unavailable(iOS 17) {
            mozWaitForElementToExist(app.tables.buttons["Delete \(customSearchEngine["name"]!)"])
        } else {
            mozWaitForElementToExist(app.tables.buttons["Remove \(customSearchEngine["name"]!)"])
        }
    }

    private func addCustomSearchEngine() {
        app.tables.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton].waitAndTap()
        mozWaitForElementToExist(app.tables.cells.staticTexts["Search Engine"])
        app.tables.cells.textViews["customEngineTitle"].tapAndTypeText(customSearchEngine["name"]!)

        app.tables.cells.textViews["customEngineUrl"].tapAndTypeText(customSearchEngine["url"]!)
        app.buttons["Save"].waitAndTap(timeout: 5)
        // Check that custom engine has been added successfully
        mozWaitForElementToExist(app.tables.cells.staticTexts[customSearchEngine["name"]!])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353248
    // Regression
    func testCustomSearchEngineAsDefaultIsNotEditable() {
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(app.buttons["Edit"].isEnabled)

        // Select the custom engine as the default one
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.waitAndTap()
        let listOfEngines = app.tables
        listOfEngines.staticTexts[customSearchEngine["name"]!].waitAndTap()
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353249
    func testNavigateToSearchPickerTurnsOffEditing() {
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)

        addCustomSearchEngine()
        // Edit is enabled
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].waitAndTap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)

        // Navigate to the search engine picker and back
        let defaultSearchEngine = app.tables.cells.element(boundBy: 0)
        defaultSearchEngine.waitAndTap()
        app.buttons["Cancel"].waitAndTap()

        // Check to see we're not in editing state, edit is enable and done does not appear
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        mozWaitForElementToNotExist(app.buttons["Done"])

        // Make sure switches are there
        if isFennec {
            XCTAssertEqual(app.tables.cells.switches.count, app.tables.cells.count - 3)
        } else {
            // Enhanced search suggestion experiment is turned off on firefox
            // Suggestion switches are not available
            XCTAssertEqual(app.tables.cells.switches.count, app.tables.cells.count - 2)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2353250
    // Regression
    func testDeletingLastCustomEngineExitsEditing() {
        // Edit is disabled
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
        // Add a custom search engine
        addCustomSearchEngine()
        XCTAssertTrue(app.buttons["Edit"].isEnabled)
        app.buttons["Edit"].waitAndTap()
        // Remove the custom search engine and check that edit is disabled
        let tablesQuery = app.tables
        if #unavailable(iOS 17) {
            tablesQuery.buttons["Delete \(customSearchEngine["name"]!)"].waitAndTap()
        } else {
            tablesQuery.buttons["Remove \(customSearchEngine["name"]!)"].waitAndTap()
        }
        tablesQuery.buttons[AccessibilityIdentifiers.Settings.Search.deleteButton].waitAndTap()
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
    }
}

class SearchSettingsSuggestUITests: BaseTestCase {
    private let sponsoredSearchTerm = "amazon"
    private let sponsoredSuggestionTitle = "Amazon.com - Official Site"

    private var toolbarScreen: ToolbarScreen!
    private var mainMenuScreen: MainMenuScreen!
    private var settingScreen: SettingScreen!
    private var searchSettingsScreen: SearchSettingsScreen!
    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        toolbarScreen = ToolbarScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        settingScreen = SettingScreen(app: app)
        searchSettingsScreen = SearchSettingsScreen(app: app)
        browserScreen = BrowserScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2753086
    // Regression
    func testSearchSettingsMenuUIWithFirefoxSuggestEnabled() {
        enrollInFirefoxSuggestRollout(ingestingSuggestions: false)

        openSearchSettings()

        searchSettingsScreen.assertDefaultSearchEngineSectionExists()
        searchSettingsScreen.assertAlternativeSearchEnginesSectionExists()
        searchSettingsScreen.assertAddSearchEngineRowExists()
        searchSettingsScreen.assertShowSearchSuggestionsSwitchIsOn()
        searchSettingsScreen.assertShowInPrivateSessionsSwitchIsOff()
        searchSettingsScreen.assertSearchBrowsingHistorySwitchIsOn()
        searchSettingsScreen.assertSearchBookmarksSwitchIsOn()
        searchSettingsScreen.assertSearchSyncedTabsSwitchIsOn()
        searchSettingsScreen.assertSuggestionsFromTheWebSwitchIsOn()
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsOn()
        searchSettingsScreen.assertLearnMoreAboutFirefoxSuggestRowExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2753072
    // Regression
    func testSponsoredSuggestionsToggle() {
        enrollInFirefoxSuggestRollout()

        // Step 1: the toggle is displayed with its title and description
        openSearchSettings()
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsDisplayed()

        // Step 2: it is ON by default and can be switched both ways
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsOn()
        searchSettingsScreen.tapOnSuggestionsFromSponsorsSwitch()
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsOff()
        searchSettingsScreen.tapOnSuggestionsFromSponsorsSwitch()
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsOn()

        // Bug: sponsored suggestions may not show up on iPad
        // https://github.com/mozilla-mobile/firefox-ios/issues/35243
        guard !iPad() else { return }

        // Step 3: with the toggle ON, a sponsored suggestion is offered
        openNewTabFromSearchSettings()
        browserScreen.searchAndAssertSponsoredResult(term: sponsoredSearchTerm, title: sponsoredSuggestionTitle)

        // Step 4: with the toggle OFF, it is not
        browserScreen.dismissURLBarOverlay()
        openSearchSettings()
        searchSettingsScreen.tapOnSuggestionsFromSponsorsSwitch()
        searchSettingsScreen.assertSuggestionsFromSponsorsSwitchIsOff()
        openNewTabFromSearchSettings()
        browserScreen.searchFromAddressBar(term: sponsoredSearchTerm)
        // The Suggest section must still render, otherwise the sponsored entry could be missing
        // simply because no suggestions came back at all
        browserScreen.assertSponsoredResult(
            title: sponsoredSuggestionTitle,
            shouldExist: false,
            suggestSectionExists: true
        )
    }

    private func openSearchSettings() {
        toolbarScreen.tapSettingsMenuButton()
        mainMenuScreen.tapSettings()
        settingScreen.navigateToSearchSettings()
        searchSettingsScreen.assertNavBarVisible()
    }

    /// Backs out with direct taps, as the screen graph has no route out of SearchSettings: settings
    /// was opened by tapping rather than through the navigator, so no return path was recorded.
    private func openNewTabFromSearchSettings() {
        searchSettingsScreen.tapOnBackButton()
        settingScreen.closeSettingsWithDoneButton()
        navigator.nowAt(NewTabScreen)
        navigator.createNewTab()
    }
}
