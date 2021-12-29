// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = "test-example.html"

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
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + prefilledTopSites, LaunchArguments.SkipContextualHintJumpBackIn]
        }
        super.setUp()
    }
    func testCheckHomeSettingsByDefault() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        XCTAssertTrue(app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(app.tables.cells["HomeAsCustomURL"].exists)
        waitForExistence(app.tables.cells["TopSitesRows"])
        XCTAssertEqual(app.tables.cells["TopSitesRows"].label as String, "Shortcuts, Rows: 2")
        XCTAssertTrue(app.cells.switches["Recommended by Pocket"].exists)
    }

    func testTyping() {
        navigator.performAction(Action.CloseURLBarOpen)
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

        //Now check open home page should load the previously saved home page
        let homePageMenuItem = app.buttons["TabToolbar.homeButton"]
        waitForExistence(homePageMenuItem, timeout: 5)
        homePageMenuItem.tap()
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "example")
    }

    func testClipboard() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        app.textFields["HomeAsCustomURLTextField"].tap()
        app.textFields["HomeAsCustomURLTextField"].press(forDuration: 3)
        waitForExistence(app.menuItems["Paste"])
        app.menuItems["Paste"].tap()
        waitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correclty copied into the correct field
        let value = app.textFields["HomeAsCustomURLTextField"].value as! String
        XCTAssertEqual(value, websiteUrl1)
    }

    func testSetFirefoxHomeAsHome() {
        // Start by setting to History since FF Home is default
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        enterWebPageAsHomepage(text: websiteUrl1)
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        navigator.goto(BrowserTab)
        waitUntilPageLoad()
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.textFields["url"], timeout: 3)

        // Now after setting History, make sure FF home is set
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.performAction(Action.GoToHomePage)
        waitForExistence(app.collectionViews.cells["TopSitesCell"])
    }

    func testSetCustomURLAsHome() {
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Open a new tab and tap on Home option
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)

        // Workaroud needed after xcode 11.3 update Issue 5937
        // Lets check only that website is open
        waitForExistence(app.textFields["url"], timeout: 5)
        waitForValueContains(app.textFields["url"], value: "mozilla")
    }
    
    func testTopSitesCustomNumberOfRows() {
        navigator.performAction(Action.CloseURLBarOpen)
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        var topSitesPerRow:Int
        //Ensure testing in portrait mode
        XCUIDevice.shared.orientation = .portrait
        //Run test for both iPhone and iPad devices as behavior differs between the two
        if iPad() {
            // On iPad, 6 top sites per row are displayed
            topSitesPerRow = 8
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                navigator.goto(HomeSettings)
                app.tables.cells.element(boundBy: 3).tap()
                app.tables.cells.element(boundBy: n-1).tap()
                navigator.goto(SettingsScreen)
                app.buttons["Settings"].tap()
                navigator.goto(NewTabScreen)
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        } else {
            // On iPhone, 4 top sites per row are displayed
            topSitesPerRow = 4
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                navigator.performAction(Action.SelectTopSitesRows)
                XCTAssertEqual(app.tables.cells["TopSitesRows"].label as String, "Shortcuts, Rows: " + String(n))
                navigator.performAction(Action.GoToHomePage)
                navigator.performAction(Action.CloseURLBarOpen)
                navigator.nowAt(NewTabScreen)
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        }
    }
    
    func testChangeHomeSettingsLabel() {
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        //Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectHomeAsCustomURL)
        navigator.nowAt(HomeSettings)
        //Enter a custom URL
        enterWebPageAsHomepage(text: websiteUrl1)
        waitForValueContains(app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Homepage")
        //Switch to FXHome and check label
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.nowAt(HomeSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(app.tables.cells["Home"].label, "Homepage, Firefox Home")
    }
    //Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        waitForExistence(app.cells["TopSitesCell"])
        XCTAssertTrue(app.cells["TopSitesCell"].exists)
        let numberOfTopSites = app.cells["TopSitesCell"].collectionViews.cells.count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }

    func testJumpBackIn() throws {
        throw XCTSkip("Disabled failing in BR - investigating") 
        navigator.openURL(path(forTestPage: exampleUrl))
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(NewTabScreen)
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        waitForExistence(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn], timeout: 5)
        // Swipe up needed to see the content below the Jump Back In section
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn].swipeUp()
        XCTAssertTrue(app.cells.collectionViews.staticTexts["Example Domain"].exists)
        // Swipe down to be able to click on Show all option
        app.buttons["More"].swipeDown()
        waitForExistence(app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn], timeout: 5)
        app.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.jumpBackIn].tap()
        // Tab tray is open with recently open tab
        waitForExistence(app.cells.staticTexts["Example Domain"], timeout: 3)
    }

    func testCustomizeHomepage() {
        if !iPad() {
            navigator.performAction(Action.CloseURLBarOpen)
            app.cells.otherElements["Bookmarks"].swipeUp()
            waitForExistence(app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage])
        }
        app.cells.otherElements.buttons[AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.customizeHomePage].tap()
        // Verify default settings
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar], timeout: 3)
        XCTAssertTrue(app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.always].exists)
        XCTAssertTrue(app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.disabled].exists)
        XCTAssertTrue(app.tables.cells[AccessibilityIdentifiers.Settings.Homepage.StartAtHome.afterFourHours].exists)
        // Commented due to experimental features
        // XCTAssertEqual(app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.jumpBackIn].value as! String, "1")
        // XCTAssertEqual(app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentlySaved].value as! String, "1")
        XCTAssertEqual(app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recentSearches].value as! String, "0")
        XCTAssertEqual(app.cells.switches[AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.recommendedByPocket].value as! String, "1")
    }
}
