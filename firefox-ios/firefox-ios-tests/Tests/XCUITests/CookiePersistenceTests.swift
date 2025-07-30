// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class CookiePersistenceTests: BaseTestCase {
    let cookieSiteURL = "http://localhost:\(serverPort)/test-fixture/test-cookie-store.html"
    let topSitesTitle = ["Facebook", "YouTube", "Wikipedia"]

    override func setUp() {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if #available(iOS 17, *) {
            removeApp()
        }

        // The app is correctly installed
        super.setUp()
    }

    func testCookiePersistenceBasic() {
        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Relaunch app
        relaunchApp()

        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
    }

    func testCookiePersistence_OpenNewTab() {
        // Open URL for Cookie login
        openCookieSite()
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
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
        navigator.nowAt(NewTabScreen)
        openCookieSite()
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
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
    }

    private func typeOnSearchBar(text: String) {
        let urlBar = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        urlBar.waitAndTap()
        urlBar.tapAndTypeText(text)
    }
}
