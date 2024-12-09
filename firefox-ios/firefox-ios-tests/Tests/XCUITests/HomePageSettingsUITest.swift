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
        let jumpBackIn = app.tables.cells.switches["Jump Back In"].value
        XCTAssertEqual("1", jumpBackIn as? String)
        let bookmarks = app.tables.cells.switches["Bookmarks"].value
        XCTAssertEqual("1", bookmarks as? String)
        // FXIOS-8107: Commented out as history highlights has been disabled to fix app hangs / slowness
        // Reloads for notification
        // let recentlyVisited = app.tables.cells.switches["Recently Visited"].value
        // XCTAssertEqual("1", recentlyVisited as? String)
        let sponsoredStories = app.tables.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].value
        XCTAssertEqual("1", sponsoredStories as? String)

        // Current Homepage
        XCTAssertTrue(app.tables.cells["Firefox Home"].isSelected)
        mozWaitForElementToExist(app.tables.cells["HomeAsCustomURL"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339257
    func testTyping() {
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
        let homePageMenuItem = app.buttons[AccessibilityIdentifiers.Toolbar.homeButton]
        homePageMenuItem.waitAndTap()
        waitUntilPageLoad()
        // Issue found - https://mozilla-hub.atlassian.net/browse/FXIOS-10753
        // Workaround - the test will start to fail once the issue is fixed
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "Search or enter address")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339258
    func testClipboard() {
        navigator.nowAt(NewTabScreen)
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomeAsCustomURLTextField"].tap()
        if #unavailable(iOS 16) {
            sleep(2)
        }
        let textField = app.textFields["HomeAsCustomURLTextField"]
        textField.press(forDuration: 3)
        let pasteOption = app.menuItems["Paste"]
        var nrOfTaps = 3
        while !pasteOption.exists && nrOfTaps > 0 {
            textField.press(forDuration: 3)
            nrOfTaps -= 1
        }
        app.menuItems["Paste"].waitAndTap()
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correctly copied into the correct field
        mozWaitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: websiteUrl1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339260
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
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.UrlBar.url])

        // Now after setting History, make sure FF home is set
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.performAction(Action.GoToHomePage)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307031
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
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.GoToHomePage)

        // Issue found - https://mozilla-hub.atlassian.net/browse/FXIOS-10753
        // Workaround - the test will start to fail once the issue is fixed
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField])
        mozWaitForValueContains(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField],
                                value: "Search or enter address")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2339489
    func testDisableTopSitesSettingsRemovesSection() {
        mozWaitForElementToExist(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton]
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

    // https://mozilla.testrail.io/index.php?/cases/view/2339491
    func testChangeHomeSettingsLabel() {
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
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell])
        XCTAssertTrue(app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].exists)
        let numberOfTopSites = app
            .cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
            .collectionViews
            .cells
            .count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307033
    func testJumpBackIn() {
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
            navigator.performAction(Action.CloseURLBarOpen)
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
        if !iPad() {
            mozWaitForElementToExist(
                app.otherElements
                    .cells[AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell]
                    .staticTexts[urlExampleLabel])
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

    // https://mozilla.testrail.io/index.php?/cases/view/2307034
    func testRecentlySaved() {
        // Preconditons: Create 6 bookmarks & add 1 items to reading list
        bookmarkPages()
        addContentToReaderView()
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        } else {
            navigator.performAction(Action.GoToHomePage)
        }
        mozWaitForElementToExist(app.staticTexts["Bookmarks"])
        navigator.performAction(Action.ToggleRecentlySaved)
        if !iPad() {
            navigator.performAction(Action.ClickSearchButton)
            mozWaitForElementToNotExist(
                app.scrollViews.cells[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks]
            )
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
            navigator.performAction(Action.CloseURLBarOpen)
        } else {
            navigator.nowAt(HomeSettings)
            navigator.performAction(Action.OpenNewTabFromTabTray)
        }
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.ToggleRecentlySaved)
        navigator.nowAt(HomeSettings)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if !iPad() {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton])
            navigator.performAction(Action.CloseURLBarOpen)
        }
        checkBookmarks()
        app.scrollViews
            .cells[AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell]
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
        checkBookmarksUpdated()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306923
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
//            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton], timeout: 3)
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306871
    // Smoketest
    func testCustomizeHomepage() {
        if !iPad() {
            mozWaitForElementToExist(app.collectionViews["FxCollectionView"])
            app.collectionViews["FxCollectionView"].swipeUp()
            app.collectionViews["FxCollectionView"].swipeUp()
            mozWaitForElementToExist(
                app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage]
            )
        }
        app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage].tap()
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

        // FXIOS-8107: Commented out as history highlights has been disabled to fix app hangs / slowness
        // Reloads for notification
//        XCTAssertEqual(
//            app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentVisited].value as! String,
//            "1"
//        )
        XCTAssertEqual(
            app.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].value as? String,
            "1"
        )
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307032
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
        app.staticTexts["Rows"].waitAndTap()
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
        app.tables.otherElements[StandardImageIdentifiers.Large.pin].waitAndTap()
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
    }
}
