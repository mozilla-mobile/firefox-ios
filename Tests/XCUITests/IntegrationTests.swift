// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
    let historyDB = "exampleURLHistoryBookmark-places.db"

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
        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: TIMEOUT_LONG)
        waitForExistence(app.staticTexts["Continue to Firefox accounts"], timeout: TIMEOUT_LONG)
        userState.fxaUsername = ProcessInfo.processInfo.environment["FXA_EMAIL"]!
        userState.fxaPassword = ProcessInfo.processInfo.environment["FXA_PASSWORD"]!
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        sleep(3)
        waitForTabsButton()
        allowNotifications()
    }

    private func waitForInitialSyncComplete() {
        navigator.nowAt(BrowserTab)
        navigator.goto(SettingsScreen)
        waitForExistence(app.staticTexts["FIREFOX ACCOUNT"], timeout: TIMEOUT_LONG)
        waitForNoExistence(app.staticTexts["Sync and Save Data"])
        sleep(5)
        if app.tables.staticTexts["Sync Now"].exists {
            app.tables.staticTexts["Sync Now"].tap()
        }
        waitForNoExistence(app.tables.staticTexts["Syncing…"])
        waitForExistence(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)
    }

    func testFxASyncHistory () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Firefox Accounts
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncPageUsingChinaFxA () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Firefox Accounts
        navigator.goto(BrowserTabMenu)
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)

        waitForExistence(app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar], timeout: TIMEOUT_LONG)
        waitForExistence(app.webViews.staticTexts["Continue to Firefox accounts"], timeout: TIMEOUT_LONG)
        waitForExistence(app.webViews.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField])
        waitForExistence(app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.continueButton])
    }

    func testFxASyncBookmark () {
        // Bookmark is added by the DB
        // Sign into Firefox Accounts
        navigator.openURL("example.com")
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.trackingProtection], timeout: 5)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.bookmark], timeout: 15)
        app.tables.otherElements[StandardImageIdentifiers.Large.bookmark].tap()
        navigator.nowAt(BrowserTab)
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
        waitForExistence(app.staticTexts["FIREFOX ACCOUNT"], timeout: TIMEOUT)
        app.tables.cells.element(boundBy: 2).tap()
        waitForExistence(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)
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
        // Sign into Firefox Accounts
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced History
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables.cells.staticTexts[historyItemSavedOnDesktop], timeout: 5)
    }

    func testFxASyncPasswordDesktop () {
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
        waitForExistence(app.tables.otherElements["profile1"], timeout: TIMEOUT)
        XCTAssertTrue(app.tables.staticTexts[tabOpenInDesktop].exists, "The tab is not synced")
    }

    func testFxADisconnectConnect() {
        // Sign into Firefox Accounts
        signInFxAccounts()

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
        waitForExistence(app.staticTexts["GENERAL"])
        app.swipeDown()
        waitForExistence(app.staticTexts["FIREFOX ACCOUNT"], timeout: TIMEOUT)
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
