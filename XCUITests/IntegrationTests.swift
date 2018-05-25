/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let testingURL = "example.com"

class IntegrationTests: BaseTestCase {

    let testWithDB = ["testFxASyncHistory"]

    // This DB contains 1 entry example.com
    let historyDB = "exampleURL.db"

    override func setUp() {
     // Test name looks like: "[Class testFunc]", parse out the function name
     let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
     let key = String(parts[1])
     if testWithDB.contains(key) {
     // for the current test name, add the db fixture used
     launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.StageServer, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + historyDB]
     }
     super.setUp()
     }

    func allowNotifications () {
        addUIInterruptionMonitor(withDescription: "notifications") { (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        sleep(5)
        app.swipeDown()
    }

    private func bookmark() {
        navigator.goto(PageOptionsMenu)
        waitforExistence(app.tables.cells["Bookmark This Page"])
        app.tables.cells["Bookmark This Page"].tap()
        navigator.nowAt(BrowserTab)
    }

    private func signInFxAccounts() {
        navigator.goto(FxASigninScreen)
        waitforExistence(app.webViews.staticTexts["Sign in"], timeout: 10)
        userState.fxaUsername = ProcessInfo.processInfo.environment["FXA_EMAIL"]!
        userState.fxaPassword = ProcessInfo.processInfo.environment["FXA_PASSWORD"]!
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        allowNotifications()
    }

    private func waitForInitialSyncComplete() {
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        waitforExistence(app.tables.staticTexts["Sync Now"], timeout: 10)
    }

    func testFxASyncHistory () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Firefox Accounts
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncBookmark () {
        // Go to a webpage, and add to bookmarks
        navigator.createNewTab()
        loadWebPage(testingURL)
        navigator.nowAt(BrowserTab)
        bookmark()

        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }
}
