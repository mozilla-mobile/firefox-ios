/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PhotonActionSheetTest: BaseTestCase {
    func testPinToTop() {
        navigator.openURL(urlString: "http://example.com")
        waitUntilPageLoad()
        // Open Action Sheet
        app.buttons["TabLocationView.pageOptionsButton"].tap()

        // Pin the site
        app.cells["Pin to Top Sites"].tap()

        // Verify that the site has been pinned

        // Open menu
        app.buttons["Menu"].tap()

        // Navigate to top sites
        app.cells["Top Sites"].tap()

        waitforExistence(app.cells["TopSite"].firstMatch)

        // Verify that the site is pinned to top
        let cell = app.cells["TopSite"].firstMatch
        XCTAssertEqual(cell.label, "example")

        // Remove pin
        cell.press(forDuration: 2)
        app.cells["Remove"].tap()
    }

    func testShareOptionIsShown() {
        navigator.browserPerformAction(.shareOption)
        app.buttons["TabLocationView.pageOptionsButton"].press(forDuration: 1)

        // Wait to see the Share options sheet
        waitforExistence(app.buttons["Copy"])
    }

    func testShareOptionIsShownFromShortCut() {
        navigator.goto(BrowserTab)
        app.buttons["TabLocationView.pageOptionsButton"].press(forDuration: 1)
        // Wait to see the Share options sheet
        waitforExistence(app.buttons["Copy"])
    }

    func testSendToDeviceFromPageOptionsMenu() {
        // User not logged in
        navigator.browserPerformAction(.sendToDeviceOption)
        waitforExistence(app.images["emptySync"])
        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }

    func testSendToDeviceFromShareOption() {
        // Open and Wait to see the Share options sheet
        navigator.browserPerformAction(.shareOption)
        waitforExistence(app.buttons["More"])
        waitforNoExistence(app.buttons["Send Tab"])
        app.collectionViews.cells/*@START_MENU_TOKEN@*/.collectionViews.containing(.button, identifier:"Copy")/*[[".collectionViews.containing(.button, identifier:\"Create PDF\")",".collectionViews.containing(.button, identifier:\"Print\")",".collectionViews.containing(.button, identifier:\"Copy\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["More"].tap()

        // Enable Send Tab
        let sendTabButton = app.tables.cells.switches["Send Tab"]
        sendTabButton.tap()
        app.navigationBars["Activities"].buttons["Done"].tap()

        // Send Tab option appears on the Share options sheet
        waitforExistence(app.buttons["Send Tab"])
        app.buttons["Send Tab"].tap()

        // User not logged in
        waitforExistence(app.images["emptySync"])
        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }
}
