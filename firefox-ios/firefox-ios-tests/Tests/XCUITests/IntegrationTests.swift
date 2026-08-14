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
    var browserScreen: BrowserScreen!

    let testWithDB = ["testFxASyncHistory", "testFxAFirefoxSuggest"]
    let testFxAChinaServer = ["testFxASyncPageUsingChinaFxA"]

    // This DB contains 1 entry example.com
    let historyDB = "exampleURLHistoryBookmark-places.db"

    override func setUp() async throws {
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
        } else {
            launchArguments.append(LaunchArguments.StageServer)
        }
        launchArguments.append(LaunchArguments.DisableAnimations)
        launchArguments.append("\(LaunchArguments.ServerPort)\(serverPort)")
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    func allowNotifications() {
        addUIInterruptionMonitor(withDescription: "notifications") { (alert) -> Bool in
            alert.buttons["Allow"].waitAndTap()
            return true
        }
        sleep(5)
    }

    private func signInFxAccounts() {
        navigator.goto(BrowserTabMenu)
        navigator.goto(Intro_FxASignin)
        navigator.performAction(Action.OpenEmailToSignIn)
        sleep(5)
        mozWaitForElementToExist(
            app.navigationBars[AccessibilityIdentifiers.Settings.FirefoxAccount.fxaNavigationBar],
            timeout: TIMEOUT_LONG
        )
        userState.fxaUsername = ProcessInfo.processInfo.environment["FXA_EMAIL"]!
        userState.fxaPassword = ProcessInfo.processInfo.environment["FXA_PASSWORD"]!
        mozWaitForElementToExist(app.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField])
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnContinueButton)
        mozWaitForElementToNotExist(app.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField])
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
        navigator.goto(BrowserTabMenu)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.staticTexts["ACCOUNT"], timeout: TIMEOUT_LONG)
        mozWaitForElementToNotExist(app.staticTexts["Sync and Save Data"])
        sleep(5)
        if app.tables.staticTexts["Sync is offline"].exists {
            app.tables.staticTexts["Sync is offline"].waitAndTap()
        }
        if app.tables.staticTexts["Sync Now"].exists {
            app.tables.staticTexts["Sync Now"].waitAndTap()
        }
        mozWaitForElementToNotExist(app.tables.staticTexts["Syncing…"])
        mozWaitForElementToExist(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncHistory() {
        // History is generated using the DB so go directly to Sign in
        // Sign into Mozilla Account
        navigator.goto(BrowserTabMenu)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3895156
    func testFxASyncPageUsingChinaFxA() {
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncBookmark() {
        waitForTabsButton()
        navigator.nowAt(HomePanelsScreen)
        // Bookmark is added by the DB
        // Sign into Mozilla Account
        navigator.openURL(testingURL)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon])
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.Bookmark)
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncBookmarkDesktop() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"].cells.staticTexts[TestLabels.exampleDomain])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncTabs() {
        signInFxAccounts()

        // We only sync tabs if the user is signed in
        navigator.nowAt(HomePanelsScreen)
        waitForTabsButton()
        navigator.openURL(testingURL)
        waitUntilPageLoad()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        // This is only to check that the device's name changed
        navigator.goto(SettingsScreen)
        app.tables.cells.element(boundBy: 1).waitAndTap()
        mozWaitForElementToExist(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"])
        XCTAssertEqual(
            app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"].value! as? String,
            "Fennec (admin) on iOS"
        )

        // Sync again just to make sure to sync after new name is shown
        app.buttons["Settings"].waitAndTap()
        navigator.nowAt(SettingsScreen)
        navigator.goto(BrowserTab)
        waitForInitialSyncComplete()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncLogins() {
        waitForTabsButton()
        navigator.nowAt(HomePanelsScreen)
        navigator.openURL("gmail.com")
        waitUntilPageLoad()

        // Log in in order to save it
        app.webViews.textFields["Email or phone"].tapAndTypeText(userName)
        app.webViews.buttons["Next"].waitAndTap()
        app.webViews.secureTextFields["Password"].tapAndTypeText(userPassword)

        app.webViews.buttons["Sign in"].waitAndTap()

        // Save the login
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.saveButton].waitAndTap()

        // Sign in with FxAccount
        signInFxAccounts()
        // Wait for initial sync to complete
        waitForInitialSyncComplete()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncHistoryDesktop() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced History
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables.cells.staticTexts[historyItemSavedOnDesktop])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncPasswordDesktop() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Logins
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.buttons.firstMatch)
        app.scrollViews.buttons["Continue"].waitAndTap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tapAndTypeText("foo\n")

        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertTrue(app.tables.cells.staticTexts[loginEntry].exists, "The login saved on desktop is not synced")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306819
    func testFxASyncTabsDesktop() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()

        // Check synced Tabs
        app.buttons["Done"].waitAndTap()
        navigator.nowAt(HomePanelsScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.ToggleExperimentSyncMode)

        // Need to swipe to get the data on the screen on focus
        app.swipeDown()
        mozWaitForElementToExist(app.tables.otherElements["profile1"])
        XCTAssertTrue(app.tables.staticTexts[tabOpenInDesktop].exists, "The tab is not synced")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2576803
    // [Config] orientation:portrait, orientation:landscape 
    // Smoketest
    func testFxATabsFirefoxSuggest() {
        // Precondition: Sign into Mozilla Account
        signInFxAccounts()
        waitForInitialSyncComplete()
        navigator.nowAt(SettingsScreen)
        // navigator.goto(HomePanelsScreen)

        // Create an open Tab
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        waitForTabsButton()
        navigator.openURL("localhost:\(serverPort)/test-fixture/\(TestPages.mozillaOrg)")
        waitUntilPageLoad()
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Create some history
        navigator.openNewURL(urlString: "https://www.iana.org/")
        waitUntilPageLoad()
        navigator.performAction(Action.CloseTab)

        // Create a bookmark
        navigator.openNewURL(urlString: "localhost:\(serverPort)/test-fixture/\(TestPages.mozillaBook)")
        waitUntilPageLoad()
        navigator.performAction(Action.Bookmark)
        navigator.performAction(Action.CloseTab)
        navigator.performAction(Action.OpenNewTabFromTabTray)

        // Firefox Suggest and Google Search
        // Synced tab: example.com/
        let siteTable = app.tables["SiteTable"]
        for orientation in [UIDeviceOrientation.portrait, UIDeviceOrientation.landscapeLeft] {
            XCUIDevice.shared.orientation = orientation
            sleep(1)
            waitForTabsButton()

            // Firefox Suggest should show up for sponsored suggestion, open tab, history
            // and bookmark.
            let firefoxSuggestTerms = [
                // Known bug: Sponsored suggestion not showing up when logged in to
                // Mozilla Account.
                // https://github.com/mozilla-mobile/firefox-ios/issues/35171
                // "amazon": "Amazon.com - Official Site", // Sponsored suggestion
                "internet": "Internet for people, not profit — Mozilla", // Open tab
                "iana": "www.iana.org/", // History
                "book": "The Book of Mozilla", // Bookmark
                "exam": "Example Domain" // synced tab
            ]
            for (term, expectedTitle) in firefoxSuggestTerms {
                browserScreen.tapOnAddressBar()
                browserScreen.tapClearButtonIfExists()
                browserScreen.typeOnSearchBar(text: term)
                mozWaitForElementToExist(app.scrollViews.buttons["Search Settings"])
                print(app.debugDescription)
                mozWaitForElementToExist(siteTable.staticTexts[expectedTitle])
                let searchEngines = [
                    "Bing search", "DuckDuckGo search", "Perplexity search", "Wikipedia (en) search", "eBay search"
                ]
                for searchEngine in searchEngines {
                    mozWaitForElementToExist(app.scrollViews.buttons[searchEngine])
                }
                // Search engine suggestions
                mozWaitForElementToExist(siteTable.otherElements["Google Search"])
                mozWaitForElementToExist(siteTable.staticTexts[term])

                // Firefox Suggest is displayed
                if XCUIDevice.shared.orientation == UIDeviceOrientation.landscapeLeft {
                    siteTable.cells.firstMatch.swipeUp()
                }
                mozWaitForElementToExist(siteTable.otherElements["Firefox Suggest"])
                mozWaitForElementToExist(siteTable.staticTexts[expectedTitle])
            }

            // Non Firefox Suggest result: A random term
            let term = "heeeeeeellllllllllloooooooo"
            browserScreen.tapOnAddressBar()
            browserScreen.tapClearButtonIfExists()
            browserScreen.typeOnSearchBar(text: term)
            mozWaitForElementToExist(app.scrollViews.buttons["Search Settings"])
            let searchEngines = [
                "Bing search", "DuckDuckGo search", "Perplexity search", "Wikipedia (en) search", "eBay search"
            ]
            for searchEngine in searchEngines {
                mozWaitForElementToExist(app.scrollViews.buttons[searchEngine])
            }
            // Search engine suggestions
            mozWaitForElementToExist(siteTable.otherElements["Google Search"])
            mozWaitForElementToExist(siteTable.staticTexts[term])
            mozWaitForElementToNotExist(siteTable.otherElements["Firefox Suggest"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306822
    func testFxADisconnectConnect() {
        // Sign into Mozilla Account
        signInFxAccounts()

        // Wait for initial sync to complete
        waitForInitialSyncComplete()
        navigator.nowAt(SettingsScreen)
        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        mozWaitForElementToExist(app.tables["Bookmarks List"].cells.staticTexts[TestLabels.exampleDomain])

        // Check Login
        navigator.performAction(Action.CloseBookmarkPanel)
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowserTabMenu)

        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        navigator.goto(LoginsSettings)
        mozWaitForElementToExist(app.buttons.firstMatch)
        app.scrollViews.buttons["Continue"].waitAndTap()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let passcodeInput = springboard.secureTextFields["Passcode field"]
        passcodeInput.tapAndTypeText("foo\n")

        mozWaitForElementToExist(app.tables["Login List"])
        // Verify the login
        mozWaitForElementToExist(app.staticTexts["https://accounts.google.com"])

        // Disconnect account
        navigator.goto(SettingsScreen)
        app.tables.cells.element(boundBy: 1).waitAndTap()
        mozWaitForElementToExist(app.cells["DeviceNameSetting"].textFields["DeviceNameSettingTextField"])

        app.cells["SignOut"].waitAndTap()

        app.buttons["Disconnect"].waitAndTap()
        sleep(3)

        // Connect same account again
        navigator.nowAt(SettingsScreen)
        app.tables.cells["SignInToSync"].waitAndTap()
        app.buttons["EmailSignIn.button"].waitAndTap()

        navigator.nowAt(FxASigninScreen)
        mozWaitForElementToExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)
        navigator.performAction(Action.FxATypePasswordExistingAccount)
        navigator.performAction(Action.FxATapOnSignInButton)
        mozWaitForElementToNotExist(app.staticTexts["Enter your password"], timeout: TIMEOUT_LONG)

        navigator.nowAt(SettingsScreen)
        app.swipeDown()
        mozWaitForElementToExist(app.staticTexts["GENERAL"])
        mozWaitForElementToExist(app.staticTexts["ACCOUNT"])
        mozWaitForElementToExist(app.tables.staticTexts["Sync Now"], timeout: TIMEOUT_LONG)

        // Check Bookmarks
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables["Bookmarks List"].cells.staticTexts[TestLabels.exampleDomain])

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
