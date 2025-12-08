// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class CookiePersistenceTests: BaseTestCase {
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
            navigator.performAction(Action.OpenNewTabFromTabTray)
            navigator.nowAt(NewTabScreen)
            app.collectionViews.links.staticTexts[title].waitAndTap()
            waitUntilPageLoad()
            navigator.nowAt(BrowserTab)
        }

        // Relaunch app
        relaunchApp()

        // Open a new tab for cookie website and check login status
        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
    }

    func testCookiePersistenceOpenRegularTabAfterPrivateTab() {
        // Go to private tab
        navigator.toggleOn(userState.isPrivate, withAction: Action.ToggleExperimentPrivateMode)
        if userState.isPrivate {
            app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
            navigator.nowAt(BrowserTab)
        }

        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Open regular tabs
        // navigate to website and expect not to be login
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
        mozWaitForElementToExist(app.buttons["Private"])
        if iPad() {
            app.segmentedControls.buttons.firstMatch.waitAndTap()
        } else {
            app.buttons["Tabs"].tap()
        }
        app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()

        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])
    }

    private func relaunchApp() {
        // Restart the app
        app.terminate()

        // Wait a moment if needed (optional but sometimes helpful)
        sleep(1)

        // Launch it again
        app.launch()
    }

    private func openCookieSite() {
        navigator.openURL(path(forTestPage: "test-cookie-store.html"))
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
        mozWaitForElementToExist(webview.textFields.firstMatch)
        mozWaitForElementToExist(webview.buttons["Login"])
        mozWaitForElementToExist(webview.buttons["Logout"])
    }
}
