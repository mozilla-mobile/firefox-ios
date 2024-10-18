// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DataManagementTests: BaseTestCase {
    // Testing the search bar, and clear website data option
    // https://mozilla.testrail.io/index.php?/cases/view/2307015
    func testWebSiteDataOptions() {
        navigator.nowAt(NewTabScreen)
        waitForTabsButton()
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        app.tables.otherElements["Website Data"].swipeDown()
        mozWaitForElementToExist(app.searchFields["Filter Sites"])
        navigator.performAction(Action.TapOnFilterWebsites)
        app.typeText("bing")
        mozWaitForElementToExist(app.tables["Search results"])
        let expectedSearchResults = app.tables["Search results"].cells.count
        sleep(3)
        XCTAssertEqual(expectedSearchResults, 1)
        navigator.performAction(Action.TapOnFilterWebsites)

        app.buttons["Cancel"].tap()
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])

        navigator.performAction(Action.AcceptClearAllWebsiteData)
        mozWaitForElementToExist(app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"])
        let expectedWebsitesCleared = app.tables.cells.count
        XCTAssertEqual(expectedWebsitesCleared, 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307017
    // Smoketest
    func testWebSiteDataEnterFirstTime() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        navigator.goto(WebsiteDataSettings)
        mozWaitForElementToExist(app.tables.otherElements["Website Data"])
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.tables.buttons.images["circle"].firstMatch, timeout: TIMEOUT_LONG)
        } else {
            mozWaitForElementToExist(app.tables.buttons.firstMatch)
        }
        if app.cells["ShowMoreWebsiteData"].exists {
            app.cells["ShowMoreWebsiteData"].tap()
        }
        mozWaitForElementToExist(app.staticTexts["example.com"])
        // There should be 4 entries. One is the website visited and 3 for extrainfo from the page.
        // This assert will remain commented until a way is found of having website data clean on the first run
        // This is to avoid intermittent failings
        // XCTAssertEqual(app.tables.staticTexts.count, 4)
    }
 }
