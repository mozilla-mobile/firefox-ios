// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

final class CookiePersistenceTests: BaseTestCase {
    private var browserScreen: BrowserScreen!
    private var toolbarScreen: ToolbarScreen!
    private var tabTrayScreen: TabTrayScreen!

    let cookieSiteURL = "http://localhost:\(serverPort)/test-fixture/\(TestPages.cookieStore)"
    let topSitesTitle = ["Facebook", "YouTube", "Wikipedia"]

    override func setUp() async throws {
        // Start each test with a clean WKWebView cookie store (ClearProfile alone doesn't clear it)
        // instead of relying on a fragile fresh install via removeApp().
        launchArguments.append(LaunchArguments.ClearWebData)
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
        toolbarScreen.tapOnTabsButton()
        tabTrayScreen.switchToPrivateBrowsing()
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
        app.terminate()
        _ = app.wait(for: .notRunning, timeout: TIMEOUT)
        // Relaunch without ClearWebData so the web cookie store persists — this is what the test verifies.
        app.launchArguments = app.launchArguments.filter { $0 != LaunchArguments.ClearWebData }
        app.launch()
    }

    private func openCookieSite() {
        browserScreen.navigateToURL(cookieSiteURL)
        waitUntilPageLoad()
        browserScreen.assertCookiePageLoaded()
    }
}
