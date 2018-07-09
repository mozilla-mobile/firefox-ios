/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let testingURL = "example.com"
private let userName = "iosmztest"
private let userPassword = "test15mz"

class IntegrationTests: BaseTestCase {

    let testWithDB = ["testFxASyncHistory", "testFxASyncBookmark"]

    // This DB contains 1 entry example.com
    let historyDB = "exampleURLHistoryBookmark.db"

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
        // Bookmark is added by the DB
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncTabs () {
        navigator.openURL(testingURL)
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        navigator.nowAt(BrowserTab)
        // This is only to check that the device's name changed
        navigator.goto(SettingsScreen)
        app.tables.cells.element(boundBy: 0).tap()
        waitforExistence(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"])
        XCTAssertEqual(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"].value! as! String, "Fennec on iOS")

        // Sync again just to make sure to sync after new name is shown
        app.buttons["Settings"].tap()
        app.tables.cells.element(boundBy: 1).tap()
        waitforExistence(app.tables.staticTexts["Sync Now"], timeout: 15)
    }

    func testFxASyncLogins () {
        navigator.openURL("gmail.com")
        waitUntilPageLoad()

        // Log in in order to save it
        waitforExistence(app.webViews.textFields["Email or phone"])
        app.webViews.textFields["Email or phone"].tap()
        app.webViews.textFields["Email or phone"].typeText(userName)
        app.webViews.buttons["Next"].tap()
        waitforExistence(app.webViews.secureTextFields["Password"])
        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText(userPassword)

        app.webViews.buttons["Sign in"].tap()

        // Save the login
        waitforExistence(app.buttons["SaveLoginPrompt.saveLoginButton"])
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Sig in with FxAccount
        signInFxAccounts()
        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }
}
