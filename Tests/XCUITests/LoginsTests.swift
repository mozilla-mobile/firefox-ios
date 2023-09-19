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
// The following seem to be labels that change a lot and make the tests break; aka volatile. Let's keep them in one place.
let loginsListURLLabel = "Website, \(domain)"
let loginsListUsernameLabel = "Username, test@example.com"
let loginsListPasswordLabel = "Password"
let defaultNumRowsLoginsList = 2
let defaultNumRowsEmptyFilterList = 0

class LoginTest: BaseTestCase {
    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.buttons["submit"], timeout: 10)
        app.buttons["submit"].tap()
        mozWaitForElementToExist(app.buttons["SaveLoginPrompt.saveLoginButton"], timeout: 10)
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
    }

    private func openLoginsSettings() {
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells["SignInToSync"], timeout: 5)
        app.cells["SignInToSync"].swipeUp()
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
    }

    private func openLoginsSettingsFromBrowserTab() {
        waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: TIMEOUT)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.otherElements[StandardImageIdentifiers.Large.login], timeout: 5)
        navigator.goto(LoginsSettings)

        unlockLoginsView()
        waitForExistence(app.tables["Login List"])
        navigator.nowAt(LoginsSettings)
    }

    private func unlockLoginsView() {
        // Press continue button on the password onboarding if it's shown
        if app.buttons[AccessibilityIdentifiers.Settings.Passwords.onboardingContinue].exists {
            app.buttons[AccessibilityIdentifiers.Settings.Passwords.onboardingContinue].tap()
        }

        let passcodeInput = springboard.otherElements.secureTextFields.firstMatch
        mozWaitForElementToExist(passcodeInput, timeout: 20)
        passcodeInput.tap()
        passcodeInput.typeText("foo\n")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288345
    func testLoginsListFromBrowserTabMenu() {
        closeURLBar()
        // Make sure you can access empty Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertTrue(app.searchFields["Filter"].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        app.buttons["Settings"].tap()
        navigator.performAction(Action.OpenNewTabFromTabTray)
        saveLogin(givenUrl: testLoginPage)
        // Make sure you can access populated Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertTrue(app.searchFields["Filter"].exists)
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/52768
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
        XCTAssertTrue(app.staticTexts[domain].exists)
        // XCTAssertTrue(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
        // Check to see how it works with multiple entries in the list- in this case, two for now
        app.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)
        waitForExistence(app.buttons["Done"])
        app.buttons["Done"].tap()

        navigator.nowAt(HomePanelsScreen)
        saveLogin(givenUrl: testSecondLoginPage)
        openLoginsSettings()
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertTrue(app.staticTexts[domain].exists)
        // XCTAssertTrue(app.staticTexts[domainSecondLogin].exists)
        // Workaround for Bitrise specific issue. "vagrant" user is used in Bitrise.
        if (ProcessInfo.processInfo.environment["HOME"]!).contains(String("vagrant")) {
            XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
        } else {
            XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 2)
        }
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288353
    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.dontSaveButton"].tap()
        // There should not be any login saved
        openLoginsSettings()
        XCTAssertFalse(app.staticTexts[domain].exists)
        XCTAssertFalse(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288348
    func testSavedLoginSelectUnselect() {
        saveLogin(givenUrl: testLoginPage)
        navigator.goto(SettingsScreen)
        openLoginsSettings()
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)
        app.buttons["Edit"].tap()

        XCTAssertTrue(app.buttons["Select All"].exists)
        XCTAssertTrue(app.staticTexts[domain].exists)
        XCTAssertTrue(app.staticTexts[domainLogin].exists)

        app.staticTexts[domain].tap()
        mozWaitForElementToExist(app.buttons["Deselect All"])

        XCTAssertTrue(app.buttons["Deselect All"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288349
    func testDeleteLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        app.staticTexts[domain].tap()
        app.cells.staticTexts["Delete"].tap()
        mozWaitForElementToExist(app.alerts["Are you sure?"])
        app.alerts.buttons["Delete"].tap()
        mozWaitForElementToExist(app.tables["Login List"])
        XCTAssertFalse(app.staticTexts[domain].exists)
        XCTAssertFalse(app.staticTexts[domainLogin].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288354
    func testEditOneLoginEntry() throws {
        throw XCTSkip("This test has been disabled for some time now, investigation required")
            /*
            saveLogin(givenUrl: testLoginPage)
            openLoginsSettings()
            XCTAssertTrue(app.staticTexts[domain].exists)
            XCTAssertTrue(app.staticTexts[domainLogin].exists)
            app.staticTexts[domain].tap()
            waitForExistence(app.tables["Login Detail List"])
            XCTAssertTrue(app.tables.cells[loginsListURLLabel].exists)
            XCTAssertTrue(app.tables.cells[loginsListUsernameLabel].exists)
            XCTAssertTrue(app.tables.cells[loginsListPasswordLabel].exists)
            XCTAssertTrue(app.tables.cells.staticTexts["Delete"].exists)
            */
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/2288351
    func testSearchLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // Enter on Search mode
        app.searchFields["Filter"].tap()
        // Type Text that matches user, website
        app.searchFields["Filter"].typeText("test")
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)

        // Type Text that does not match
        app.typeText("b")
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsEmptyFilterList)
        // mozWaitForElementToExist(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear text"].tap()
        XCTAssertEqual(app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/52769
    // Smoketest
    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        // Provided text fields are completely empty
        mozWaitForElementToExist(app.webViews.staticTexts["Username:"], timeout: 15)

        // Fill in the username text box
        app.webViews.textFields.element(boundBy: 0).tap()
        app.webViews.textFields.element(boundBy: 0).typeText(mailLogin)
        // Fill in the password text box
        app.webViews.secureTextFields.element(boundBy: 0).tap()
        app.webViews.secureTextFields.element(boundBy: 0).typeText("test15mz")

        // Submit form and choose to save the logins
        app.buttons["submit"].tap()
        mozWaitForElementToExist(app.buttons["SaveLoginPrompt.saveLoginButton"], timeout: 5)
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Clear Data and go to test page, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)

        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        mozWaitForElementToExist(app.webViews.textFields.element(boundBy: 0), timeout: 3)
        // let emailValue = app.webViews.textFields.element(boundBy: 0).value!
        // XCTAssertEqual(emailValue as! String, mailLogin)
        // let passwordValue = app.webViews.secureTextFields.element(boundBy: 0).value!
        // XCTAssertEqual(passwordValue as! String, "••••••••")
    }

    // https://testrail.stage.mozaws.net/index.php?/cases/view/1468479
    // Smoketest
    func testCreateLoginManually() {
        closeURLBar()
        navigator.goto(LoginsSettings)
        unlockLoginsView()
        mozWaitForElementToExist(app.tables["Login List"], timeout: 15)
        app.buttons["Add"].tap()
        mozWaitForElementToExist(app.tables["Add Credential"], timeout: 15)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Website"].exists)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Username"].exists)
        XCTAssertTrue(app.tables["Add Credential"].cells.staticTexts["Password"].exists)

        app.tables["Add Credential"].cells["Website, "].tap()
        enterTextInField(typedText: "testweb")

        app.tables["Add Credential"].cells["Username, "].tap()
        enterTextInField(typedText: "foo")

        app.tables["Add Credential"].cells["Password"].tap()
        enterTextInField(typedText: "bar")

        app.buttons["Save"].tap()
        mozWaitForElementToExist(app.tables["Login List"].otherElements["SAVED LOGINS"])
        // XCTAssertTrue(app.cells.staticTexts["foo"].exists)
    }

    func enterTextInField(typedText: String) {
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
