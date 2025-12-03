// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = "test-example.html"
let urlExampleLabel = "Example Domain"
let urlMozillaLabel = "Internet for people, not profit — Mozilla (US)"

class HomePageSettingsUITests: FeatureFlaggedTestBase {
    private func enterWebPageAsHomepage(text: String) {
        app.textFields["HomeAsCustomURLTextField"].tapAndTypeText(text)
        let value = app.textFields["HomeAsCustomURLTextField"].value
        XCTAssertEqual(value as? String, text, "The webpage typed does not match with the one saved")
    }
    let testWithDB = ["testTopSitesCustomNumberOfRows"]
    let prefilledTopSites = "testBookmarksDatabase1000-browser.db"

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        if testWithDB.contains(key) {
            // for the current test name, add the db fixture used
            launchArguments = [LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.LoadDatabasePrefix + prefilledTopSites,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
        }
        super.setUp()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339256
    func testCheckHomeSettingsByDefault() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)

        waitForElementsToExist(
            [
                app.navigationBars["Homepage"],
                app.tables.otherElements["OPENING SCREEN"],
                app.tables.otherElements["INCLUDE ON HOMEPAGE"],
                app.tables.otherElements["CURRENT HOMEPAGE"]
            ]
        )

        // Opening Screen
        XCTAssertFalse(app.tables.cells["StartAtHomeAlways"].isSelected)
        XCTAssertFalse(app.tables.cells["StartAtHomeDisabled"].isSelected)
        XCTAssertTrue(app.tables.cells["StartAtHomeAfterFourHours"].isSelected)

        // Include on Homepage
        mozWaitForElementToExist(app.tables.cells["TopSitesSettings"].staticTexts["On"])

