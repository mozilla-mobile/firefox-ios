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

    private func openNewShareSheet() {
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(URLBarOpen)
        navigator.openURL("example.com")
        waitUntilPageLoad()
        browserScreen.waitForClipboardToastToDisappear()
        toolBarScreen.tapShareButton()
        photonActionSheetScreen.assertPhotonActionSheetExists()
        photonActionSheetScreen.tapFennecIcon()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306849
    // Smoketest
    func testPinToShortcuts() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306841
    // Smoketest
    func testSharePageWithShareSheetOptions() throws {
        try XCTSkipIf(
            isFirefoxBeta || isFirefox,
            "Skipping test because Firefox and FirefoxBeta are not yet supported"
        )
        app.launch()
        openNewShareSheet()
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
