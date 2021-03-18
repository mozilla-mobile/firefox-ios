/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Disabled by default, running locally to get these specific screenshots in specific locales
import XCTest

class L10nMktSuiteSnapshotTests: L10nBaseSnapshotTests {

    func test1SettingsETP() {
        navigator.goto(TrackingProtectionSettings)
        
       // Check the warning alert
        app.cells["Settings.TrackingProtectionOption.BlockListStrict"].tap()
        app.alerts.buttons.firstMatch.tap()
        sleep(3)
        snapshot("TrackingProtectionStrictWarning-01")
        waitForExistence(app.cells["Settings.TrackingProtectionOption.BlockListBasic"])
    }
    
    func test2URLBar() {
        navigator.openURL("https://www.kingarthurbaking.com/recipes/sourdough-starter-recipe")
        sleep(2)
        
        navigator.openNewURL(urlString: "https://www.thekitchn.com/how-to-make-sourdough-bread-224367")
        sleep(2)
        
        userState.url = "sourdough"
        navigator.performAction(Action.SetURLByTyping)
        sleep(1)
        app.staticTexts["sourdough starter"].tap()
        waitUntilPageLoad()

        sleep(2)
        navigator.performAction(Action.SetURLByTyping)
        // app.staticTexts["sourdough pizza"].tap()
        app.staticTexts.element(boundBy: 2).tap()
        sleep(1)

        userState.url = "sourdough"
        navigator.performAction(Action.SetURLByTyping)
        sleep(2)
        snapshot("URLBar-02")
    }
    
    // DarkMode for these tests
    func test3DefaultTopSites() {
        // Enable Dark Mode
        navigator.goto(SettingsScreen)
        navigator.goto(DisplaySettings)
        app.switches["SystemThemeSwitchValue"].tap()
    
        app.cells.staticTexts.element(boundBy: 6).tap()
        navigator.goto(HomePanelsScreen)
        snapshot("DefaultTopSites-01")
    }
    
    func test4PrivateBrowsingTabsEmptyState() {
        navigator.toggleOn(userState.isPrivate, withAction: Action.TogglePrivateMode)
        app.buttons["closeTabButtonTabTray"].tap()
        waitForExistence(app.tables["Empty list"], timeout: 3)
        snapshot("PrivateBrowsingMode")
    }
    
    func test5DefaultSearchEngine() {
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
        snapshot("DefaultBrowser-01")
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
        print(springboard.debugDescription)
        springboard.scrollViews.staticTexts.firstMatch.swipeLeft()
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
}
*/
