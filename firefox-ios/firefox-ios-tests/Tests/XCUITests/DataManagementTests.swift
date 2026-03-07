// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DataManagementTests: BaseTestCase {
    private var webSitesDataScreen: WebsiteDataScreen!

    func cleanAllData() {
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        mozWaitForElementToNotExist(app.activityIndicators.firstMatch)
        // navigator.performAction(Action.AcceptClearAllWebsiteData)
        // We need to fix the method in FxScreenGraph file
        // but there are many linter issues on that file, so this is a quick fix
        app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"].waitAndTap(timeout: TIMEOUT)
        app.alerts.buttons["OK"].waitAndTap(timeout: TIMEOUT)
        mozWaitForElementToNotExist(app.alerts.buttons["OK"])
        XCTAssertEqual(app.cells.buttons.images.count, 0, "The Website data has not cleared correctly")
        // Navigate back to the browser
        mozWaitElementEnabled(element: app.buttons["Data Management"], timeout: TIMEOUT)
        app.buttons["Data Management"].waitAndTap()
        app.buttons["Settings"].waitAndTap()
        app.buttons["Done"].waitAndTap()
    }

    // Testing the search bar, and clear website data option
    // https://mozilla.testrail.io/index.php?/cases/view/2307015
    func testWebSiteDataOptions() {
        cleanAllData()
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-example.html"))
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        // The Settings button may not be visible on iOS 15
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])

        var beforeDelete = 0
        if #available(iOS 17, *) {
            beforeDelete = app.cells.images.count
            app.cells.images["circle"].firstMatch.waitAndTap()
        } else {
            beforeDelete = app.cells.staticTexts.count
            app.cells.staticTexts.firstMatch.waitAndTap()
        }

        app.otherElements.staticTexts["Clear Items: 1"].waitAndTap()
        app.alerts.buttons["OK"].waitAndTap()
        mozWaitForElementToNotExist(app.alerts.buttons["OK"])
        if #available(iOS 17, *) {
            XCTAssertEqual(beforeDelete-1, app.cells.images.count, "The first entry has not been deleted correctly")
        } else {
            XCTAssertEqual(beforeDelete-1, app.cells.staticTexts.count, "The first entry has not been deleted correctly")
        }
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        mozWaitForElementToExist(app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"])
        XCTAssertEqual(0, app.cells.buttons.images.count)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307017
    // Smoketest
    func testWebSiteDataEnterFirstTime() {
        webSitesDataScreen = WebsiteDataScreen(app: app)

        // Warm-up: Open Website Data Settings first to handle slow cold start (best effort)
        // The first load is often very slow due to initialization, subsequent loads are fast
        // If warm-up times out, the retry pattern below will handle it
        navigator.goto(WebsiteDataSettings)
        if app.tables.otherElements["Website Data"].waitForExistence(timeout: TIMEOUT) {
            // Wait up to 45s for activity indicator, but don't fail if it times out
            mozWaitForElementToNotExist(app.activityIndicators.firstMatch, timeout: TIMEOUT_LONG)
        }
        navigator.goto(NewTabScreen)
        waitForTabsButton()

        // Now run the actual test with the app already warmed up
        navigator.goto(WebsiteDataSettings)
        webSitesDataScreen.clearAllWebsiteData()
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.openURL("example.com")
        waitUntilPageLoad()

        // Retry pattern: try loading website data settings up to 3 times
        // This handles the flaky behavior where iOS may not have persisted website data yet
        var dataLoaded = false
        for attempt in 1...3 {
            navigator.goto(WebsiteDataSettings)

            // Check if data loaded successfully
            if webSitesDataScreen.checkIfDataLoaded() {
                dataLoaded = true
                break
            }

            // If not loaded and not last attempt, go back and wait before retry
            if attempt < 3 {
                navigator.goto(NewTabScreen)
                sleep(2) // Give iOS more time to persist website data
            }
        }

        XCTAssertTrue(dataLoaded, "Website data did not load after 3 attempts")

        webSitesDataScreen.expandShowMoreIfNeeded()
        webSitesDataScreen.waitForExampleDomain()
        webSitesDataScreen.assertWebsiteDataVisible()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2802088
    func testFilterWebsiteData() {
        cleanAllData()
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        navigator.nowAt(BrowserTab)
        navigator.openURL(path(forTestPage: "test-example.html"))
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        // The Settings button may not be visible on iOS 15
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        app.tables.otherElements["Website Data"].swipeDown()
        mozWaitForElementToExist(app.searchFields["Filter Sites"])
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("mozilla")
        mozWaitForElementToExist(app.tables["Search results"])
        // "localhost" still exist in the debugDescription, but is not visible.
        // I cannot test for visibility at the moment.
        // let expectedSearchResults = app.tables["Search results"].cells.count
        // XCTAssertEqual(expectedSearchResults, 1)
        if #available(iOS 26, *) {
            if iPad() {
                app.buttons["Clear text"].waitAndTap()
            } else {
                app.buttons["close"].waitAndTap()
            }
        } else {
            app.buttons["Cancel"].waitAndTap()
        }
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        if #available(iOS 17, *) {
            XCTAssertGreaterThan(app.cells.images.count, 1)
        } else {
            XCTAssertGreaterThan(app.cells.staticTexts.count-1, 1)
        }
    }
 }
