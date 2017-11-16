/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let website_1 = ["url": "www.mozilla.org", "label": "Internet for people, not profit — Mozilla", "value": "mozilla.org"]
let website_2 = ["url": "www.example.com", "label": "Example", "value": "example"]

let urlAddons = "addons.mozilla.org"
let urlGoogle = "www.google.com"

let requestMobileSiteLabel = "Request Mobile Site"
let requestDesktopSiteLabel = "Request Desktop Site"

class NavigationTest: BaseTestCase {
    func testNavigation() {
        navigator.goto(URLBarOpen)
        let urlPlaceholder = "Search or enter address"
        XCTAssert(app.textFields["url"].exists)
        let defaultValuePlaceholder = app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssert(urlPlaceholder == defaultValuePlaceholder)
        if iPad() {
            app.buttons["goBack"].tap()
            XCTAssertFalse(app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["Forward"].isEnabled)
            app.textFields["url"].tap()
        } else {
            XCTAssertFalse(app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)
        }

        // Once an url has been open, the back button is enabled but not the forward button
        navigator.openURL(website_1["url"]!)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_1["value"]!)
        if iPad() {
            XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["Forward"].isEnabled)
        } else {
            XCTAssertTrue(app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)
        }

        // Once a second url is open, back button is enabled but not the forward one till we go back to url_1
        navigator.openURL(website_2["url"]!)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_2["value"]!)
        if iPad() {
            XCTAssertTrue(app.buttons["URLBarView.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["Forward"].isEnabled)
            // Go back to previous visited web site
            app.buttons["URLBarView.backButton"].tap()
        } else {
            XCTAssertTrue(app.buttons["TabToolbar.backButton"].isEnabled)
            XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)
            // Go back to previous visited web site
            app.buttons["TabToolbar.backButton"].tap()
        }
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_1["value"]!)

        if iPad() {
            app.buttons["Forward"].tap()
        } else {
            // Go forward to next visited web site
            app.buttons["TabToolbar.forwardButton"].tap()
        }
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: website_2["value"]!)
    }

    func testTapSignInShowsFxAFromTour() {
        // Open FxAccount from tour option in settings menu and go throughout all the screens there
        navigator.goto(Intro_FxASignin)
        checkFirefoxSyncScreenShown()

        // Go back to NewTabScreen
        navigator.goto(HomePanelsScreen)
        waitforExistence(app.buttons["HomePanels.TopSites"])
    }

    func testTapSigninShowsFxAFromSettings() {
        navigator.goto(SettingsScreen)
        // Open FxAccount from settings menu and check the Sign in to Firefox scren
        let signInToFirefoxStaticText = app.tables["AppSettingsTableViewController.tableView"].staticTexts["Sign in to Sync"]
        signInToFirefoxStaticText.tap()
        checkFirefoxSyncScreenShown()

        // After that it is possible to go back to Settings
        let settingsButton = app.navigationBars["Client.FxAContentView"].buttons["Settings"]
        settingsButton.tap()
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        navigator.goto(HomePanel_TopSites)
        // Open FxAccount from remote tab panel and check the Sign in to Firefox scren
        navigator.goto(HomePanel_History)
        XCTAssertTrue(app.tables["History List"].staticTexts["Synced Devices"].isEnabled)
        app.tables["History List"].staticTexts["Synced Devices"].tap()
        app.tables.buttons["Sign in"].tap()
        checkFirefoxSyncScreenShown()
        app.navigationBars["Client.FxAContentView"].buttons["Done"].tap()
        navigator.nowAt(HomePanel_History)
    }

    private func checkFirefoxSyncScreenShown() {
        waitforExistence(app.webViews.staticTexts["Sign in"])
        XCTAssertTrue(app.webViews.textFields["Email"].exists)
        XCTAssertTrue(app.webViews.secureTextFields["Password"].exists)
        XCTAssertTrue(app.webViews.buttons["Sign in"].exists)
    }

    func testScrollsToTopWithMultipleTabs() {
        navigator.goto(TabTray)
        navigator.openURL(website_1["url"]!)
        waitForValueContains(app.textFields["url"], value: website_1["value"]!)

        // Element at the TOP. TBChanged once the web page is correclty shown
        let topElement = app.webViews.staticTexts["The new"]

        // Element at the BOTTOM
        let bottomElement = app.webViews.links.staticTexts["Contact Us"]

        // Scroll to bottom
        bottomElement.tap()
        waitUntilPageLoad()
        if iPad() {
            app.buttons["URLBarView.backButton"].tap()
        } else {
            app.buttons["TabToolbar.backButton"].tap()
        }
        waitUntilPageLoad()

        // Scroll to top
        topElement.tap()
        waitforExistence(topElement)
    }

    private func checkMobileView() {
        let mobileViewElement = app.webViews.links.staticTexts["Use precise location"]
        waitforExistence(mobileViewElement)
        XCTAssertTrue (mobileViewElement.exists, "Mobile view is not available")
    }

    private func checkDesktopView() {
        let desktopViewElement = app.webViews.links.staticTexts["About Google"]
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available")
    }

    private func clearData() {
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(NewTabScreen)
    }

    func testToggleBetweenMobileAndDesktopSiteFromSite() {
        clearData()
        let goToDesktopFromMobile = app.webViews.links.staticTexts["View classic desktop site"]
        // Open URL by default in mobile view. This web site works changing views using their links not with the menu options
        navigator.openURL(urlAddons, waitForLoading: false)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: urlAddons)
        waitforExistence(goToDesktopFromMobile)

        // From the website go to Desktop view
        goToDesktopFromMobile.tap()
        waitUntilPageLoad()

        let desktopViewElement = app.webViews.links.staticTexts["View the new site"]
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available")

        // From the website go back to Mobile view
        app.webViews.links.staticTexts["View the new site"].tap()
        waitUntilPageLoad()

        let mobileViewElement = app.webViews.links.staticTexts["View classic desktop site"]
        waitforExistence(mobileViewElement)
        XCTAssertTrue (mobileViewElement.exists, "Mobile view is not available")
    }

    func testToggleBetweenMobileAndDesktopSiteFromMenu() {
        clearData()
        navigator.openURL(urlGoogle)
        waitUntilPageLoad()
        waitForValueContains(app.textFields["url"], value: "google")
        
        // Mobile view by default, desktop view should be available
        navigator.browserPerformAction(.toggleDesktopOption)
        checkDesktopSite()
        checkDesktopView()

        // From desktop view it is posible to change to mobile view again
        navigator.nowAt(BrowserTab)
        navigator.browserPerformAction(.toggleDesktopOption)
        checkMobileSite()
        checkMobileView()
    }

    private func checkMobileSite() {
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        waitforExistence(app.tables.cells["menu-RequestDesktopSite"].staticTexts[requestDesktopSiteLabel])
        navigator.goto(BrowserTab)
    }
    
    private func checkDesktopSite() {
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        waitforExistence(app.tables.cells["menu-RequestDesktopSite"].staticTexts[requestMobileSiteLabel])
        navigator.goto(BrowserTab)
    }
    
    func testNavigationPreservesDesktopSiteOnSameHost() {
        clearData()
        navigator.openURL(urlGoogle)
        waitUntilPageLoad()

        // Mobile view by default, desktop view should be available
        navigator.browserPerformAction(.toggleDesktopOption)
        waitforNoExistence(app.tables["Context Menu"])
        waitUntilPageLoad()
        checkDesktopView()

        // Select any link to navigate to another site and check if the view is kept in desktop view
        waitforExistence(app.webViews.links["Images"])
        app.webViews.links["Images"].tap()

        // About Google appear on desktop view but not in mobile view
        waitforExistence(app.webViews.links["About Google"])
    }

    func testReloadPreservesMobileOrDesktopSite() {
        clearData()
        navigator.openURL(urlGoogle)
        waitUntilPageLoad()

        // Mobile view by default, desktop view should be available
        navigator.browserPerformAction(.toggleDesktopOption)
        waitUntilPageLoad()

        // After reloading a website the desktop view should be kept
        if iPad() {
                app.buttons["Reload"].tap()
        } else {
                app.buttons["TabToolbar.stopReloadButton"].tap()
        }
        waitForValueContains(app.textFields["url"], value: "google")
        waitUntilPageLoad()
        checkDesktopView()

        // From desktop view it is posible to change to mobile view again
        navigator.nowAt(BrowserTab)
        navigator.browserPerformAction(.toggleDesktopOption)
        waitUntilPageLoad()

        // After reloading a website the mobile view should be kept
        if iPad() {
            app.buttons["Reload"].tap()
        } else {
            app.buttons["TabToolbar.stopReloadButton"].tap()
        }
        checkMobileView()
    }

    /* Disable test due to bug 1346157, the desktop view is not kept after going back and forward
      func testBackForwardNavigationRestoresMobileOrDesktopSite() {
        clearData()
        let desktopViewElement = app.webViews.links.staticTexts["Mobile"]

        // Open first url and keep it in mobile view
        navigator.openURL(urlString: urlGoogle)
        waitForValueContains(app.textFields["url"], value: urlGoogle)
        checkMobileView()
        // Open a second url and change it to desktop view
        navigator.openURL(urlString: "www.linkedin.com")
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["menu-RequestDesktopSite"].staticTexts[requestDesktopSiteLabel])
        app.tables.cells["menu-RequestDesktopSite"].tap()
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available")

        // Go back to first url and check that the view is still mobile view
        app.buttons["TabToolbar.backButton"].tap()
        waitForValueContains(app.textFields["url"], value: urlGoogle)
        checkMobileView()

        // Go forward to second url and check that the view is still desktop view
        app.buttons["TabToolbar.forwardButton"].tap()
        waitForValueContains(app.textFields["url"], value: "www.linkedin.com")
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available after coming from another site in mobile view")
     }
     */
 }
