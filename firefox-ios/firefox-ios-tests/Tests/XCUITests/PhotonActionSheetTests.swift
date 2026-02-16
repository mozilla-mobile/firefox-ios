// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

class PhotonActionSheetTests: BaseTestCase {
    var toolBarScreen: ToolbarScreen!
    var photonActionSheetScreen: PhotonActionSheetScreen!
    var browserScreen: BrowserScreen!
    var topSitesScreen: TopSitesScreen!

    override func setUp() async throws {
        try await super.setUp()
        toolBarScreen = ToolbarScreen(app: app)
        photonActionSheetScreen = PhotonActionSheetScreen(app: app)
        browserScreen = BrowserScreen(app: app)
        topSitesScreen = TopSitesScreen(app: app)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306849
    // Smoketest
    func testPinToShortcuts() {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        // Open Page Action Menu Sheet and Pin the site
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenuMore)
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }

        // Verify that the site is pinned to top
        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let cell = itemCell.staticTexts["Example Domain"]
        mozWaitForElementToExist(cell)
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.links["Pinned: Example Domain"].images[StandardImageIdentifiers.Large.pinFill])
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306849
    // Smoketest TAE
    func testPinToShortcuts_TAE() {
        app.launch()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()

        // Open Page Action Menu Sheet and Pin the site
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenuMore)
        navigator.performAction(Action.PinToTopSitesPAM)

        // Navigate to topsites to verify that the site has been pinned
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        browserScreen.tapCancelButtonIfExist()

        // Verify that the site is pinned to top
        topSitesScreen.assertTopSiteExists(named: "Example Domain")
        topSitesScreen.assertTopSitePinned(named: "Example Domain")

        // Remove pin
        topSitesScreen.longPressOnPinnedSite(named: "Example Domain")
        topSitesScreen.tapPinSlashIcon()
        topSitesScreen.assertTopSiteNotPinned(named: "Example Domain")
        topSitesScreen.assertTopSiteDoesNotExist(named: "Example Domain")
    }

    func testPinToShortcuts_andThenRemovingShortcuts() {
        navigator.openURL(path(forTestPage: "test-example.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenuMore)
        navigator.performAction(Action.PinToTopSitesPAM)
        navigator.nowAt(BrowserTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        if iPad() {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }

        let itemCell = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        let shortcutCell = itemCell.staticTexts["Example Domain"]
        mozWaitForElementToExist(shortcutCell)
        if #available(iOS 17, *) {
            mozWaitForElementToExist(app.links["Pinned: Example Domain"].images[StandardImageIdentifiers.Large.pinFill])
        } else {
            // No identifier is available for iOS 17 amd below
            mozWaitForElementToExist(app.links["Pinned: Example Domain"].images.element(boundBy: 1))
        }

        let pinnedShortcutCell = app.collectionViews.links["Pinned: Example Domain"]
        pinnedShortcutCell.press(forDuration: 2)
        app.tables.cells.buttons[StandardImageIdentifiers.Large.cross].waitAndTap()

        mozWaitForElementToNotExist(pinnedShortcutCell)
        mozWaitForElementToNotExist(shortcutCell)
    }

    private func openNewShareSheet_TAE() {
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL("example.com")
        waitUntilPageLoad()
        toolBarScreen.tapShareButton()
        photonActionSheetScreen.assertPhotonActionSheetExists()
        photonActionSheetScreen.tapFennecIcon()
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
            fennecElement = app.collectionViews.scrollViews.cells
                .matching(identifier: "XCElementSnapshotPrivilegedValuePlaceholder").element(boundBy: 1)
        }
        fennecElement.waitAndTap()
        mozWaitForElementToExist(app.navigationBars["ShareTo.ShareView"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306841
    // Smoketest
    func testSharePageWithShareSheetOptions() throws {
        try XCTSkipIf(
            isFirefoxBeta || isFirefox,
            "Skipping test because Firefox and FirefoxBeta are not yet supported"
        )
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306841
    // Smoketest TAE
    func testSharePageWithShareSheetOptions_TAE() {
        app.launch()
        openNewShareSheet_TAE()
        photonActionSheetScreen.assertShareViewExists()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2323203
    func testShareSheetSendToDevice() {
        openNewShareSheet()
        var attempts = 2
        let sendToDeviceButton = app.staticTexts["Send to Device"]
        while sendToDeviceButton.isVisible() && attempts > 0 {
            sendToDeviceButton.waitAndTap()
            waitForNoExistence(sendToDeviceButton)
            attempts -= 1
        }
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
