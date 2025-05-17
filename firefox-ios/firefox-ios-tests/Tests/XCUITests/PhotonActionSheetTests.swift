// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class PhotonActionSheetTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2306849
    // Smoketest
    func testPinToShortcuts() {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        // Open Page Action Menu Sheet and Pin the site
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Verify that the site is pinned to top
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let cell = itemCell.staticTexts["Example Domain"]
        mozWaitForElementToExist(cell)
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.links["Pinned: Example Domain"].images[StandardImageIdentifiers.Small.pinBadgeFill])
        } else {
            // No identifier is available for iOS 17 amd below
            mozWaitForElementToExist(app.links["Pinned: Example Domain"].images.element(boundBy: 1))
        }

        // Remove pin
        cell.press(forDuration: 2)
        app.tables.cells.buttons[StandardImageIdentifiers.Large.pinSlash].waitAndTap()
        // Check that it has been unpinned
        if #available(iOS 17, *) {
            mozWaitForElementToNotExist(app.links["Example Domain"].images[StandardImageIdentifiers.Small.pinBadgeFill])
        } else {
            mozWaitForElementToNotExist(app.links["Example Domain"].images.element(boundBy: 1))
        }

        mozWaitForElementToNotExist(cell)
    }

    private func openNewShareSheet() {
        navigator.openURL("example.com")
        waitUntilPageLoad()
        mozWaitForElementToNotExist(app.staticTexts["Fennec pasted from CoreSimulatorBridge"])
        app.buttons[AccessibilityIdentifiers.Toolbar.shareButton].waitAndTap()

        if #unavailable(iOS 16) {
            waitForElementsToExist(
                [
                    app.otherElements["ActivityListView"].navigationBars["UIActivityContentView"],
                    app.buttons["Copy"]
                ]
            )
        } else {
            waitForElementsToExist(
                [
                app.otherElements["ActivityListView"].otherElements["Example Domain"],
                app.otherElements["ActivityListView"].otherElements["example.com"],
                app.collectionViews.cells["Copy"]
                ]
            )
        }
        var fennecElement = app.collectionViews.scrollViews.cells.elementContainingText("Fennec")
        // This is not ideal but only way to get the element on iPhone 8
        // for iPhone 11, that would be boundBy: 2
        if #unavailable(iOS 17) {
            fennecElement = app.collectionViews.scrollViews.cells.element(boundBy: 2)
        }
        fennecElement.waitAndTap()
        mozWaitForElementToExist(app.navigationBars["ShareTo.ShareView"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306841
    // Smoketest
    func testSharePageWithShareSheetOptions() {
        openNewShareSheet()
        waitForElementsToExist(
            [
                app.staticTexts["Open in Firefox"],
                app.staticTexts["Load in Background"],
                app.staticTexts["Bookmark This Page"],
                app.staticTexts["Add to Reading List"]
            ]
        )
        mozWaitForElementToExist(app.staticTexts["Send to Device"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323203
    func testShareSheetSendToDevice() {
        openNewShareSheet()
        app.staticTexts["Send to Device"].waitAndTap()
        waitForElementsToExist(
            [
                app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton],
                app.staticTexts["You are not signed in to your account."]
            ]
        )
        app.navigationBars.buttons[AccessibilityIdentifiers.ShareTo.HelpView.doneButton].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323204
    func testShareSheetOpenAndCancel() {
        openNewShareSheet()
        app.buttons["Cancel"].waitAndTap()
        // User is back to the BrowserTab where the sharesheet was launched
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForElementToExist(url)
        mozWaitForValueContains(url, value: "example.com")
    }
}
