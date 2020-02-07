/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

private let testingURL = "example.com"
private let userName = "iosmztest"
private let userPassword = "test15mz"
private let historyItemSavedOnDesktop = "http://www.example.com/"
private let loginEntry = "https://accounts.google.com"
private let tabOpenInDesktop = "http://example.com/"

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
        Base.app.swipeDown()
    }

    private func signInFxAccounts() {
        navigator.goto(FxASigninScreen)
        sleep(5)
        Base.helper.waitForExistence(Base.app.navigationBars["Client.FxAContentView"], timeout: 20)
        userState.fxaUsername = ProcessInfo.processInfo.environment["FXA_EMAIL"]!
        userState.fxaPassword = ProcessInfo.processInfo.environment["FXA_PASSWORD"]!
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        sleep(3)
        allowNotifications()
    }

    private func waitForInitialSyncComplete() {
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        Base.helper.waitForExistence(Base.app.tables.staticTexts["Sync Now"], timeout: 15)
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

    func testFxASyncBookmarkDesktop () {
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.goto(LibraryPanel_Bookmarks)
        Base.helper.waitForExistence(Base.app.tables["Bookmarks List"].cells.staticTexts["Example Domain"], timeout: 5)
    }

    func testFxASyncTabs () {
        navigator.openURL(testingURL)
        Base.helper.waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        navigator.nowAt(BrowserTab)
        // This is only to check that the device's name changed
        navigator.goto(SettingsScreen)
        Base.app.tables.cells.element(boundBy: 0).tap()
        Base.helper.waitForExistence(Base.app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"], timeout: 10)
        XCTAssertEqual(Base.app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"].value! as! String, "Fennec (synctesting) on iOS")

        // Sync again just to make sure to sync after new name is shown
        Base.app.buttons["Settings"].tap()
        Base.app.tables.cells.element(boundBy: 1).tap()
        Base.helper.waitForExistence(Base.app.tables.staticTexts["Sync Now"], timeout: 15)
    }

    func testFxASyncLogins () {
        navigator.openURL("gmail.com")
        Base.helper.waitUntilPageLoad()

        // Log in in order to save it
        Base.helper.waitForExistence(Base.app.webViews.textFields["Email or phone"])
        Base.app.webViews.textFields["Email or phone"].tap()
        Base.app.webViews.textFields["Email or phone"].typeText(userName)
        Base.app.webViews.buttons["Next"].tap()
        Base.helper.waitForExistence(Base.app.webViews.secureTextFields["Password"])
        Base.app.webViews.secureTextFields["Password"].tap()
        Base.app.webViews.secureTextFields["Password"].typeText(userPassword)

        Base.app.webViews.buttons["Sign in"].tap()

        // Save the login
        Base.helper.waitForExistence(Base.app.buttons["SaveLoginPrompt.saveLoginButton"])
        Base.app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Sign in with FxAccount
        signInFxAccounts()
        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncHistoryDesktop () {
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced History
        navigator.goto(LibraryPanel_History)
        Base.helper.waitForExistence(Base.app.tables.cells.staticTexts[historyItemSavedOnDesktop], timeout: 5)
    }

    func testFxASyncPasswordDesktop () {
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Logins
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"], timeout: 5)
        XCTAssertTrue(Base.app.tables.cells.staticTexts[loginEntry].exists, "The login saved on desktop is not synced")
    }

    func testFxASyncTabsDesktop () {
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Tabs
        navigator.goto(LibraryPanel_History)
        Base.helper.waitForExistence(Base.app.cells["HistoryPanel.syncedDevicesCell"], timeout: 5)
        Base.app.cells["HistoryPanel.syncedDevicesCell"].tap()
        // Need to swipe to get the data on the screen on focus
        Base.app.swipeDown()
        Base.helper.waitForExistence(Base.app.tables.otherElements["profile1"], timeout: 10)
        XCTAssertTrue(Base.app.tables.staticTexts[tabOpenInDesktop].exists, "The tab is not synced")
    }
}
