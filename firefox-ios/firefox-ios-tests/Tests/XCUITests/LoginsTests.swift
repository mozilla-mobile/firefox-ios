// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

let domain = "http://localhost:\(serverPort)"
let domainLogin = "test@example.com"
let domainSecondLogin = "test2@example.com"
let testLoginPage = path(forTestPage: "test-password.html")
let testSecondLoginPage = path(forTestPage: "test-password-2.html")
let savedLoginEntry = "test@example.com, http://localhost:\(serverPort)"
let urlLogin = path(forTestPage: "empty-login-form.html")
let mailLogin = "iosmztest@mailinator.com"
// The following seem to be labels that change a lot and make the tests
// break; aka volatile. Let's keep them in one place.
let loginsListURLLabel = "Website, \(domain)"
let loginsListUsernameLabel = "Username, test@example.com"
let loginsListUsernameLabelEdited = "Username, foo"
let loginsListPasswordLabel = "Password"
let loginsListPasswordLabelEdited = "Password, bar"
let defaultNumRowsLoginsList = 2
let defaultNumRowsEmptyFilterList = 0
let searchPasswords = "Search passwords"
let loginList = "Login List"

class LoginTest: BaseTestCase {
    var toolBarScreen: ToolbarScreen!
    var loginSettingsScreen: LoginSettingsScreen!
    var mainMenuScreen: MainMenuScreen!
    var settingsScreen: SettingScreen!
    var webFormScreen: WebFormScreen!
    var saveLoginAlertScreen: SaveLoginAlertScreen!

