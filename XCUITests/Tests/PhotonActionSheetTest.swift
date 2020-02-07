/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PhotonActionSheetTest: BaseTestCase {
    // Smoketest
    func testPinToTop() {
        navigator.openURL("http://example.com")
        Base.helper.waitUntilPageLoad()
        // Open Page Action Menu Sheet and Pin the site
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Verify that the site is pinned to top
        Base.helper.waitForExistence(Base.app.cells["example"])
        let cell = Base.app.cells["example"]
        Base.helper.waitForExistence(cell)

        // Remove pin
        Base.app.cells["example"].press(forDuration: 2)
        Base.app.cells["action_unpin"].tap()

        // Check that it has been unpinned
        cell.press(forDuration: 2)
        Base.helper.waitForExistence(Base.app.cells["action_pin"])
    }
    // Disable issue #5554
    /*
    func testShareOptionIsShown() {
        navigator.browserPerformAction(.shareOption)

        // Wait to see the Share options sheet
        Base.helper.waitForExistence(Base.app.buttons["Copy"])
    }

    // Smoketest
    func testShareOptionIsShownFromShortCut() {
        navigator.goto(BrowserTab)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["TabLocationView.pageOptionsButton"])
        let pageObjectButton = Base.app.buttons["TabLocationView.pageOptionsButton"]
        // Fix to bug 1467393, url bar long press is shown sometimes instead of the share menu
        let pageObjectButtonCenter = pageObjectButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        pageObjectButtonCenter.press(forDuration: 1)

        Base.helper.waitForExistence(Base.app.buttons["Copy"], timeout: 10)
    }*/

    func testSendToDeviceFromPageOptionsMenu() {
        // User not logged in
        navigator.browserPerformAction(.sendToDeviceOption)
        Base.helper.waitForExistence(Base.app.navigationBars["Client.InstructionsView"])
        XCTAssertTrue(Base.app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }
    // Disable issue #5554
    /*
    // Test disabled due to new implementation Bug 1449708 - new share sheet
    func testSendToDeviceFromShareOption() {
        // Open and Wait to see the Share options sheet
        navigator.browserPerformAction(.shareOption)
        Base.helper.waitForExistence(Base.app.buttons["More"])
        Base.helper.waitForNoExistence(Base.app.buttons["Send Tab"])
        Base.app.collectionViews.cells/*@START_MENU_TOKEN@*/.collectionViews.containing(.button, identifier:"Copy")/*[[".collectionViews.containing(.button, identifier:\"Create PDF\")",".collectionViews.containing(.button, identifier:\"Print\")",".collectionViews.containing(.button, identifier:\"Copy\")"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["More"].tap()

        // Enable Send Tab
        let sendTabButton = Base.app.tables.cells.switches["Send Tab"]
        sendTabButton.tap()
        Base.app.navigationBars["Activities"].buttons["Done"].tap()

        // Send Tab option appears on the Share options sheet
        Base.helper.waitForExistence(Base.app.buttons["Send Tab"])
        Base.app.buttons["Send Tab"].tap()

        // User not logged in
        Base.helper.waitForExistence(Base.app.images["emptySync"])
        XCTAssertTrue(Base.app.staticTexts["You are not signed in to your Firefox Account."].exists)
    }*/

    private func openNewShareSheet() {
        navigator.openURL("example.com")
        navigator.goto(PageOptionsMenu)
        Base.app.tables["Context Menu"].staticTexts["Share Page With…"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Copy"], timeout: 5)
        let countButtons = Base.app.collectionViews.cells.collectionViews.buttons.count
        let fennecElement = Base.app.collectionViews.cells.collectionViews.buttons.element(boundBy: 1)
        // If Fennec has not been configured there are 5 buttons, 6 if it is there already
        if (countButtons <= 6) {
            let moreElement = Base.app.collectionViews.cells.collectionViews.containing(.button, identifier:"Reminders").buttons["More"]
            moreElement.tap()
            Base.helper.waitForExistence(Base.app.switches["Reminders"])
            // Tap on Fennec switch
            Base.app.switches.element(boundBy: 1).tap()
            Base.app.buttons["Done"].tap()
            Base.helper.waitForExistence(Base.app.buttons["Copy"])
        }
        fennecElement.tap()
        Base.helper.waitForExistence(Base.app.navigationBars["ShareTo.ShareView"], timeout: 5)
    }

    private func disableFennec() {
        navigator.nowAt(BrowserTab)
        navigator.goto(PageOptionsMenu)
        Base.helper.waitForExistence(Base.app.tables["Context Menu"])
        Base.app.tables["Context Menu"].staticTexts["Share Page With…"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Copy"])
        let moreElement = Base.app.collectionViews.cells.collectionViews.containing(.button, identifier:"Reminders").buttons["More"]
        moreElement.tap()
        Base.helper.waitForExistence(Base.app.switches["Reminders"])
        // Tap on Fennec switch
        Base.app.switches.element(boundBy: 1).tap()
        Base.app.buttons["Done"].tap()
        Base.helper.waitForExistence(Base.app.buttons["Copy"], timeout: 3)
    }
    // Disable issue #5554
    /*
    // Smoketest
    func testSharePageWithShareSheetOptions() {
        openNewShareSheet()
        XCTAssertTrue(Base.app.staticTexts["Open in Firefox"].exists)
        XCTAssertTrue(Base.app.staticTexts["Load in Background"].exists)
        XCTAssertTrue(Base.app.staticTexts["Bookmark This Page"].exists)
        XCTAssertTrue(Base.app.staticTexts["Add to Reading List"].exists)
        XCTAssertTrue(Base.app.staticTexts["Send to Device"].exists)
        Base.app.buttons["Cancel"].tap()
        disableFennec()
    }

    func testShareSheetSendToDevice() {
        openNewShareSheet()
        Base.app.staticTexts["Send to Device"].tap()
        XCTAssertTrue(Base.app.images["emptySync"].exists)
        XCTAssertTrue(Base.app.staticTexts["You are not signed in to your Firefox Account."].exists)
        Base.helper.waitForExistence(Base.app.navigationBars.buttons["Close"], timeout: 3)
        Base.app.navigationBars.buttons["Close"].tap()
        disableFennec()
    }

    func testShareSheetOpenAndCancel() {
        openNewShareSheet()
        Base.app.buttons["Cancel"].tap()
        // User is back to the BrowserTab where the sharesheet was launched
        Base.helper.waitForExistence(Base.app.textFields["url"])
        Base.helper.waitForValueContains(Base.app.textFields["url"], value:"example.com/")
        disableFennec()
    }*/
}