        // Current Homepage
        XCTAssertTrue(app.tables.cells["Firefox Home"].isSelected)
        mozWaitForElementToExist(app.tables.cells["HomeAsCustomURL"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339257
    func testTyping() throws {
        let shouldSkipTest = true
        try XCTSkipIf(shouldSkipTest,
                      "Skipping test based on https://github.com/mozilla-mobile/firefox-ios/issues/28117.")
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: "example.com")

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(SettingsScreen)
        navigator.goto(HomeSettings)
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "http://example.com")

        // Check that it is actually set by opening a different website and going to Home
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Now check open home page should load the previously saved home page
        app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton].waitAndTap()
        waitUntilPageLoad()
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "example.com")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339258
    func testClipboard() {
        app.launch()
        navigator.nowAt(NewTabScreen)
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomeAsCustomURLTextField"].waitAndTap()
        if #unavailable(iOS 16) {
            sleep(2)
        }
        let textField = app.textFields["HomeAsCustomURLTextField"]
        let pasteOption = app.menuItems["Paste"]
        textField.pressWithRetry(duration: 2, element: pasteOption)
        pasteOption.waitAndTap()
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correctly copied into the correct field
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: websiteUrl1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339260
    func testSetFirefoxHomeAsHome() {
        app.launch()
        // Go to homepage settings
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Firefox home and custom URL options are displayed
        // Firefox Home is selected by default
        mozWaitForElementToExist(app.tables.cells["HomeAsFirefoxHome"])
        mozWaitForElementToExist(app.tables.cells["HomeAsCustomURL"])
        XCTAssertTrue(app.tables.cells["HomeAsFirefoxHome"].isSelected, "Firefox Home is not selected by default")
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        // Add a new tab
        navigator.performAction(Action.GoToHomePage)
        // A new tab with Firefox homepage is added
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307031
    func testSetCustomURLAsHome() throws {
        let shouldSkipTest = true
        try XCTSkipIf(shouldSkipTest,
                      "Skipping test based on https://github.com/mozilla-mobile/firefox-ios/issues/28117.")
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Open a new tab and tap on Home option
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "mozilla.org")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339489
    func testDisableTopSitesSettingsRemovesSection() {
        app.launch()
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
        )
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        app.cells[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage].waitAndTap()
        XCTAssertTrue(app.switches["Shortcuts"].exists)
        app.switches["Shortcuts"].waitAndTap()

        navigator.goto(NewTabScreen)
        app.buttons["Done"].waitAndTap()

        mozWaitForElementToNotExist(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        mozWaitForElementToNotExist(app.collectionViews.cells.staticTexts["YouTube"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339491
    func testChangeHomeSettingsLabel() {
        app.launch()
        // Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectHomeAsCustomURL)
        navigator.nowAt(HomeSettings)
        // Enter a custom URL
        enterWebPageAsHomepage(text: websiteUrl1)
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["Home"])
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Custom")
        // Switch to FXHome and check label
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.nowAt(HomeSettings)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.tables.cells["Home"])
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Firefox Home")
    }

    // Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        mozWaitForElementToExist(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
        let numberOfTopSites = app
            .links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            .collectionViews
            .cells
            .count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307033
    func testJumpBackIn() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
        waitForElementsToExist(
            [
                app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn],
                app.otherElements
                    .cells[AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell]
                    .staticTexts[urlExampleLabel]]
        )
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn].waitAndTap()
        // Tab tray is open with recently open tab
        mozWaitForElementToExist(app.otherElements.cells[urlExampleLabel])
        app.buttons["Done"].waitAndTap()
        // Validation for when Jump In section is not displayed
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        app.tables.cells.switches["Jump Back In"].waitAndTap()
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307034
    func testRecentlySaved() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "apple-summarizer-feature")
        addLaunchArgument(jsonFileName: "defaultEnabledOff", featureName: "hosted-summarizer-feature")
        app.launch()
        // Preconditons: Create 6 bookmarks & add 1 items to reading list
        navigator.nowAt(BrowserTab)
        bookmarkPages()
        // iOS 15 does not have the Reader View button available (when experiment Off)
        if #available(iOS 16, *) {
            addContentToReaderView(isHomePageOn: false)
            if iPad() {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
                app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
            } else {
                navigator.performAction(Action.GoToHomePage)
                app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
            }
            mozWaitForElementToExist(app.staticTexts["Bookmarks"])
            navigator.nowAt(NewTabScreen)
            navigator.performAction(Action.ToggleRecentlySaved)
            navigator.nowAt(HomeSettings)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            navigator.nowAt(NewTabScreen)
            navigator.performAction(Action.ToggleRecentlySaved)
            navigator.nowAt(HomeSettings)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            checkBookmarks()
            app.scrollViews
                .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell]
                .staticTexts[urlExampleLabel].waitAndTap()
            navigator.nowAt(BrowserTab)
            waitForTabsButton()
            unbookmark(url: urlLabelExample_3)
            removeContentFromReaderView()
            navigator.nowAt(LibraryPanel_ReadingList)
            navigator.performAction(Action.CloseReadingListPanel)
            navigator.nowAt(BrowserTab)
            navigator.performAction(Action.OpenNewTabFromTabTray)
            checkBookmarksUpdated()
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306871
    // Smoketest
    func testCustomizeHomepage() {
        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        if !iPad() {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"])
            app.collectionViews["FxCollectionView"].swipeUp()
            app.collectionViews["FxCollectionView"].swipeUp()
            mozWaitForElementToExist(
                app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage]
            )
        }
        app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage].waitAndTap()
        // Verify default settings
        waitForElementsToExist(
            [
            app.navigationBars[AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar],
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.always],
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.disabled]
            ]
        )
        mozWaitForElementToExist(
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.afterFourHours]
        )
        // Commented due to experimental features
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.jumpBackIn].value as! String,
//            "1"
//        )
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentlySaved].value as! String,
//            "1"
//        )

        if #available(iOS 17, *) {
            XCTAssertEqual(
                app.cells.switches["Stories"].value as? String,
                "1"
            )
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306871
    // Smoketest TAE
    func testCustomizeHomepage_TAE() {
        let fxHomePageScreen = FirefoxHomePageScreen(app: app)
        let homePageScreen = HomePageScreen(app: app)
        let settingHomePageScreen = SettingsHomepageScreen(app: app)

        addLaunchArgument(jsonFileName: "homepageRedesignOff", featureName: "homepage-redesign-feature")
        app.launch()
        homePageScreen.swipeToCustomizeHomeOption()
        fxHomePageScreen.tapOnCustomizeHomePageOption(timeout: TIMEOUT)
        // Verify default settings
        settingHomePageScreen.assertDefaultOptionsVisible()
        // Commented due to experimental features
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.jumpBackIn].value as! String,
//            "1"
//        )
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentlySaved].value as! String,
//            "1"
//        )

        settingHomePageScreen.assertStoriesSwitch(isOn: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307032
    func testShortcutsRows() {
        app.launch()
        addWebsitesToShortcut(website: path(forTestPage: url_1))
        addWebsitesToShortcut(website: path(forTestPage: url_2["url"]!))
        addWebsitesToShortcut(website: path(forTestPage: url_3))
        addWebsitesToShortcut(website: "www.euronews.com")
        addWebsitesToShortcut(website: "www.walmart.com")
        addWebsitesToShortcut(website: "www.bestbuy.com")
        addWebsitesToShortcut(website: "www.instagram.com")
        if !iPad() {
            validateNumberOfTopSitesDisplayed(row: 0, minBoundary: 1, maxBoundary: 5)
            validateNumberOfTopSitesDisplayed(row: 1, minBoundary: 4, maxBoundary: 9)
        } else {
            validateNumberOfTopSitesDisplayed(row: 0, minBoundary: 1, maxBoundary: 8)
            validateNumberOfTopSitesDisplayed(row: 1, minBoundary: 7, maxBoundary: 15)
        }
    }

    private func validateNumberOfTopSitesDisplayed(row: Int, minBoundary: Int, maxBoundary: Int) {
        navigator.goto(HomeSettings)
        app.cells[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage].waitAndTap()
        app.staticTexts["Rows"].waitAndTap()
        let expectedRowValues = ["1", "2"]
        for i in 0...1 {
            XCTAssertEqual(app.tables.cells.element(boundBy: i).label, expectedRowValues[i])
        }
        app.tables.cells.element(boundBy: row).waitAndTap()
        app.buttons["Shortcuts"].waitAndTap()
        navigator.goto(NewTabScreen)
        app.buttons["Done"].waitAndTap()
        mozWaitForElementToExist(app.links["TopSitesCell"])
        let totalTopSites = app.links.matching(identifier: "TopSitesCell").count
        XCTAssertTrue(totalTopSites > minBoundary)
        XCTAssertTrue(totalTopSites < maxBoundary)
    }

    private func addWebsitesToShortcut(website: String) {
        navigator.openURL(website)
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        // Tap on Save item
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
    }
}
