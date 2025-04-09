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
let defaultNumRowsLoginsList = 2
let defaultNumRowsEmptyFilterList = 0
let searchPasswords = "Search passwords"

class LoginTest: BaseTestCase {
    let passwordssQuery = AccessibilityIdentifiers.Settings.Logins.Passwords.self
    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        app.buttons["submit"].waitAndTap()
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.saveButton].waitAndTap()
    }

    private func openLoginsSettings() {
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells["SignInToSync"])
        app.cells["SignInToSync"].swipeUp()
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
    }

    private func openLoginsSettingsFromBrowserTab() {
        waitForExistence(app.buttons["TabToolbar.menuButton"])
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton])
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
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
                app.tables["Login List"],
                app.searchFields[searchPasswords]
            ]
        )
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        navigator.goto(AutofillPasswordSettings)
        navigator.goto(SettingsScreen)
        navigator.goto(NewTabScreen)
        app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
        app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        navigator.nowAt(NewTabScreen)
        saveLogin(givenUrl: testLoginPage)
        // Make sure you can access populated Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        waitForElementsToExist(
            [
                app.tables["Login List"],
                app.searchFields[searchPasswords],
                app.staticTexts[domain],
                app.staticTexts[domainLogin]
            ]
        )
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306951
    // Smoketest
    func testSaveLogin() {
        closeURLBar()
        // Initially the login list should be empty
        openLoginsSettingsFromBrowserTab()
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        // Save a login and check that it appears on the list from BrowserTabMenu
        navigator.goto(HomePanelsScreen)
        navigator.nowAt(HomePanelsScreen)

        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        mozWaitForElementToExist(app.tables["Login List"])
        mozWaitForElementToExist(app.staticTexts[domain])
        // XCTAssertTrue(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)

        // iOS 15 may show "Toolbar" instead of "Settings" intermittently.
        // I can't reproduce the issue manually. The issue occurs only during test automation.
        if #available(iOS 16, *) {
            // Check to see how it works with multiple entries in the list- in this case, two for now
            navigator.goto(HomePanelsScreen)
            navigator.nowAt(HomePanelsScreen)
            saveLogin(givenUrl: testSecondLoginPage)
            openLoginsSettings()
            mozWaitForElementToExist(app.tables["Login List"])
            mozWaitForElementToExist(app.staticTexts[domain])
            XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 2)
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
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
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
        mozWaitForElementToExist(app.tables["Login List"])
        mozWaitForElementToNotExist(app.staticTexts[domain])
        mozWaitForElementToNotExist(app.staticTexts[domainLogin])
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
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
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)

        // Type Text that does not match
        app.typeText("b")
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsEmptyFilterList)
        // mozWaitForElementToExist(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear text"].waitAndTap()
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
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

    // https://mozilla.testrail.io/index.php?/cases/view/2306953
    // Smoketest
    func testCreateLoginManually() {
        closeURLBar()
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
        mozWaitForElementToExist(app.navigationBars["Passwords"])
        mozWaitForElementToExist(app.staticTexts["No passwords found"])
        mozWaitForElementToExist(app.buttons["Add"])
        mozWaitForElementToExist(app.buttons["Edit"])
        XCTAssertFalse(app.buttons["Edit"].isEnabled)
        XCTAssertTrue(app.buttons["Add"].isEnabled)
        createLoginManually()
        mozWaitForElementToExist(app.tables["Login List"].staticTexts["https://testweb"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306954
    func testAddDuplicateLogin() {
        // Add login credential
        openLoginsSettingsFromBrowserTab()
        createLoginManually()
        // The login is correctly created.
        waitForElementsToExist(
            [
                app.tables["Login List"].staticTexts["https://testweb"],
                app.tables["Login List"].staticTexts["foo"]
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
    func testVerifyUpdatedPasswordIsSaved() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // There is a Saved Password toggle option (enabled)
        XCTAssertEqual(app.switches[passwordssQuery.saveLogins].value as? String,
                       "1",
                       "Save passwords toggle in not enabled by default")
        navigator.goto(NewTabScreen)
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
        app.buttons[AccessibilityIdentifiers.SaveLoginAlert.updateButton].waitAndTap()
        openLoginsSettings()
        app.tables["Login List"].cells.element(boundBy: 2).waitAndTap()
        app.tables.cells["Password"].waitAndTap()
        app.staticTexts["Reveal"].waitAndTap()
        mozWaitForElementToExist(app.tables.cells.elementContainingText("password"))
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
        app.buttons[passwordssQuery.AddLogin.cancelButton].waitAndTap()
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
                app.tables["Login List"].cells.element(boundBy: 2).staticTexts[domain],
                app.tables["Login List"].cells.element(boundBy: 2).staticTexts[domainLogin]
            ]
        )
        // Tap on one of the matching results
        app.tables["Login List"].cells.element(boundBy: 2).tap()
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
        mozWaitForElementToExist(app.tables["Login List"].otherElements["SAVED PASSWORDS"])
    }

    func enterTextInField(typedText: String) {
        // iOS 15 does not expand the keyboard for entering the credentials sometimes.
        if #unavailable(iOS 16) {
            mozWaitForElementToExist(app.keyboards.firstMatch)
            if app.keyboards.buttons["Continue"].exists {
                app.keyboards.buttons["Continue"].waitAndTap()
                mozWaitForElementToNotExist(app.keyboards.buttons["Continue"])
            }
            // The keyboard may need extra time to respond.
            sleep(1)
        }
        for letter in typedText {
            print("\(letter)")
            app.keyboards.keys["\(letter)"].waitAndTap()
        }
    }

    func closeURLBar () {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
    }
}
