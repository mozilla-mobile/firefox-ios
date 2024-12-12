// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared

private let testingURL = "https://example.com"
private let userName = "iosmztest"
private let userPassword = "test15mz"
private let historyItemSavedOnDesktop = "https://www.example.com/"
private let loginEntry = "https://accounts.google.com"
private let tabOpenInDesktop = "https://example.com/"

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
                        LaunchArguments.SkipContextualHints]
     } else if testFxAChinaServer.contains(key) {
        launchArguments = [LaunchArguments.SkipIntro,
                           LaunchArguments.FxAChinaServer,
                           LaunchArguments.SkipWhatsNew,
                           LaunchArguments.SkipETPCoverSheet,
                           LaunchArguments.SkipContextualHints]
     }
    launchArguments.append(LaunchArguments.DisableAnimations)
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
        mozWaitForElementToExist(
            app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar],
            timeout: TIMEOUT_LONG
        )
        mozWaitForElementToExist(app.staticTexts["Continue to your Mozilla account"], timeout: TIMEOUT_LONG)
        userState.fxaUsername = ProcessInfo.processInfo.environment["FXA_EMAIL"]!
        userState.fxaPassword = ProcessInfo.processInfo.environment["FXA_PASSWORD"]!
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        mozWaitForElementToExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)
        navigator.performAction(Action.FxATypePasswordExistingAccount)
        navigator.performAction(Action.FxATapOnSignInButton)
        mozWaitForElementToNotExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)
        waitForTabsButton()
        allowNotifications()
    }

    private func waitForInitialSyncComplete() {
        navigator.nowAt(BrowserTab)
        waitForTabsButton()
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.staticTexts["ACCOUNT"], timeout: TIMEOUT_LONG)
        mozWaitForElementToNotExist(app.staticTexts["Sync and Save Data"])
        sleep(5)
        if app.tables.staticTexts["Sync is offline"].exists {
            app.tables.staticTexts["Sync is offline"].tap()
        }
        if app.tables.staticTexts["Sync Now"].exists {
            app.tables.staticTexts["Sync Now"].tap()
        }
        mozWaitForElementToNotExist(app.tables.staticTexts["Syncing…"])
        mozWaitForElementToExist(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)
    }

    func testFxASyncHistory () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Mozilla Account
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncPageUsingChinaFxA () {
        // History is generated using the DB so go directly to Sign in
        // Sign into Mozilla Account
        navigator.goto(BrowserTabMenu)
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)

        mozWaitForElementToExist(
            app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar],
            timeout: TIMEOUT_LONG
        )
    }

    func testFxASyncBookmark () {
        // Bookmark is added by the DB
        // Sign into Mozilla Account
        navigator.openURL(testingURL)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon])
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.Bookmark)
        navigator.nowAt(BrowserTab)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncBookmarkDesktop () {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"])
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
        app.tables.cells.element(boundBy: 1).waitAndTap()
        mozWaitForElementToExist(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"])
        XCTAssertEqual(
            app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"].value! as? String,
            "Fennec (administrator) on iOS"
        )

        // Sync again just to make sure to sync after new name is shown
        app.buttons["Settings"].tap()
        mozWaitForElementToExist(app.staticTexts["ACCOUNT"])
        app.tables.cells.element(boundBy: 2).tap()
        mozWaitForElementToExist(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)
    }

    func testFxASyncLogins () {
        navigator.openURL("gmail.com")
        waitUntilPageLoad()

        // Log in in order to save it
        app.webViews.textFields["Email or phone"].tapAndTypeText(userName)
        app.webViews.buttons["Next"].tap()
        app.webViews.secureTextFields["Password"].tapAndTypeText(userPassword)

        app.webViews.buttons["Sign in"].tap()

        // Save the login
        app.buttons["SaveLoginPrompt.saveLoginButton"].waitAndTap()

        // Sign in with FxAccount
        signInFxAccounts()
        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    func testFxASyncHistoryDesktop () {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced History
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables.cells.staticTexts[historyItemSavedOnDesktop])
    }

    func testFxASyncPasswordDesktop () {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Logins
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.buttons.firstMatch)
        app.scrollViews.buttons["Continue"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tapAndTypeText("foo\n")

        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertTrue(app.tables.cells.staticTexts[loginEntry].exists, "The login saved on desktop is not synced")
    }

    func testFxASyncTabsDesktop () {
        // Sign into Mozilla Account
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
        mozWaitForElementToExist(app.tables.otherElements["profile1"])
        XCTAssertTrue(app.tables.staticTexts[tabOpenInDesktop].exists, "The tab is not synced")
    }

    func testFxADisconnectConnect() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.nowAt(SettingsScreen)
        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        waitForElementsToExist(
            [
                app.tables["Bookmarks List"],
                app.tables["Bookmarks List"].cells.staticTexts["Example Domain"]
            ]
        )

        // Check Login
        navigator.performAction(Action.CloseBookmarkPanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)

        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.buttons.firstMatch)
        app.scrollViews.buttons["Continue"].tap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tapAndTypeText("foo\n")

        mozWaitForElementToExist(app.tables["Login List"])
        // Verify the login
        mozWaitForElementToExist(app.staticTexts["https://accounts.google.com"])

        // Disconnect account
        navigator.goto(SettingsScreen)
        app.tables.cells.element(boundBy: 1).tap()
        mozWaitForElementToExist(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"])

        app.cells["SignOut"].tap()

        app.buttons["Disconnect"].waitAndTap()
        sleep(3)

        // Connect same account again
        navigator.nowAt(SettingsScreen)
        app.tables.cells["SignInToSync"].tap()
        app.buttons["EmailSignIn.button"].tap()

        navigator.nowAt(FxASigninScreen)
        mozWaitForElementToExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)
        navigator.performAction(Action.FxATypePasswordExistingAccount)
        navigator.performAction(Action.FxATapOnSignInButton)
        mozWaitForElementToNotExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)

        navigator.nowAt(SettingsScreen)
        mozWaitForElementToExist(app.staticTexts["GENERAL"])
        app.swipeDown()
        mozWaitForElementToExist(app.staticTexts["ACCOUNT"])
        mozWaitForElementToExist(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)

        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"].cells.staticTexts["Example Domain"])

        // Check Logins
        navigator.performAction(Action.CloseBookmarkPanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        navigator.goto(LoginsSettings)

        passcodeInput.tapAndTypeText("foo\n")

        waitForElementsToExist(
            [
                app.tables["Login List"],
                app.staticTexts["https://accounts.google.com"]
            ]
        )
    }
}
