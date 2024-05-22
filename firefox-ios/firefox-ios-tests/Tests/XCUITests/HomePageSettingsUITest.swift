// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = "test-example.html"
let urlExampleLabel = "Example Domain"
let urlMozillaLabel = "Internet for people, not profit — Mozilla (US)"

class HomePageSettingsUITests: BaseTestCase {
    private func enterWebPageAsHomepage(text: String) {
        app.textFields["HomeAsCustomURLTextField"].tap()
        app.textFields["HomeAsCustomURLTextField"].typeText(text)
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

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339256
    func testCheckHomeSettingsByDefault() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)

        mozWaitForElementToExist(app.navigationBars["Homepage"])
        mozWaitForElementToExist(app.tables.otherElements["OPENING SCREEN"])
        mozWaitForElementToExist(app.tables.otherElements["INCLUDE ON HOMEPAGE"])
        mozWaitForElementToExist(app.tables.otherElements["CURRENT HOMEPAGE"])

        // Opening Screen
        XCTAssertFalse(app.tables.cells["StartAtHomeAlways"].isSelected)
        XCTAssertFalse(app.tables.cells["StartAtHomeDisabled"].isSelected)
        XCTAssertTrue(app.tables.cells["StartAtHomeAfterFourHours"].isSelected)

        // Include on Homepage
        XCTAssertTrue(app.tables.cells["TopSitesSettings"].staticTexts["On"].exists)
        let jumpBackIn = app.tables.cells.switches["Jump Back In"].value
        XCTAssertEqual("1", jumpBackIn as? String)
        let recentlySaved = app.tables.cells.switches["Recently Saved"].value
        XCTAssertEqual("1", recentlySaved as? String)
        // FXIOS-8107: Commented out as history highlights has been disabled to fix app hangs / slowness
        // Reloads for notification
        // let recentlyVisited = app.tables.cells.switches["Recently Visited"].value
        // XCTAssertEqual("1", recentlyVisited as? String)
        let sponsoredStories = app.tables.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].value
        XCTAssertEqual("1", sponsoredStories as? String)

        // Current Homepage
        XCTAssertTrue(app.tables.cells["Firefox Home"].isSelected)
        XCTAssertTrue(app.tables.cells["HomeAsCustomURL"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339257
    func testTyping() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: "example.com")

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(SettingsScreen)
        navigator.goto(HomeSettings)
        let valueAfter = app.textFields["HomeAsCustomURLTextField"].value
        XCTAssertEqual(valueAfter as? String, "http://example.com")

        // Check that it is actually set by opening a different website and going to Home
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()

        // Now check open home page should load the previously saved home page
        let homePageMenuItem = app.buttons[AccessibilityIdentifiers.Toolbar.homeButton]
        mozWaitForElementToExist(homePageMenuItem, timeout: TIMEOUT)
        homePageMenuItem.tap()
        waitUntilPageLoad()
        mozWaitForValueContains(app.textFields["url"], value: "example")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339258
    func testClipboard() {
        navigator.nowAt(NewTabScreen)
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomeAsCustomURLTextField"].tap()
        app.textFields["HomeAsCustomURLTextField"].press(forDuration: 3)
        mozWaitForElementToExist(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correctly copied into the correct field
        let value = app.textFields["HomeAsCustomURLTextField"].value as! String
        XCTAssertEqual(value, websiteUrl1)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339260
    func testSetFirefoxHomeAsHome() {
        // Start by setting to History since FF Home is default
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        enterWebPageAsHomepage(text: websiteUrl1)
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.textFields["url"], timeout: TIMEOUT)

        // Now after setting History, make sure FF home is set
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307031
    func testSetCustomURLAsHome() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Open a new tab and tap on Home option
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)

        // Workaround needed after Xcode 11.3 update Issue 5937
        // Lets check only that website is open
        mozWaitForElementToExist(app.textFields["url"], timeout: TIMEOUT)
        mozWaitForValueContains(app.textFields["url"], value: "mozilla")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339489
    func testDisableTopSitesSettingsRemovesSection() {
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton],
            timeout: TIMEOUT
        )
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        app.staticTexts["Shortcuts"].tap()
        XCTAssertTrue(app.switches["Shortcuts"].exists)
        app.switches["Shortcuts"].tap()

        navigator.goto(NewTabScreen)
        app.buttons["Done"].tap()

        mozWaitForElementToNotExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        mozWaitForElementToNotExist(app.collectionViews.cells.staticTexts["YouTube"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2339491
    func testChangeHomeSettingsLabel() {
        // Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectHomeAsCustomURL)
        navigator.nowAt(HomeSettings)
        // Enter a custom URL
        enterWebPageAsHomepage(text: websiteUrl1)
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Custom")
        // Switch to FXHome and check label
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.nowAt(HomeSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Firefox Home")
    }

    // Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
        let numberOfTopSites = app
            .cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            .collectionViews
            .cells
            .count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307033
    func testJumpBackIn() {
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 5)
            navigator.performAction(Action.CloseURLBarOpen)
        }
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn],
            timeout: 5
        )
        XCTAssertTrue(
            app.otherElements
                .cells[AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell]
                .staticTexts[urlExampleLabel].exists
        )
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn],
            timeout: 5
        )
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn].tap()
        // Tab tray is open with recently open tab
        if !iPad() {
            mozWaitForElementToExist(
                app.otherElements
                    .cells[AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell]
                    .staticTexts[urlExampleLabel],
                timeout: 3)
        } else {
            mozWaitForElementToExist(app.otherElements.cells[urlExampleLabel])
        }
        app.buttons["Done"].tap()
        // Validation for when Jump In section is not displayed
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        app.tables.cells.switches["Jump Back In"].tap()
        app.buttons["Done"].tap()
        navigator.nowAt(NewTabScreen)
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307034
    func testRecentlySaved() {
        // Preconditons: Create 6 bookmarks & add 1 items to reading list
        bookmarkPages()
        addContentToReaderView()
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.staticTexts["Recently Saved"])
        navigator.performAction(Action.ToggleRecentlySaved)
        // On iPad we have the homepage button always present,
        // on iPhone we have the search button instead when we're on a new tab page
        navigator.performAction(Action.ClickSearchButton)
        XCTAssertFalse(
            app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.recentlySaved].exists
        )
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 3)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.ToggleRecentlySaved)
        navigator.nowAt(HomeSettings)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 3)
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkRecentlySaved()
        app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.RecentlySaved.itemCell]
            .staticTexts[urlExampleLabel].tap()
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        unbookmark()
        if !iPad() {
            navigator.performAction(Action.CloseTab)
        }
        removeContentFromReaderView()
        navigator.nowAt(LibraryPanel_ReadingList)
        navigator.performAction(Action.CloseReadingListPanel)
        navigator.goto(NewTabScreen)
        checkRecentlySavedUpdated()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306923
    // Smoketest
    // FXIOS-8107: Disabled test as history highlights has been disabled to fix app hangs / slowness
    // Reloads for notification
