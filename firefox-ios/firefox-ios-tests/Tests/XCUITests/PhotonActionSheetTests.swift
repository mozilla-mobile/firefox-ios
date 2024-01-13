// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class PhotonActionSheetTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306849
    // Smoketest
    func testPinToShortcuts() {
        navigator.openURL("http://example.com")
        waitUntilPageLoad()
        // Open Page Action Menu Sheet and Pin the site
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Verify that the site is pinned to top
        let cell = app.cells[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell].staticTexts["Example Domain"]
        mozWaitForElementToExist(cell)

        // Remove pin
        cell.press(forDuration: 2)
        app.tables.cells.otherElements[StandardImageIdentifiers.Large.pinSlash].tap()

        // Check that it has been unpinned
        cell.press(forDuration: 2)
        mozWaitForElementToExist(app.tables.cells.otherElements[StandardImageIdentifiers.Large.pin])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2322067
    // Smoketest
    func testShareOptionIsShown() {
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()

        // Wait to see the Share options sheet
        mozWaitForElementToExist(app.cells["Copy"], timeout: 15)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2322667
    func testSendToDeviceFromPageOptionsMenu() {
        // User not logged in
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()
        mozWaitForElementToExist(app.cells["Send Link to Device"], timeout: 10)
        app.cells["Send Link to Device"].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton])
        XCTAssertTrue(app.staticTexts["You are not signed in to your account."].exists)
        XCTAssertTrue(app.staticTexts["Please open Firefox, go to Settings and sign in to continue."].exists)
    }

    private func openNewShareSheet() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from CoreSimulatorBridge"])

        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.shareButton], timeout: 10)
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].tap()

        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        mozWaitForElementToExist(app.otherElements["ActivityListView"].otherElements["Example Domain"])
        mozWaitForElementToExist(app.otherElements["ActivityListView"].otherElements["example.com"])
        mozWaitForElementToExist(app.collectionViews.cells["Copy"], timeout: TIMEOUT)

        let fennecElement = app.collectionViews.scrollViews.cells.elementContainingText("Fennec")
        mozWaitForElementToExist(fennecElement, timeout: 5)
        fennecElement.tap()
        mozWaitForElementToExist(app.navigationBars["ShareTo.ShareView"])
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2306841
    // Smoketest
    func testSharePageWithShareSheetOptions() {
        openNewShareSheet()
        mozWaitForElementToExist(app.staticTexts["Open in Firefox"], timeout: 10)
        XCTAssertTrue(app.staticTexts["Open in Firefox"].exists)
        XCTAssertTrue(app.staticTexts["Load in Background"].exists)
        XCTAssertTrue(app.staticTexts["Bookmark This Page"].exists)
        XCTAssertTrue(app.staticTexts["Add to Reading List"].exists)
        XCTAssertTrue(app.staticTexts["Send to Device"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2323203
    func testShareSheetSendToDevice() {
        openNewShareSheet()
        mozWaitForElementToExist(app.staticTexts["Send to Device"])
        app.staticTexts["Send to Device"].tap()
        mozWaitForElementToExist(
            app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton],
            timeout: 10
        )

        XCTAssertTrue(app.staticTexts["You are not signed in to your account."].exists)
        app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton].tap()
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2323204
    func testShareSheetOpenAndCancel() {
        openNewShareSheet()
        app.buttons["Cancel"].tap()
        // User is back to the BrowserTab where the sharesheet was launched
        mozWaitForElementToExist(app.textFields["url"])
        mozWaitForValueContains(app.textFields["url"], value: "example.com/")
    }
}
