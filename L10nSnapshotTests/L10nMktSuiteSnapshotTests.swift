// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

/* Disabled by default, running locally to get these specific screenshots in specific locales
import XCTest

class L10nMktSuiteSnapshotTests: L10nBaseSnapshotTests {

    override func setUp() {
        args = [LaunchArguments.ClearProfile, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.SkipIntro, LaunchArguments.ChronTabs]

        super.setUp()
    }
    func test1SettingsETP() {
        waitForExistence(app.buttons["urlBar-cancel"])
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(TrackingProtectionSettings)
        
       // Check the warning alert
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()
        app.alerts.buttons.firstMatch.tap()
        sleep(3)
        snapshot("TrackingProtectionStrictWarning-01")
        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListBasic"])
    }
    
    func testAwesemoBarWithResults() {
        navigator.openURL("firefox.com")
        sleep(2)
        waitUntilPageLoad()
        
        navigator.openNewURL(urlString: "mozilla.com")
        sleep(2)
        
        userState.url = "firefox"
        navigator.performAction(Action.SetURLByTyping)
        snapshot("Awesomebar-results-firefox")
    }

    // DarkMode for these tests
    func test3DefaultTopSites() {
        waitForExistence(app.buttons["urlBar-cancel"])
        app.buttons["urlBar-cancel"].tap()
        // Enable Dark Mode
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        app.switches["SystemThemeSwitchValue"].tap()
    
        app.cells.staticTexts.element(boundBy: 6).tap()
        navigator.goto(HomePanelsScreen)
        snapshot("DefaultTopSites-01")
    }
    // This test has to run with regular tab tray not chron tabs
    // For that set that pref to 0 adding:
    // Client/Application/TestAppDelegate.swift
    /* if launchArguments.contains(LaunchArguments.ChronTabs) {
        profile.prefs.setInt(0, forKey: PrefsKeys.ChronTabsPrefKey)
    }*/
    func test4PrivateBrowsingTabsEmptyState() {
        waitForExistence(app.buttons["urlBar-cancel"])
        app.buttons["urlBar-cancel"].tap()
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        snapshot("PrivateBrowsingMode")
    }
    
    func test5DefaultSearchEngine() {
        waitForExistence(app.buttons["urlBar-cancel"])
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(SearchSettings)
        XCTAssert(app.tables.staticTexts["Google"].exists)
        snapshot("SearchSuggestions")
        
        // Disable Dark Mode
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        app.switches["SystemThemeSwitchValue"].tap()
    }
    
    func testSearchWidgets2() {
        // Set a url in the pasteboard
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        navigator.openURL("pocket.com")
        waitUntilPageLoad()
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.openNewURL(urlString: "mozilla.org")
        waitUntilPageLoad()
        navigator.performAction(Action.PinToTopSitesPAM)
        
        setupSnapshot(springboard)
        // Open the app and set it to background
        app.activate()
        sleep(1)
        XCUIDevice.shared.press(.home)
        
        // Swipe Right to go to Widgets view
        let window = springboard.children(matching: .window).element(boundBy: 0)
        window.swipeRight()
        window.swipeRight()
        // Swipe Up to get to the Edit and Add Widget buttons
        // This line is needed the first time widgets view is open
        springboard.alerts.firstMatch.scrollViews.otherElements.buttons.element(boundBy: 0).tap()
        
        let element = springboard/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"]",".scrollViews[\"left-of-home-scroll-view\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
            element.swipeUp()
            element.swipeUp()
            element.swipeUp()
            springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()

        sleep(1)
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()

        // Select Fennec (username)
        springboard.collectionViews.cells["Fennec (synctesting)"].children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.tap()
        // Tap on Add widget button
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()
            
        // Wait for the Search in Firefox widget and tap on it
        sleep(1)
        snapshot("Widget-01")
        // Tap on Edit and then on Add to Widget
        springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()
        
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()

        springboard.collectionViews.cells["Fennec (synctesting)"].children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.swipeLeft()

        // Scroll to she second screen to select the other widget
        sleep(1)
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        sleep(1)
        // Tap on Add widget button
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()
        sleep(1)
        snapshot("Widget-02")
        
        // Tap on Edit and then on Add to Widget
        springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()
        
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()

        springboard.collectionViews.cells["Fennec (synctesting)"].children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.swipeLeft()

        // Scroll to she second screen to select the other widget
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
        
        // Tap on Add widget button
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()
        sleep(1)
        snapshot("Widget-03")
    }

    func testTabTrayOpen() {
        navigator.openURL("firefox.com")
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(TabTray)
        sleep(1)
        snapshot("TabTray-with-tabs")
    }
}
*/
