// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        app.buttons["submit"].waitAndTap()
        mozWaitForElementToExist(app.buttons["SaveLoginPrompt.saveLoginButton"])
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
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
        waitForExistence(app.tables["Login List"])
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
        app.buttons["Settings"].tap()
        navigator.performAction(Action.OpenNewTabFromTabTray)
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
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()
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
            app.buttons["Settings"].tap()
            navigator.nowAt(SettingsScreen)
            waitForExistence(app.buttons["Done"])
            app.buttons["Done"].tap()

            navigator.nowAt(HomePanelsScreen)
            saveLogin(givenUrl: testSecondLoginPage)
            openLoginsSettings()
            mozWaitForElementToExist(app.tables["Login List"])
            mozWaitForElementToExist(app.staticTexts[domain])
            // XCTAssertTrue(app.staticTexts[domainSecondLogin].exists)
            // Workaround for Bitrise specific issue. "vagrant" user is used in Bitrise.
            if (ProcessInfo.processInfo.environment["HOME"]!).contains(String("vagrant")) {
                XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
            // Workaround for Github Actions specific issue. "runner" user is used in Github Actions.
            } else if (ProcessInfo.processInfo.environment["HOME"]!).contains(String("runner")) {
                XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
            } else {
                XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 2)
            }
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306965
    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.dontSaveButton"].tap()
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
        app.buttons["Edit"].tap()

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
        app.cells.staticTexts["Delete"].tap()
        mozWaitForElementToExist(app.alerts["Remove Password?"])
        app.alerts.buttons["Remove"].tap()
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
        app.staticTexts[domain].tap()
        // The login details are available
        waitForExistence(app.tables["Login Detail List"])
        mozWaitForElementToExist(app.tables.cells[loginsListURLLabel])
        mozWaitForElementToExist(app.tables.cells[loginsListUsernameLabel])
        mozWaitForElementToExist(app.tables.cells[loginsListPasswordLabel])
        mozWaitForElementToExist(app.tables.cells.staticTexts["Delete"])
        // Change the username
        app.buttons["Edit"].tap()
        mozWaitForElementToExist(app.tables["Login Detail List"])
        app.tables["Login Detail List"].cells.elementContainingText("Username").tap()
        mozWaitForElementToExist(app.menuItems["Select All"])
        app.menuItems["Select All"].tap()
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
        app.buttons["Clear text"].tap()
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
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.saveLoginButton"].waitAndTap()

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

    private func createLoginManually() {
        app.buttons["Add"].tap()
        waitForElementsToExist(
            [
                app.tables["Add Credential"],
                app.tables["Add Credential"].cells.staticTexts.containingText("Web").element,
                app.tables["Add Credential"].cells.staticTexts["Username"],
                app.tables["Add Credential"].cells.staticTexts["Password"]
            ]
        )

        app.tables["Add Credential"].cells["Website, "].tap()
        enterTextInField(typedText: "testweb")

        app.tables["Add Credential"].cells["Username, "].tap()
        enterTextInField(typedText: "foo")

        app.tables["Add Credential"].cells["Password"].tap()
        enterTextInField(typedText: "bar")

        app.buttons["Save"].tap()
        mozWaitForElementToExist(app.tables["Login List"].otherElements["SAVED PASSWORDS"])
    }

    func enterTextInField(typedText: String) {
        // iOS 15 does not expand the keyboard for entering the credentials sometimes.
        if #unavailable(iOS 16) {
            mozWaitForElementToExist(app.keyboards.firstMatch)
            if app.keyboards.buttons["Continue"].exists {
                app.keyboards.buttons["Continue"].tap()
                mozWaitForElementToNotExist(app.keyboards.buttons["Continue"])
            }
            // The keyboard may need extra time to respond.
            sleep(1)
        }
        for letter in typedText {
            print("\(letter)")
            app.keyboards.keys["\(letter)"].tap()
        }
    }

    func closeURLBar () {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
    }
}
