/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PhotonActionSheetTest: BaseTestCase {
    // Smoketest
    func testPinToTop() {
        navigator.openURL("http://example.com")
        waitUntilPageLoad()
        // Open Page Action Menu Sheet and Pin the site
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Verify that the site is pinned to top
        waitForExistence(app.cells["example"])
        let cell = app.cells["example"]
        waitForExistence(cell)

        // Remove pin
        app.cells["example"].press(forDuration: 2)
        app.cells["action_unpin"].tap()

        // Check that it has been unpinned
        cell.press(forDuration: 2)
        waitForExistence(app.cells["action_pin"])
    }
    // Disable issue #5554

    func testShareOptionIsShown() {
        navigator.goto(BrowserTab)
        navigator.browserPerformAction(.shareOption)

        // Wait to see the Share options sheet
        waitForExistence(app.collectionViews.buttons["Copy"], timeout: 10)
    }

    // Smoketest
    func testShareOptionIsShownFromShortCut() {
        navigator.goto(BrowserTab)
        waitUntilPageLoad()
        waitForExistence(app.buttons["TabLocationView.pageOptionsButton"])
        let pageObjectButton = app.buttons["TabLocationView.pageOptionsButton"]
        // Fix to bug 1467393, url bar long press is shown sometimes instead of the share menu
        let pageObjectButtonCenter = pageObjectButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        pageObjectButtonCenter.press(forDuration: 1)

        waitForExistence(app.cells["Copy"], timeout: 10)
    }

    func testSendToDeviceFromPageOptionsMenu() {
        // User not logged in
        navigator.browserPerformAction(.sendToDeviceOption)
        waitForExistence(app.navigationBars["Client.InstructionsView"])
        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }
    // Disable issue #5554, More button is not accessible
    /*
    // Test disabled due to new implementation Bug 1449708 - new share sheet
    func testSendToDeviceFromShareOption() {
        // Open and Wait to see the Share options sheet
        navigator.browserPerformAction(.shareOption)
        waitForExistence(app.buttons["More"])
        waitForNoExistence(app.buttons["Send Tab"])
        app.collectionViews.cells/*@START_MENU_TOKEN@*/.collectionViews.containing(.button, identifier:"Copy")/*[[".collectionViews.containing(.button, identifier:\"Create PDF\")",".collectionViews.containing(.button, identifier:\"Print\")",".collectionViews.containing(.button, identifier:\"Copy\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["More"].tap()

        // Enable Send Tab
        let sendTabButton = app.tables.cells.switches["Send Tab"]
        sendTabButton.tap()
        app.navigationBars["Activities"].buttons["Done"].tap()

        // Send Tab option appears on the Share options sheet
        waitForExistence(app.buttons["Send Tab"])
        app.buttons["Send Tab"].tap()

        // User not logged in
        waitForExistence(app.images["emptySync"])
        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }*/

    private func openNewShareSheet() {
        navigator.openURL("example.com")
        navigator.goto(PageOptionsMenu)
        app.tables["Context Menu"].staticTexts["Share Page With…"].tap()
        waitForExistence(app.cells["Copy"], timeout: 5)
        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        let fennecElement = app.collectionViews.scrollViews.cells.element(boundBy: 1)

        fennecElement.tap()
        waitForExistence(app.navigationBars["ShareTo.ShareView"], timeout: 5)
    }

    private func disableFennec() {
        navigator.nowAt(BrowserTab)
        navigator.goto(PageOptionsMenu)
        waitForExistence(app.tables["Context Menu"])
        app.tables["Context Menu"].staticTexts["Share Page With…"].tap()
        waitForExistence(app.buttons["Copy"])
        let moreElement = app.collectionViews.cells.collectionViews.containing(.button, identifier:"Reminders").buttons["More"]
        moreElement.tap()
        waitForExistence(app.switches["Reminders"])
        // Tap on Fennec switch
        app.switches.element(boundBy: 1).tap()
        app.buttons["Done"].tap()
        waitForExistence(app.buttons["Copy"], timeout: 3)
    }

    // Smoketest
    func testSharePageWithShareSheetOptions() {
        openNewShareSheet()
        waitForExistence(app.staticTexts["Open in Firefox"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Open in Firefox"].exists)
        XCTAssertTrue(app.staticTexts["Load in Background"].exists)
        XCTAssertTrue(app.staticTexts["Bookmark This Page"].exists)
        XCTAssertTrue(app.staticTexts["Add to Reading List"].exists)
        XCTAssertTrue(app.staticTexts["Send to Device"].exists)
    }

    func testShareSheetSendToDevice() {
        openNewShareSheet()
        app.staticTexts["Send to Device"].tap()
        waitForExistence(app.navigationBars.buttons["InstructionsViewController.navigationItem.leftBarButtonItem"], timeout: 10)

        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
        app.navigationBars.buttons["InstructionsViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testShareSheetOpenAndCancel() {
        openNewShareSheet()
        app.buttons["Cancel"].tap()
        // User is back to the BrowserTab where the sharesheet was launched
        waitForExistence(app.textFields["url"])
        waitForValueContains(app.textFields["url"], value:"example.com/")
    }
}
