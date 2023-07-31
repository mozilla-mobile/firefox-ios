// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

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
        let cell = app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].staticTexts["Example Domain"]
        waitForExistence(cell)

        // Remove pin
        cell.press(forDuration: 2)
        app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash].tap()

        // Check that it has been unpinned
        cell.press(forDuration: 2)
        waitForExistence(app.tables.cells.otherElements[StandardImageIdentifiers.Large.pin])
    }

    func testShareOptionIsShown() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()

        // Wait to see the Share options sheet
        waitForExistence(app.cells["Copy"], timeout: 10)
    }

    // Smoketest
    func testShareOptionIsShownFromShortCut() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()

        // Wait to see the Share options sheet
        if iPad() {
            waitForExistence(app.cells["Copy"], timeout: 15)
        } else {
            waitForExistence(app.buttons["Close"], timeout: 15)
        }
    }

    func testSendToDeviceFromPageOptionsMenu() {
        // User not logged in
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()
        waitForExistence(app.cells["Send Link to Device"], timeout: 10)
        app.cells["Send Link to Device"].tap()
        waitForExistence(app.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton])
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
        waitForExistence(app.images[ImageIdentifiers.emptySyncImageName])
        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }*/

    private func openNewShareSheet() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        waitForNoExistence(app.staticTexts["Fennec pasted from CoreSimulatorBridge"])

        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()

        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        waitForExistence(app.collectionViews.cells["Copy"], timeout: TIMEOUT)
        waitForExistence(app.collectionViews.scrollViews.cells["XCElementSnapshotPrivilegedValuePlaceholder"].firstMatch, timeout: TIMEOUT)
        var  fennecElement = app.collectionViews.scrollViews.cells.element(boundBy: 2)
        if iPad() {
            fennecElement = app.collectionViews.scrollViews.cells.element(boundBy: 1)
        }
        waitForExistence(fennecElement, timeout: 5)
        fennecElement.tap()
        waitForExistence(app.navigationBars["ShareTo.ShareView"], timeout: TIMEOUT)
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
        waitForExistence(app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton], timeout: 10)

        XCTAssertTrue(app.staticTexts["You are not signed in to your Firefox Account."].exists)
        app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton].tap()
    }

    func testShareSheetOpenAndCancel() {
        openNewShareSheet()
        app.buttons["Cancel"].tap()
        // User is back to the BrowserTab where the sharesheet was launched
        waitForExistence(app.textFields["url"])
        waitForValueContains(app.textFields["url"], value: "example.com/")
    }
}
