// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class CookiePersistenceTests: BaseTestCase {
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!

    let cookieSiteURL = "http://localhost:\(serverPort)/test-fixture/test-cookie-store.html"
    let topSitesTitle = ["Facebook", "YouTube", "Wikipedia"]

    override func setUp() async throws {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if #available(iOS 17, *) {
            removeApp()
        }

        // The app is correctly installed
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
        toolbarScreen = ToolbarScreen(app: app)
        tabTrayScreen = TabTrayScreen(app: app)
    }

    func testCookiePersistenceBasic() {
        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Relaunch app
        relaunchApp()

        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
    }

    func testCookiePersistenceOpenNewTab() {
        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Open a few tabs
        topSitesTitle.forEach { title in
            toolbarScreen.openNewTabFromTabTray()
            app.collectionViews.links.staticTexts[title].waitAndTap()
            waitUntilPageLoad()
        }

        // Relaunch app
        relaunchApp()

        // Open a new tab for cookie website and check login status
        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
    }

    func testCookiePersistenceOpenRegularTabAfterPrivateTab() {
        // Go to private tab
        toolbarScreen.switchToPrivateBrowsing()
        tabTrayScreen.tapOnNewTabButton()

        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Open regular tabs
        // navigate to website and expect not to be login
        toolbarScreen.tapOnTabsButton()
        mozWaitForElementToExist(app.buttons["Private"])
        if iPad() {
            app.segmentedControls.buttons.firstMatch.waitAndTap()
        } else {
            app.buttons["Tabs"].tap()
        }
        tabTrayScreen.tapOnNewTabButton()

        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])
    }

    private func relaunchApp() {
        // Restart the app
        app.terminate()

        // Wait a moment if needed (optional but sometimes helpful)
        _ = app.wait(for: .notRunning, timeout: TIMEOUT)

        // Launch it again
        app.launch()
    }

    private func openCookieSite() {
        browserScreen.navigateToURL(cookieSiteURL)
        waitUntilPageLoad()
        browserScreen.assertCookiePageLoaded()
    }
}
