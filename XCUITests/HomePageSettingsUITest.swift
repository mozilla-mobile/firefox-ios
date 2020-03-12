/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let websiteUrl1 = "www.mozilla.org"
let websiteUrl2 = "developer.mozilla.org"
let invalidUrl = "1-2-3"
let exampleUrl = "test-example.html"

class HomePageSettingsUITests: BaseTestCase {
    private func enterWebPageAsHomepage(text: String) {
        Base.app.textFields["HomeAsCustomURLTextField"].tap()
        Base.app.textFields["HomeAsCustomURLTextField"].typeText(text)
        let value = Base.app.textFields["HomeAsCustomURLTextField"].value
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
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + prefilledTopSites]
        }
        super.setUp()
    }
    func testCheckHomeSettingsByDefault() {
        navigator.goto(HomeSettings)
        XCTAssertTrue(Base.app.tables.cells["Firefox Home"].exists)
        XCTAssertTrue(Base.app.tables.cells["HomeAsCustomURL"].exists)
        Base.helper.waitForExistence(Base.app.tables.cells["TopSitesRows"])
        XCTAssertEqual(Base.app.tables.cells["TopSitesRows"].label as String, "Top Sites, Rows: 2")
        XCTAssertTrue(Base.app.tables.switches["ASPocketStoriesVisible"].isEnabled)
    }

    func testTyping() {
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: "example.com")

        // Check if it is saved going back and then again to home settings menu
        navigator.goto(SettingsScreen)
        navigator.goto(HomeSettings)
        let valueAfter = Base.app.textFields["HomeAsCustomURLTextField"].value
        XCTAssertEqual(valueAfter as? String, "http://example.com")

        // Check that it is actually set by opening a different website and going to Home
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        navigator.goto(BrowserTabMenu)

        //Now check open home page should load the previously saved home page
        let homePageMenuItem = Base.app.cells["menu-Home"]
        Base.helper.waitForExistence(homePageMenuItem)
        homePageMenuItem.tap()
        Base.helper.waitForValueContains(Base.app.textFields["url"], value: "example")
    }

    /* Test disabled until bug 1510243 is fixed
    func testTypingBadURL() {
        Base.helper.waitForExistence(Base.app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(HomeSettings)
        // Enter an invalid Url
        enterWebPageAsHomepage(text: invalidUrl)
        navigator.goto(SettingsScreen)
        // Check that it is not saved
        navigator.goto(HomeSettings)
        Base.helper.waitForExistence(Base.app.textFields["HomePageSettingTextField"])
        let valueAfter = Base.app.textFields["HomePageSettingTextField"].value
        XCTAssertEqual("Enter a webpage", valueAfter as! String)

        // There is no option to go to Home, instead the website open has the option to be set as HomePageSettings
        navigator.openURL(Base.helper.path(forTestPage: "test-mozilla-org.html"))
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["TabToolbar.menuButton"], timeout: 5)
        navigator.goto(BrowserTabMenu)
        let homePageMenuItem = Base.app.tables["Context Menu"].cells["Open Homepage"]
        XCTAssertFalse(homePageMenuItem.exists)
    }*/

    func testClipboard() {
        // Check that what's in clipboard is copied
        UIPasteboard.general.string = websiteUrl1
        navigator.goto(HomeSettings)
        Base.app.textFields["HomeAsCustomURLTextField"].tap()
        Base.app.textFields["HomeAsCustomURLTextField"].press(forDuration: 3)
        print(Base.app.debugDescription)
        Base.helper.waitForExistence(Base.app.menuItems["Paste"])
        Base.app.menuItems["Paste"].tap()
        Base.helper.waitForValueContains(Base.app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        // Check that the webpage has been correclty copied into the correct field
        let value = Base.app.textFields["HomeAsCustomURLTextField"].value as! String
        XCTAssertEqual(value, websiteUrl1)
    }

    // Test disabled until bug 1510243 is fixed/clarified
    /*
    func testDisabledClipboard() {
        // Type an incorrect URL and copy it
        navigator.goto(URLBarOpen)
        Base.app.textFields["address"].typeText(invalidUrl)
        Base.app.textFields["address"].press(forDuration: 5)
        Base.app.menuItems["Select All"].tap()
        Base.app.menuItems["Copy"].tap()
        Base.helper.waitForExistence(Base.app.buttons["goBack"])
        Base.app.buttons["goBack"].tap()

        // Go to HomePage settings and check that it is not possible to copy it into the set webpage field
        navigator.nowAt(BrowserTab)
        navigator.goto(HomeSettings)
        Base.helper.waitForExistence(Base.app.staticTexts["Use Copied Link"])

        // Check that nothing is copied in the Set webpage field
        Base.app.cells["Use Copied Link"].tap()
        let value = Base.app.textFields["HomePageSettingTextField"].value

        XCTAssertEqual("Enter a webpage", value as! String)
    }*/
    
    // Disabled due to xcode 11.3 udpate Issue 5937
    /*
    func testSetFirefoxHomeAsHome() {
        // Start by setting to History since FF Home is default
        navigator.goto(HomeSettings)
        enterWebPageAsHomepage(text: websiteUrl1)
        navigator.performAction(Action.GoToHomePage)
        Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 3)

        // Now after setting History, make sure FF home is set
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabSettings)
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.performAction(Action.GoToHomePage)
        Base.helper.waitForExistence(Base.app.collectionViews.cells["TopSitesCell"])
    }*/

    func testSetCustomURLAsHome() {
        navigator.goto(HomeSettings)
        // Enter a webpage
        enterWebPageAsHomepage(text: websiteUrl1)

        // Open a new tab and tap on Home option
        navigator.performAction(Action.OpenNewTabFromTabTray)
        Base.helper.waitForTabsButton()
        navigator.performAction(Action.GoToHomePage)

        // Workaroud needed after xcode 11.3 update Issue 5937
        // Lets check only that website is open
        // Base.helper.waitForExistence(Base.app.textFields["url"], timeout: 5)
        // Base.helper.waitForValueContains(Base.app.textFields["url"], value: "mozilla")
    }
    
    func testTopSitesCustomNumberOfRows() {
        var topSitesPerRow:Int
        //Ensure testing in portrait mode
        XCUIDevice.shared.orientation = .portrait
        //Run test for both iPhone and iPad devices as behavior differs between the two
        if Base.helper.iPad() {
            // On iPad, 6 top sites per row are displayed
            topSitesPerRow = 6
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                // Workaround for new Xcode11/iOS13
                navigator.goto(HomeSettings)
                Base.app.tables.cells.element(boundBy: 2).tap()
                Base.helper.waitForExistence(Base.app.cells.staticTexts["1"], timeout: 3)
                Base.app.tables.cells.element(boundBy: n-1).tap()
                navigator.goto(NewTabScreen)
                Base.app.buttons["Done"].tap()
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        } else {
            // On iPhone, 4 top sites per row are displayed
            topSitesPerRow = 4
            //Test each of the custom row options from 1-4
            for n in 1...4 {
                userState.numTopSitesRows = n
                navigator.performAction(Action.SelectTopSitesRows)
                XCTAssertEqual(Base.app.tables.cells["TopSitesRows"].label as String, "Top Sites, Rows: " + String(n))
                navigator.performAction(Action.GoToHomePage)
                checkNumberOfExpectedTopSites(numberOfExpectedTopSites: (n * topSitesPerRow))
            }
        }
    }
    
    func testChangeHomeSettingsLabel() {
        //Go to New Tab settings and select Custom URL option
        navigator.performAction(Action.SelectHomeAsCustomURL)
        navigator.nowAt(HomeSettings)
        //Enter a custom URL
        enterWebPageAsHomepage(text: websiteUrl1)
        Base.helper.waitForValueContains(Base.app.textFields["HomeAsCustomURLTextField"], value: "mozilla")
        navigator.goto(SettingsScreen)
        //Assert that the label showing up in Settings is equal to the URL entere (NOT CURRENTLY WORKING, SHOWING HOMEPAGE INSTEAD OF URL)
        XCTAssertEqual(Base.app.tables.cells["Home"].label, "Home, Homepage")
        //Switch to FXHome and check label
        navigator.performAction(Action.SelectHomeAsFirefoxHomePage)
        navigator.nowAt(HomeSettings)
        navigator.goto(SettingsScreen)
        XCTAssertEqual(Base.app.tables.cells["Home"].label, "Home, Firefox Home")
    }
    //Function to check the number of top sites shown given a selected number of rows
    private func checkNumberOfExpectedTopSites(numberOfExpectedTopSites: Int) {
        Base.helper.waitForExistence(Base.app.cells["TopSitesCell"])
        XCTAssertTrue(Base.app.cells["TopSitesCell"].exists)
        let numberOfTopSites = Base.app.collectionViews.cells["TopSitesCell"].cells.matching(identifier: "TopSite").count
        XCTAssertEqual(numberOfTopSites, numberOfExpectedTopSites)
    }
}
