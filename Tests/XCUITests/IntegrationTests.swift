// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

private let testingURL = "example.com"
private let userName = "iosmztest"
private let userPassword = "test15mz"
private let historyItemSavedOnDesktop = "http://www.example.com/"
private let loginEntry = "https://accounts.google.com"
private let tabOpenInDesktop = "http://example.com/"

class IntegrationTests: BaseTestCase {

    let testWithDB = ["testFxASyncHistory"]
    let testFxAChinaServer = ["testFxASyncPageUsingChinaFxA"]

    // This DB contains 1 entry example.com
    let historyDB = "exampleURLHistoryBookmark.db"

    override func setUp() {
     // Test name looks like: "[Class testFunc]", parse out the function name
     let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
     let key = String(parts[1])
     if testWithDB.contains(key) {
     // for the current test name, add the db fixture used
     launchArguments = [LaunchArguments.SkipIntro,
                        LaunchArguments.StageServer,
                        LaunchArguments.SkipWhatsNew,
                        LaunchArguments.SkipETPCoverSheet,
                        LaunchArguments.LoadDatabasePrefix + historyDB,
                        LaunchArguments.SkipContextualHints,
                        LaunchArguments.TurnOffTabGroupsInUserPreferences]

     } else if testFxAChinaServer.contains(key) {
        launchArguments = [LaunchArguments.SkipIntro,
                           LaunchArguments.FxAChinaServer,
                           LaunchArguments.SkipWhatsNew,
                           LaunchArguments.SkipETPCoverSheet,
                           LaunchArguments.SkipContextualHints,
                           LaunchArguments.TurnOffTabGroupsInUserPreferences]
     }
     super.setUp()
     }

    func allowNotifications () {
        addUIInterruptionMonitor(withDescription: "notifications") { (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        app.swipeDown()
    }

    private func signInFxAccounts() {
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        sleep(5)
        waitForExistence(app.navigationBars["Turn on Sync"], timeout: 20)
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
        waitForExistence(app.tables.staticTexts["Sync Now"], timeout: 25)
    }

    func testFxASyncHistory () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Firefox Accounts
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncPageUsingChinaFxA () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Firefox Accounts
        app.buttons["urlBar-cancel"].tap()
        navigator.goto(BrowserTabMenu)
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        waitForExistence(app.navigationBars["Turn on Sync"], timeout: 20)
        waitForExistence(app.webViews.textFields["Email"], timeout: 20)

        // Wait for element not present on FxA sign in page China FxA server
        waitForNoExistence(app.webViews.otherElements.staticTexts["Firefox Monitor"])
        XCTAssertFalse(app.webViews.otherElements.staticTexts["Firefox Monitor"].exists)
    }

    func testFxASyncBookmark () {
        // Bookmark is added by the DB
        // Sign into Firefox Accounts
        app.buttons["urlBar-cancel"].tap()
        navigator.openURL("example.com")
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.trackingProtection], timeout: 5)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[ImageIdentifiers.addToBookmark], timeout: 15)
        app.tables.otherElements[ImageIdentifiers.addToBookmark].tap()
        navigator.nowAt(BrowserTab)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncBookmarkDesktop () {
        // Sign into Firefox Accounts
        app.buttons["urlBar-cancel"].tap()
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"], timeout: 5)
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
        waitForExistence(app.tables.cells.element(boundBy: 1), timeout: 10)
        app.tables.cells.element(boundBy: 1).tap()
        waitForExistence(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"], timeout: 10)
        XCTAssertEqual(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"].value! as! String, "Fennec (administrator) on iOS")

        // Sync again just to make sure to sync after new name is shown
        app.buttons["Settings"].tap()
        app.tables.cells.element(boundBy: 2).tap()
        waitForExistence(app.tables.staticTexts["Sync Now"], timeout: 15)
    }

    func testFxASyncLogins () {
        navigator.openURL("gmail.com")
        waitUntilPageLoad()

        // Log in in order to save it
        waitForExistence(app.webViews.textFields["Email or phone"])
        app.webViews.textFields["Email or phone"].tap()
        app.webViews.textFields["Email or phone"].typeText(userName)
        app.webViews.buttons["Next"].tap()
        waitForExistence(app.webViews.secureTextFields["Password"])
        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText(userPassword)

        app.webViews.buttons["Sign in"].tap()

        // Save the login
        waitForExistence(app.buttons["SaveLoginPrompt.saveLoginButton"])
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Sign in with FxAccount
        signInFxAccounts()
        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncHistoryDesktop () {
        app.buttons["urlBar-cancel"].tap()
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced History
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells.staticTexts[historyItemSavedOnDesktop], timeout: 5)
    }

    func testFxASyncPasswordDesktop () {
        app.buttons["urlBar-cancel"].tap()
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Logins
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        waitForExistence(app.buttons.firstMatch)
        app.buttons["Continue"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("foo\n")

        navigator.goto(LoginsSettings)
        waitForExistence(app.tables["Login List"], timeout: 5)
        XCTAssertTrue(app.tables.cells.staticTexts[loginEntry].exists, "The login saved on desktop is not synced")
    }

    func testFxASyncTabsDesktop () {
        app.buttons["urlBar-cancel"].tap()
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Tabs
        app.buttons["Done"].tap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleSyncMode)

        // Need to swipe to get the data on the screen on focus
        app.swipeDown()
        waitForExistence(app.tables.otherElements["profile1"], timeout: 10)
        XCTAssertTrue(app.tables.staticTexts[tabOpenInDesktop].exists, "The tab is not synced")
    }

    func testFxADisconnectConnect() {
        app.buttons["urlBar-cancel"].tap()
        // Sign into Firefox Accounts
        signInFxAccounts()
        sleep(3)

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.nowAt(SettingsScreen)
        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"], timeout: 3)
        waitForExistence(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"], timeout: 5)

        // Check Login
        navigator.performAction(Action.CloseBookmarkPanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)

        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        waitForExistence(app.buttons.firstMatch)
        app.buttons["Continue"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tap()
        passcodeInput.typeText("foo\n")

        waitForExistence(app.tables["Login List"], timeout: 3)
        // Verify the login
        waitForExistence(app.staticTexts["https://accounts.google.com"])

        // Disconnect account
        navigator.goto(SettingsScreen)
        app.tables.cells.element(boundBy: 1).tap()
        waitForExistence(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"], timeout: 10)

        app.cells["SignOut"].tap()

        waitForExistence(app.buttons["Disconnect"], timeout: 5)
        app.buttons["Disconnect"].tap()
        sleep(3)

        // Connect same account again
        navigator.nowAt(SettingsScreen)
        app.tables.cells["SignInToSync"].tap()
        app.buttons["EmailSignIn.button"].tap()

        waitForExistence(app.secureTextFields.element(boundBy: 0), timeout: 10)
        app.secureTextFields.element(boundBy: 0).tap()
        app.secureTextFields.element(boundBy: 0).typeText(userState.fxaPassword!)
        waitForExistence(app.webViews.buttons.element(boundBy: 0), timeout: 5)
        app.webViews.buttons.element(boundBy: 0).tap()

        navigator.nowAt(SettingsScreen)
        waitForExistence(app.tables.staticTexts["Sync Now"], timeout: 35)

        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"], timeout: 5)

        // Check Logins
        navigator.performAction(Action.CloseBookmarkPanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        navigator.goto(LoginsSettings)

        passcodeInput.tap()
        passcodeInput.typeText("foo\n")

        waitForExistence(app.tables["Login List"], timeout: 10)
        waitForExistence(app.staticTexts["https://accounts.google.com"], timeout: 10)
    }
}
