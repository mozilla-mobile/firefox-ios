// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class LoginPersistenceUITests: BaseTestCase {
    override func setUp() {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if name.contains("testLoginFreshInstallMessage") {
            if #available(iOS 17, *) {
                removeApp()
            }
        }
        // The app is correctly installed
        super.setUp()
    }

    func testCookiePersistence() {
        // Open URL for Cookie login
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/test-cookie-store.html")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        let webview = app.webViews.firstMatch
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])

        mozWaitForElementToExist(webview.staticTexts["LOGGED_OUT"])

        // Tap on Log in
        webview.buttons["Login"].waitAndTap()

        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])

        // Restart the app
        app.terminate()

        // Wait a moment if needed (optional but sometimes helpful)
        sleep(1)

        // Launch it again
        app.launch()

        navigator.openURL("http://localhost:\(serverPort)/test-fixture/test-cookie-store.html")
        waitUntilPageLoad()
        navigator.nowAt(BrowserTab)
        mozWaitForElementToExist(webview.staticTexts["Cookie Test Page"])
        mozWaitForElementToExist(webview.staticTexts["LOGGED_IN"])
    }
}