//    func testRecentlyVisited() {
//        navigator.openURL(websiteUrl1)
//        waitUntilPageLoad()
//        navigator.performAction(Action.GoToHomePage)
//        mozWaitForElementToExist(
//            app.scrollViews
//                .cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell]
//                .staticTexts[urlMozillaLabel]
//        )
//        navigator.goto(HomeSettings)
//        navigator.performAction(Action.ToggleRecentlyVisited)
//
//        // On iPad we have the homepage button always present,
//        // on iPhone we have the search button instead when we're on a new tab page
//        if !iPad() {
//            navigator.performAction(Action.ClickSearchButton)
//        } else {
//            navigator.performAction(Action.GoToHomePage)
//        }
//
//        XCTAssertFalse(
//            app.scrollViews
//                .cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell]
//                .staticTexts[urlMozillaLabel].exists
//        )
//        if !iPad() {
//            mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 3)
//            navigator.performAction(Action.CloseURLBarOpen)
//        }
//        navigator.nowAt(NewTabScreen)
//        navigator.goto(HomeSettings)
//        navigator.performAction(Action.ToggleRecentlyVisited)
//        navigator.nowAt(HomeSettings)
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        XCTAssert(
//            app.scrollViews
//                .cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell]
//                .staticTexts[urlMozillaLabel].exists
//        )

        // swiftlint:disable line_length
//        Disabled due to https://github.com/mozilla-mobile/firefox-ios/issues/11271
//        navigator.openURL("mozilla ")
//        navigator.openURL(websiteUrl2)
//        navigator.performAction(Action.GoToHomePage)
//        XCTAssert(app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell].staticTexts["Mozilla , Pages: 2"].exists)
//        app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell].staticTexts["Mozilla , Pages: 2"].staticTexts["Mozilla , Pages: 2"].press(forDuration: 1.5)
//        selectOptionFromContextMenu(option: "Remove")
//        XCTAssertFalse(app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell].staticTexts["Mozilla , Pages: 2"].exists)
        // swiftlint:enable line_length
//    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306871
    // Smoketest
    func testCustomizeHomepage() {
        if !iPad() {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"], timeout: TIMEOUT)
            app.collectionViews["FxCollectionView"].swipeUp()
            app.collectionViews["FxCollectionView"].swipeUp()
            mozWaitForElementToExist(
                app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage],
                timeout: TIMEOUT
            )
        }
        app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage].tap()
        // Verify default settings
        mozWaitForElementToExist(
            app.navigationBars[AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar],
            timeout: TIMEOUT_LONG
        )
        XCTAssertTrue(
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.always].exists
        )
        XCTAssertTrue(
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.disabled].exists
        )
        XCTAssertTrue(
            app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.afterFourHours].exists
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

        // FXIOS-8107: Commented out as history highlights has been disabled to fix app hangs / slowness
        // Reloads for notification
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentVisited].value as! String,
//            "1"
//        )
        XCTAssertEqual(
            app.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].value as! String,
            "1"
        )
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2307032
    func testShortcutsRows() {
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
            validateNumberOfTopSitesDisplayed(row: 2, minBoundary: 8, maxBoundary: 13)
            validateNumberOfTopSitesDisplayed(row: 3, minBoundary: 12, maxBoundary: 17)
        } else {
            validateNumberOfTopSitesDisplayed(row: 0, minBoundary: 1, maxBoundary: 8)
            validateNumberOfTopSitesDisplayed(row: 1, minBoundary: 7, maxBoundary: 15)
        }
    }

    private func validateNumberOfTopSitesDisplayed(row: Int, minBoundary: Int, maxBoundary: Int) {
        navigator.goto(HomeSettings)
        app.staticTexts["Shortcuts"].tap()
        mozWaitForElementToExist(app.staticTexts["Rows"])
        app.staticTexts["Rows"].tap()
        let expectedRowValues = ["1", "2", "3", "4"]
        for i in 0...3 {
            XCTAssertEqual(app.tables.cells.element(boundBy: i).label, expectedRowValues[i])
        }
        app.tables.cells.element(boundBy: row).tap()
        app.buttons["Shortcuts"].tap()
        navigator.goto(NewTabScreen)
        app.buttons["Done"].tap()
        mozWaitForElementToExist(app.cells["TopSitesCell"])
        let totalTopSites = app.cells.matching(identifier: "TopSitesCell").count
        XCTAssertTrue(totalTopSites > minBoundary)
        XCTAssertTrue(totalTopSites < maxBoundary)
    }

    private func addWebsitesToShortcut(website: String) {
        navigator.goto(NewTabScreen)
        navigator.openURL(website)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables.otherElements[StandardImageIdentifiers.Large.pin])
        app.tables.otherElements[StandardImageIdentifiers.Large.pin].tap()
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
    }
}