    override func setUp() async throws {
        // Fresh install the app
        // removeApp() does not work on iOS 15 and 16 intermittently
        if name.contains("testLoginFreshInstallMessage") {
            if #available(iOS 17, *) {
                removeApp()
            }
        }
        // The app is correctly installed
        try await super.setUp()
        toolBarScreen = ToolbarScreen(app: app)
        loginSettingsScreen = LoginSettingsScreen(app: app)
        mainMenuScreen = MainMenuScreen(app: app)
        settingsScreen = SettingScreen(app: app)
        webFormScreen = WebFormScreen(app: app)
        saveLoginAlertScreen = SaveLoginAlertScreen(app: app)
    }

    let passwordssQuery = AccessibilityIdentifiers.Settings.Logins.Passwords.self
    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        app.buttons["submit"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.saveButton].waitAndTap()
    }

    private func saveLogin_TAE(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        loginSettingsScreen.tapOnSubmitButton()
        loginSettingsScreen.tapOnSaveButton()
    }

    private func openLoginsSettings() {
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(SettingsScreen)
        let syncInToSync = AccessibilityIdentifiers.Settings.ConnectSetting.title.self
        mozWaitForElementToExist(app.cells[syncInToSync])
        app.cells[syncInToSync].swipeUp()
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        mozWaitForElementToExist(app.tables[loginList])
    }

    private func openLoginsSettings_TAE() {
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(SettingsScreen)
        settingsScreen.connectSettingSwipeUp()
        navigator.goto(LoginsSettings)

        loginSettingsScreen.unlockLoginsView()
        loginSettingsScreen.assertLoginListExist()
    }

    private func openLoginsSettingsFromBrowserTab() {
        waitForExistence(app.buttons["TabToolbar.menuButton"])
        navigator.goto(BrowserTabMenu)
        mozWaitForElementToExist(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings])
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        mozWaitForElementToExist(app.tables[loginList])
        navigator.nowAt(LoginsSettings)
    }

    private func openLoginsSettingsFromBrowserTab_TAE() {
        toolBarScreen.assertTabToolbarMenuExists()
        navigator.goto(BrowserTabMenu)
        mainMenuScreen.assertMainMenuSettingsExist()
        navigator.goto(LoginsSettings)

        loginSettingsScreen.unlockLoginsView()
        loginSettingsScreen.assertLoginListExist()
        navigator.nowAt(LoginsSettings)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306961
    func testLoginsListFromBrowserTabMenu() {
        closeURLBar()
        // Make sure you can access empty Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForElementsToExist(
            [
                app.tables[loginList],
                app.searchFields[searchPasswords]
            ]
        )
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList)
        navigator.goto(AutofillPasswordSettings)
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        saveLogin(givenUrl: testLoginPage)
        // Make sure you can access populated Login List from Browser Tab Menu
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            navigator.goto(BrowserTabMenu)
            app.swipeUp()
        }
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForElementsToExist(
            [
                app.tables[loginList],
                app.searchFields[searchPasswords],
                app.staticTexts[domain],
                app.staticTexts[domainLogin]
            ]
        )
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList + 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306951
    // Smoketest
    func testSaveLogin() {
        closeURLBar()
        // Initially the login list should be empty
        openLoginsSettingsFromBrowserTab()
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList)
        // iOS 15 does not exit from the settings page intermittently
        if #available(iOS 16, *) {
            // Save a login and check that it appears on the list from BrowserTabMenu
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(HomePanelsScreen)

            saveLogin(givenUrl: testLoginPage)
            openLoginsSettings()
            mozWaitForElementToExist(app.tables[loginList])
            mozWaitForElementToExist(app.staticTexts[domain])
            // XCTAssertTrue(app.staticTexts[domainLogin].exists)
            XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList + 1)

            // Check to see how it works with multiple entries in the list- in this case, two for now
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(HomePanelsScreen)
            saveLogin(givenUrl: testSecondLoginPage)
            openLoginsSettings()
            mozWaitForElementToExist(app.tables[loginList])
            mozWaitForElementToExist(app.staticTexts[domain])
            XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList + 2)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306951
    // Smoketest TAE
    func testSaveLogin_TAE() {
        toolBarScreen.assertTabsButtonExists()
        navigator.nowAt(NewTabScreen)
        // Initially the login list should be empty
        openLoginsSettingsFromBrowserTab_TAE()
        loginSettingsScreen.assertLoginCount(is: defaultNumRowsLoginsList)
        // Save a login and check that it appears on the list from BrowserTabMenu
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(HomePanelsScreen)

        saveLogin_TAE(givenUrl: testLoginPage)
        openLoginsSettings_TAE()
        loginSettingsScreen.waitForLoginList()
        loginSettingsScreen.assertDomainVisible(domain)
        loginSettingsScreen.assertLoginCount(is: defaultNumRowsLoginsList + 1)

        // iOS 15 may show "Toolbar" instead of "Settings" intermittently.
        // I can't reproduce the issue manually. The issue occurs only during test automation.
        if #available(iOS 16, *) {
            // Check to see how it works with multiple entries in the list- in this case, two for now
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(HomePanelsScreen)
            saveLogin_TAE(givenUrl: testSecondLoginPage)
            openLoginsSettings_TAE()
            loginSettingsScreen.waitForLoginList()
            loginSettingsScreen.assertDomainVisible(domain)
            loginSettingsScreen.assertLoginCount(is: defaultNumRowsLoginsList + 2)
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306965
    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.buttons["submit"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.notNowButton].waitAndTap()
        // There should not be any login saved
        openLoginsSettings()
        mozWaitForElementToNotExist(app.staticTexts[domain])
        mozWaitForElementToNotExist(app.staticTexts[domainLogin])
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306962
    func testSavedLoginSelectUnselect() {
        saveLogin(givenUrl: testLoginPage)
        navigator.goto(SettingsScreen)
        openLoginsSettings()
        mozWaitForElementToExist(app.staticTexts[domain])
        mozWaitForElementToExist(app.staticTexts[domainLogin])
        XCTAssertTrue(app.buttons["Edit"].isHittable)
        app.buttons["Edit"].waitAndTap()

        mozWaitForElementToExist(app.buttons["Select All"])
        mozWaitForElementToExist(app.staticTexts[domainLogin])

        app.staticTexts[domain].waitAndTap()
        mozWaitForElementToExist(app.buttons["Deselect All"])
        mozWaitForElementToExist(app.buttons["Delete"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306963
    func testDeleteLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        mozWaitForElementToExist(app.staticTexts[domainLogin])
        app.staticTexts[domain].waitAndTap()
        app.cells.staticTexts["Delete"].waitAndTap()
        mozWaitForElementToExist(app.alerts["Remove Password?"])
        app.alerts.buttons["Remove"].waitAndTap()
        mozWaitForElementToExist(app.tables[loginList])
        mozWaitForElementToNotExist(app.staticTexts[domain])
        mozWaitForElementToNotExist(app.staticTexts[domainLogin])
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306966
    func testEditOneLoginEntry() {
        // Go to test login page and save the login: test-password.html
        saveLogin(givenUrl: testLoginPage)
        // Go to Settings > Logins and tap on the username
        openLoginsSettingsFromBrowserTab()
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)
        app.staticTexts[domain].waitAndTap()
        // The login details are available
        waitForExistence(app.tables["Login Detail List"])
        mozWaitForElementToExist(app.tables.cells[loginsListURLLabel])
        mozWaitForElementToExist(app.tables.cells[loginsListUsernameLabel])
        mozWaitForElementToExist(app.tables.cells[loginsListPasswordLabel])
        mozWaitForElementToExist(app.tables.cells.staticTexts["Delete"])
        // Change the username
        app.buttons["Edit"].waitAndTap()
        mozWaitForElementToExist(app.tables["Login Detail List"])
        app.tables["Login Detail List"].cells.elementContainingText("Username").waitAndTap()
        app.menuItems["Select All"].waitAndTap()
        app.menuItems["Cut"].waitAndTap()
        enterTextInField(typedText: "foo")
        app.buttons["Done"].waitAndTap()
        // The username is correctly changed
        mozWaitForElementToExist(app.tables["Login Detail List"])
        mozWaitForElementToExist(app.tables.cells[loginsListURLLabel])
        mozWaitForElementToNotExist(app.tables.cells[loginsListUsernameLabel])
        mozWaitForElementToExist(app.tables.cells[loginsListUsernameLabelEdited])
        mozWaitForElementToExist(app.tables.cells[loginsListPasswordLabel])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306964
    func testSearchLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // Enter on Search mode
        mozWaitForElementToExist(app.searchFields[searchPasswords])
        XCTAssert(app.searchFields[searchPasswords].isEnabled)
        // Type Text that matches user, website
        app.searchFields[searchPasswords].tapAndTypeText("test")
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList + 1)

        // Type Text that does not match
        app.typeText("b")
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsEmptyFilterList)
        // mozWaitForElementToExist(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear text"].waitAndTap()
        XCTAssertEqual(app.tables[loginList].cells.count, defaultNumRowsLoginsList + 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306952
    // Smoketest
    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        // Provided text fields are completely empty
        mozWaitForElementToExist(app.webViews.staticTexts["Username:"])

        // Fill in the username text box
        app.webViews.textFields.element(boundBy: 0).tapAndTypeText(mailLogin)
        // Fill in the password text box
        app.webViews.secureTextFields.element(boundBy: 0).tapAndTypeText("test15mz")

        // Submit form and choose to save the logins
        app.buttons["submit"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.saveButton].waitAndTap()

        // Clear Data and go to test page, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.textFields.element(boundBy: 0))
        // let emailValue = app.webViews.textFields.element(boundBy: 0).value!
        // XCTAssertEqual(emailValue as! String, mailLogin)
        // let passwordValue = app.webViews.secureTextFields.element(boundBy: 0).value!
        // XCTAssertEqual(passwordValue as! String, "••••••••")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306952
    // Smoketest TAE
    func testSavedLoginAutofilled_TAE() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        // Provided text fields are completely empty
         webFormScreen.waitForLoginForm()

        // Fill in the username and password text box
        webFormScreen.fillLoginForm(username: mailLogin, password: "test15mz")

        // Submit form and choose to save the logins
        loginSettingsScreen.tapOnSubmitButton()
        loginSettingsScreen.tapOnSaveButton()

        // Clear Data and go to test page, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        webFormScreen.waitForUsernameField()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306953
    // Smoketest
    func testCreateLoginManually() {
        closeURLBar()
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.tables[loginList])
        mozWaitForElementToExist(app.navigationBars["Passwords"])
        mozWaitForElementToExist(app.staticTexts["No passwords found"])
        mozWaitForElementToExist(app.buttons["Add"])
        mozWaitForElementToExist(app.buttons["Edit"])
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
        XCTAssertTrue(app.buttons["Add"].isEnabled)
        createLoginManually()
        if #unavailable(iOS 16) {
            mozWaitForElementToExist(app.tables[loginList].staticTexts.firstMatch)
        } else {
            mozWaitForElementToExist(app.tables[loginList].staticTexts["https://testweb"])
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306953
    // Smoketest TAE
    func testCreateLoginManually_TAE() {
        toolBarScreen.assertTabsButtonExists()
        navigator.nowAt(NewTabScreen)
        navigator.goto(LoginsSettings)
        loginSettingsScreen.unlockLoginsView()
        loginSettingsScreen.waitForInitialState()
        loginSettingsScreen.assertInitialButtonStates()
        loginSettingsScreen.createLoginManually()
        loginSettingsScreen.assertLoginCreated(for: "https://testweb")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306954
    func testAddDuplicateLogin() {
        // Add login credential
        openLoginsSettingsFromBrowserTab()
        createLoginManually()
        // The login is correctly created.
        waitForElementsToExist(
            [
                app.tables[loginList].staticTexts["https://testweb"],
                app.tables[loginList].staticTexts["foo"]
            ]
        )
        // Repeat previous step, adding the same login
        createLoginManually()
        // The login cannot be duplicated
        XCTAssertEqual(app.staticTexts.matching(identifier: "https://testweb").count, 1, "Duplicate entry in the login list")
        XCTAssertEqual(app.staticTexts.matching(identifier: "foo").count, 1, "Duplicate entry in the login list")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798587
    func testVerifyPasswordsSettingMenu() {
        // Go to Settings - Passwords
        openLoginsSettingsFromBrowserTab()
        // Validate passwords section options are displayed
        waitForElementsToExist(
            [
                app.switches[passwordssQuery.saveLogins],
                app.switches[passwordssQuery.showLoginsInAppMenu],
                app.searchFields[passwordssQuery.searchPasswords],
                app.staticTexts[passwordssQuery.emptyList],
                app.buttons[passwordssQuery.addButton]
            ]
        )
        XCTAssertEqual(app.switches[passwordssQuery.saveLogins].value as? String,
                       "1",
                       "Save passwords toggle in not enabled by default")
        XCTAssertEqual(app.switches[passwordssQuery.showLoginsInAppMenu].value as? String,
                       "1",
                       "Show in Application Menu toggle in not enabled by default")
        app.buttons[passwordssQuery.addButton].waitAndTap()
        waitForElementsToExist(
            [
                app.buttons[passwordssQuery.AddLogin.saveButton],
                app.buttons[passwordssQuery.AddLogin.cancelButton],
                app.tables[passwordssQuery.AddLogin.addCredential].cells["Website, "],
                app.tables[passwordssQuery.AddLogin.addCredential].cells["Username, "],
                app.tables[passwordssQuery.AddLogin.addCredential].cells["Password"]
            ]
        )
        app.buttons[passwordssQuery.AddLogin.cancelButton].waitAndTap()
        navigator.goto(SettingsScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798590
    func testSearchSavedLoginsByURL() {
        validateSearchSavedLoginsByUrlOrUsername(searchText: "localhost")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798591
    func testSearchSavedLoginsByUsername() {
        validateSearchSavedLoginsByUrlOrUsername(searchText: "test")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798597
    // Smoketest
    func testVerifyUpdatedPasswordIsSaved() throws {
        guard #available(iOS 16, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 16")
        }
        validateChangedPasswordSavedState()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798597
    // Smoketest TAE
    func testVerifyUpdatedPasswordIsSaved_TAE() {
        validateChangedPasswordSavedState_TAE()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798598
    func testVerifyUpdatedPasswordIsNotSaved() throws {
        guard #available(iOS 16, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 16")
        }
        validateChangedPasswordSavedState(isPasswordSaved: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/3001341
    func testLoginFreshInstallMessage() throws {
        if #unavailable(iOS 17) {
            throw XCTSkip("setUp() fails to remove app intermittently")
        }
        if #available(iOS 26, *) {
            throw XCTSkip("setUp() fails to remove app intermittently")
        }
        navigator.goto(SettingsScreen)
        let syncInToSync = AccessibilityIdentifiers.Settings.ConnectSetting.title.self
        mozWaitForElementToExist(app.cells[syncInToSync])
        app.cells[syncInToSync].swipeUp()
        navigator.goto(LoginsSettings)
        let message = "Your passwords are now protected by Face ID, Touch ID or a device passcode."
        let continueButton = AccessibilityIdentifiers.Settings.Passwords.onboardingContinue.self
        let learnMoreLink = AccessibilityIdentifiers.Settings.Passwords.onboardingLearnMore.self
        mozWaitForElementToExist(app.staticTexts[message])
        XCTAssertTrue(app.staticTexts[message].isAbove(element: app.buttons[learnMoreLink]),
                      "\(message) message is not above \(learnMoreLink)")
        XCTAssertTrue(app.staticTexts[message].isAbove(element: app.buttons[continueButton]),
                      "\(message) message is not above \(continueButton)")
        XCTAssertTrue(app.buttons[learnMoreLink].isAbove(element: app.buttons[continueButton]),
                      "\(learnMoreLink) is not above \(continueButton)")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798593
    func testCannotSaveLoginWithoutAllFields() {
        openLoginsSettings()
        app.buttons[passwordssQuery.addButton].waitAndTap()
        // Add the Website and Username and leave the Password field empty
        app.tables[passwordssQuery.AddLogin.addCredential].cells["Website, "].waitAndTap()
        enterTextInField(typedText: "testweb")
        app.tables[passwordssQuery.AddLogin.addCredential].cells["Username, "].waitAndTap()
        enterTextInField(typedText: "foo")
        // The login cannot be saved
        XCTAssertFalse(app.buttons[passwordssQuery.AddLogin.saveButton].isEnabled,
                       "Save button is enabled")
        // Add the Username and Password and leave the Website field empty
        app.tables[passwordssQuery.AddLogin.addCredential].cells["Password"].waitAndTap()
        enterTextInField(typedText: "bar")
        app.tables[passwordssQuery.AddLogin.addCredential].cells.element(boundBy: 0).waitAndTap()
        mozWaitForElementToExist(app.keyboards.keys["delete"])
        app.keyboards.keys["delete"].press(forDuration: 2.2)
        // The login cannot be saved
        XCTAssertFalse(app.buttons[passwordssQuery.AddLogin.saveButton].isEnabled,
                       "Save button is enabled")
        // Add the Website and Password and leave the Username field empty
        enterTextInField(typedText: "testweb")
        app.tables[passwordssQuery.AddLogin.addCredential].cells.element(boundBy: 1).waitAndTap()
        mozWaitForElementToExist(app.keyboards.keys["delete"])
        app.keyboards.keys["delete"].press(forDuration: 1.2)
        // The login cannot be saved
        XCTAssertFalse(app.buttons[passwordssQuery.AddLogin.saveButton].isEnabled,
                       "Save button is enabled")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798594
    func testDismissedChangesAreNotSaved() {
        openLoginsSettingsFromBrowserTab()
        createLoginManually()
        let savedCredentials = app.tables[loginList].cells.element(boundBy: 2)
        let passwordCell = app.tables.cells["Password"]
        let editButton = app.buttons["Edit"]
        savedCredentials.waitAndTap()
        editButton.waitAndTap()
        clearAndEnterText(text: "test")
        passwordCell.waitAndTap()
        clearAndEnterText(text: "pass")
        navigator.goto(AutofillPasswordSettings)
        savedCredentials.waitAndTap()
        mozWaitForElementToExist(app.tables.cells[loginsListUsernameLabelEdited])
        editButton.waitAndTap()
        passwordCell.waitAndTap()
        mozWaitForElementToExist(app.tables.cells[loginsListPasswordLabelEdited])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2798592
    func testLoginCopyPaste() throws {
        openLoginsSettingsFromBrowserTab()
        createLoginManually()
        guard #available(iOS 16, *) else {
            throw XCTSkip("Test not supported on iOS versions prior to iOS 16")
        }
        validateLoginTextFieldsCanBeCopied(indexField: 0, copiedText: "https://testweb", field: "website")
        if #available(iOS 26, *) {
            if iPad() {
                app.buttons["Clear text"].waitAndTap()
            } else {
                app.buttons["close"].waitAndTap()
            }
        } else {
            app.buttons[passwordssQuery.AddLogin.cancelButton].waitAndTap()
        }
        validateLoginTextFieldsCanBeCopied(indexField: 1, copiedText: "foo", field: "username")
        if #available(iOS 26, *) {
            if iPad() {
                app.buttons["Clear text"].waitAndTap()
            } else {
                app.buttons["close"].waitAndTap()
            }
        } else {
            app.buttons[passwordssQuery.AddLogin.cancelButton].waitAndTap()
        }
        validateLoginTextFieldsCanBeCopied(indexField: 2, copiedText: "bar", field: "password")
    }

    private func validateChangedPasswordSavedState(isPasswordSaved: Bool = true) {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // There is a Saved Password toggle option (enabled)
        XCTAssertEqual(app.switches[passwordssQuery.saveLogins].value as? String,
                       "1",
                       "Save passwords toggle in not enabled by default")
        navigator.goto(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.secureTextFields.firstMatch.waitAndTap()
        app.secureTextFields.firstMatch.press(forDuration: 1.5)
        app.staticTexts["Select All"].waitAndTap()
        app.secureTextFields.firstMatch.typeText("password")
        app.buttons["submit"].waitAndTap()
        waitForElementsToExist(
            [
                app.staticTexts["Update password?"],
                app.buttons[AccessibilityIdentifiers.SaveLoginAlert.dontUpdateButton],
                app.buttons[AccessibilityIdentifiers.SaveLoginAlert.updateButton]
            ]
        )
        if isPasswordSaved {
            app.buttons[AccessibilityIdentifiers.SaveLoginAlert.updateButton].waitAndTap()
        } else {
            app.buttons[AccessibilityIdentifiers.SaveLoginAlert.dontUpdateButton].waitAndTap()
        }
        openLoginsSettings()
        app.tables[loginList].cells.element(boundBy: 2).waitAndTap()
        app.tables.cells["Password"].waitAndTap()
        app.staticTexts["Reveal"].waitAndTap()
        if isPasswordSaved {
            mozWaitForElementToExist(app.tables.cells.elementContainingText("password"))
        } else {
            mozWaitForElementToNotExist(app.tables.cells.elementContainingText("password"))
        }
    }

    private func validateChangedPasswordSavedState_TAE(isPasswordSaved: Bool = true) {
        let password = "password"
        let selectAll = "Select All"
        let submit = "submit"
        saveLogin_TAE(givenUrl: testLoginPage)
        openLoginsSettings()
        // There is a Saved Password toggle option (enabled)
        loginSettingsScreen.assertSavePasswordsToggleIsEnabled()
        // iOS 15 may not clear the URL bar before entering the new URL.
        // Open a fresh tab is a safer way to open the page for sure.
        if #unavailable(iOS 16) {
            navigator.goto(TabTray)
        }
        navigator.goto(NewTabScreen)
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        let passworField = app.secureTextFields.firstMatch
        mozWaitForElementToExist(passworField)
        passworField.waitAndTap()
        passworField.press(forDuration: 1.5)
        app.staticTexts[selectAll].waitAndTap()
        passworField.typeText(password)
        app.buttons[submit].waitAndTap()

        saveLoginAlertScreen.waitForAlert()
        saveLoginAlertScreen.respondToAlert(savePassword: isPasswordSaved)

        openLoginsSettings()
        loginSettingsScreen.openLoginAtIndex(2)
        loginSettingsScreen.revealPassword()
        if isPasswordSaved {
            loginSettingsScreen.assertPasswordVisible("password")
        } else {
            loginSettingsScreen.assertPasswordNotVisible("password")
        }
    }

    private func validateLoginTextFieldsCanBeCopied(indexField: Int, copiedText: String, field: String) {
        app.tables[loginList].cells.element(boundBy: 2).waitAndTap()
        // Long tap on the Website field and then tap on Copy
        app.tables.cells.element(boundBy: indexField).press(forDuration: 1.5)
        app.staticTexts["Copy"].waitAndTap()
        // Validate text was copied
        app.buttons["Passwords"].waitAndTap()
        let passwordSearchField = app.searchFields[passwordssQuery.searchPasswords]
        if #available(iOS 17, *) {
            passwordSearchField.press(forDuration: 1.5)
        } else {
            passwordSearchField.waitAndTap()
            passwordSearchField.waitAndTap()
        }
        app.staticTexts["Paste"].waitAndTap()
        mozWaitForElementToExist(passwordSearchField)
        XCTAssertEqual(passwordSearchField.value! as? String,
                       copiedText,
                       "The \(field)) text was not copied")
    }

    private func clearAndEnterText(text: String) {
        mozWaitForElementToExist(app.keyboards.keys["delete"])
        app.keyboards.keys["delete"].press(forDuration: 1.2)
        enterTextInField(typedText: text)
    }

    private func validateSearchSavedLoginsByUrlOrUsername(searchText: String) {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // Tap on the search passwords field
        app.searchFields[passwordssQuery.searchPasswords].waitAndTap()
        // Temporarily removing keyboard validation due to CI flakiness
        // XCTAssertTrue(app.keyboards.element.isVisible(), "The keyboard is not shown")
        // A search field is displayed
        mozWaitForElementToExist(app.searchFields[passwordssQuery.searchPasswords])
        // Tap on the cancel button
        if #available(iOS 26, *) {
            if iPad() {
                // Tapping on app on iPad to dimiss the keyboard
                app.waitAndTap()
            } else {
                app.buttons["close"].waitAndTap()
            }
        } else {
            app.buttons[passwordssQuery.AddLogin.cancelButton].waitAndTap()
        }
        // The "Saved logins" page is displayed
        mozWaitForElementToExist(app.switches[passwordssQuery.saveLogins])
        // Temporarily removing keyboard validation due to CI flakiness
        // XCTAssertFalse(app.keyboards.element.isVisible(), "The keyboard is shown")
        // Type anything that can match any website from the saved logins
        app.searchFields[passwordssQuery.searchPasswords].waitAndTap()
        app.typeText(searchText)
        // Only matching results are displayed
        waitForElementsToExist(
            [
                app.tables[loginList].cells.element(boundBy: 2).staticTexts[domain],
                app.tables[loginList].cells.element(boundBy: 2).staticTexts[domainLogin]
            ]
        )
        // Tap on one of the matching results
        app.tables[loginList].cells.element(boundBy: 2).tap()
        // The login details are displayed
        waitForElementsToExist(
            [
                app.tables.cells[loginsListURLLabel],
                app.tables.cells[loginsListUsernameLabel],
                app.tables.cells[loginsListPasswordLabel]
            ]
        )
    }

    private func createLoginManually() {
        app.buttons[passwordssQuery.addButton].waitAndTap()
        waitForElementsToExist(
            [
                app.tables[passwordssQuery.AddLogin.addCredential],
                app.tables[passwordssQuery.AddLogin.addCredential].cells.staticTexts.containingText("Web").element,
                app.tables[passwordssQuery.AddLogin.addCredential].cells.staticTexts["Username"],
                app.tables[passwordssQuery.AddLogin.addCredential].cells.staticTexts["Password"]
            ]
        )

        app.tables[passwordssQuery.AddLogin.addCredential].cells["Website, "].waitAndTap()
        enterTextInField(typedText: "testweb")

        app.tables[passwordssQuery.AddLogin.addCredential].cells["Username, "].waitAndTap()
        enterTextInField(typedText: "foo")

        app.tables[passwordssQuery.AddLogin.addCredential].cells["Password"].waitAndTap()
        enterTextInField(typedText: "bar")

        app.buttons[passwordssQuery.AddLogin.saveButton].waitAndTap()
        mozWaitForElementToExist(app.tables[loginList].otherElements["SAVED PASSWORDS"])
        loginSettingsScreen.tapSaveButtonIfExists()
    }

    func enterTextInField(typedText: String) {
        mozWaitForElementToExist(app.keyboards.firstMatch)
        // The keyboard does not expand automatically sometimes
        if app.keyboards.buttons["Continue"].exists {
            app.keyboards.buttons["Continue"].waitAndTap()
            mozWaitForElementToNotExist(app.keyboards.buttons["Continue"])
            mozWaitForElementToExist(app.keyboards.keys.firstMatch)
        }
        for letter in typedText {
            print("\(letter)")
            app.keyboards.keys["\(letter)"].waitAndTap()
        }
    }

    func closeURLBar() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
    }
}
