// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DataManagementTests: BaseTestCase {
    func cleanAllData() {
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        XCTAssertEqual(app.cells.buttons.images.count, 0, "The Website data has not cleared correctly")
        // Navigate back to the browser
        mozWaitElementHittable(element: app.buttons["Data Management"], timeout: TIMEOUT)
        app.buttons["Data Management"].tap()
        app.buttons["Settings"].waitAndTap()
        app.buttons["Done"].waitAndTap()
    }

    // Testing the search bar, and clear website data option
    // https://mozilla.testrail.io/index.php?/cases/view/2307015
    func testWebSiteDataOptions() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        navigator.openURL(path(forTestPage: "test-example.html"))
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])

        var beforeDelete = 0
        if #available(iOS 17, *) {
            beforeDelete = app.cells.images.count
            app.cells.images["circle"].firstMatch.tap()
        } else {
            beforeDelete = app.cells.staticTexts.count
            app.cells.staticTexts.firstMatch.tap()
        }

        app.otherElements.staticTexts["Clear Items: 1"].tap()
        app.alerts.buttons["OK"].tap()
        if #available(iOS 17, *) {
            XCTAssertEqual(beforeDelete-1, app.cells.images.count, "The first entry has not been deleted correctly")
        } else {
            XCTAssertEqual(beforeDelete-1, app.cells.staticTexts.count, "The first entry has not been deleted correctly")
        }
        navigator.performAction(Action.AcceptClearAllWebsiteData)
        mozWaitForElementToExist(app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"])
        XCTAssertEqual(0, app.cells.images.count)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307017
    // Smoketest
    func testWebSiteDataEnterFirstTime() {
        cleanAllData()
        navigator.nowAt(NewTabScreen)
        navigator.openURL("example.com")
        waitUntilPageLoad()
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.tables.buttons.images["circle"].firstMatch)
        } else {
            mozWaitForElementToExist(app.tables.buttons.firstMatch)
        }
        if app.cells["ShowMoreWebsiteData"].exists {
            app.cells["ShowMoreWebsiteData"].tap()
        }
        mozWaitForElementToExist(app.staticTexts["example.com"])
        if #available(iOS 17, *) {
            XCTAssertEqual(1, app.cells.images.count)
        } else {
            XCTAssertEqual(1, app.cells.staticTexts.count-1)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2802088
    func testFilterWebsiteData() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        navigator.goto(NewTabScreen)
        navigator.openURL(path(forTestPage: "test-example.html"))
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        app.tables.otherElements["Website Data"].swipeDown()
        mozWaitForElementToExist(app.searchFields["Filter Sites"])
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("mozilla")
        mozWaitForElementToExist(app.tables["Search results"])
        let expectedSearchResults = app.tables["Search results"].cells.count
        XCTAssertEqual(expectedSearchResults-1, 1)
        app.buttons["Cancel"].tap()
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        if #available(iOS 17, *) {
            XCTAssertGreaterThan(app.cells.images.count, 1)
        } else {
            XCTAssertGreaterThan(app.cells.staticTexts.count-1, 1)
        }
    }
 }
