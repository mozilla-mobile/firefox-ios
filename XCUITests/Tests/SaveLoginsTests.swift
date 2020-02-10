/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let domain = "http://localhost:\(serverPort)"
let domainLogin = "test@example.com"
let domainSecondLogin = "test2@example.com"
let testLoginPage = Base.helper.path(forTestPage: "test-password.html")
let testSecondLoginPage = Base.helper.path(forTestPage: "test-password-2.html")
let savedLoginEntry = "test@example.com, http://localhost:\(serverPort)"
let urlLogin = Base.helper.path(forTestPage: "empty-login-form.html")
let mailLogin = "iosmztest@mailinator.com"
//The following seem to be labels that change a lot and make the tests break; aka volatile. Let's keep them in one place.
let loginsListURLLabel = "Website, \(domain)"
let loginsListUsernameLabel = "Username, test@example.com"
let loginsListPasswordLabel = "Password"
let defaultNumRowsLoginsList = 2
let defaultNumRowsEmptyFilterList = 0

class SaveLoginTest: BaseTestCase {

    private func saveLogin(givenUrl: String) {
        navigator.openURL(givenUrl)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.buttons["submit"], timeout: 3)
        Base.app.buttons["submit"].tap()
        Base.app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
    }

    private func openLoginsSettings() {
        navigator.goto(SettingsScreen)
        navigator.goto(LoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
    }
    
    func testLoginsListFromBrowserTabMenu() {
        Base.helper.waitForTabsButton()
        //Make sure you can access empty Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.searchFields["Filter"].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        saveLogin(givenUrl: testLoginPage)
        //Make sure you can access populated Login List from Browser Tab Menu
        navigator.goto(LoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.searchFields["Filter"].exists)
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }
    
    func testPasscodeLoginsListFromBrowserTabMenu() {
        navigator.performAction(Action.SetPasscode)
        navigator.nowAt(PasscodeSettings)
        navigator.goto(HomePanelsScreen)
        Base.helper.waitForTabsButton()
        //Make sure you can access empty Login List from Browser Tab Menu
        navigator.goto(LockedLoginsSettings)
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.searchFields["Filter"].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        saveLogin(givenUrl: testLoginPage)
        //Make sure you can access populated Login List from Browser Tab Menu
        navigator.goto(LockedLoginsSettings)
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.searchFields["Filter"].exists)
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    func testSaveLogin() {
        // Initially the login list should be empty
        openLoginsSettings()
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
        // Save a login and check that it appears on the list
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
        //Check to see how it works with multiple entries in the list- in this case, two for now
        saveLogin(givenUrl: testSecondLoginPage)
        openLoginsSettings()
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainSecondLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 2)
    }

    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        Base.helper.waitUntilPageLoad()
        Base.app.buttons["submit"].tap()
        Base.app.buttons["SaveLoginPrompt.dontSaveButton"].tap()
        // There should not be any login saved
        openLoginsSettings()
        XCTAssertFalse(Base.app.staticTexts[domain].exists)
        XCTAssertFalse(Base.app.staticTexts[domainLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
    }

    // Smoketest
    func testSavedLoginSelectUnselect() {
        saveLogin(givenUrl: testLoginPage)
        navigator.goto(SettingsScreen)
        openLoginsSettings()
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)
        Base.app.buttons["Edit"].tap()
        // Due to Bug 1533475 this isn't working
        //XCTAssertTrue(Base.app.cells.images["loginUnselected"].exists)
        XCTAssertTrue(Base.app.buttons["Select All"].exists)
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)

        Base.app.staticTexts[domain].tap()
        Base.helper.waitForExistence(Base.app.buttons["Deselect All"])
        // Due to Bug 1533475 this isn't working
        //XCTAssertTrue(Base.app.cells.images["loginSelected"].exists)
        XCTAssertTrue(Base.app.buttons["Deselect All"].exists)
        XCTAssertTrue(Base.app.buttons["Delete"].exists)

        Base.app.buttons["Cancel"].tap()
        Base.app.buttons["Edit"].tap()
        // Due to Bug 1533475 this isn't working
        //XCTAssertTrue(Base.app.cells.images["loginUnselected"].exists)
    }

    func testDeleteLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        Base.app.staticTexts[domain].tap()
        Base.app.cells.staticTexts["Delete"].tap()
        Base.helper.waitForExistence(Base.app.alerts["Are you sure?"])
        Base.app.alerts.buttons["Delete"].tap()
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        XCTAssertFalse(Base.app.staticTexts[domain].exists)
        XCTAssertFalse(Base.app.staticTexts[domainLogin].exists)
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList)
       // Due to Bug 1533475 this isn't working
        //XCTAssertTrue(Base.app.tables["No logins found"].exists)
    }

    func testEditOneLoginEntry() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        XCTAssertTrue(Base.app.staticTexts[domain].exists)
        XCTAssertTrue(Base.app.staticTexts[domainLogin].exists)
        Base.app.staticTexts[domain].tap()
        Base.helper.waitForExistence(Base.app.tables["Login Detail List"])
        XCTAssertTrue(Base.app.tables.cells[loginsListURLLabel].exists)
        XCTAssertTrue(Base.app.tables.cells[loginsListUsernameLabel].exists)
        XCTAssertTrue(Base.app.tables.cells[loginsListPasswordLabel].exists)
        XCTAssertTrue(Base.app.tables.cells.staticTexts["Delete"].exists)
    }

    func testSearchLogin() {
        saveLogin(givenUrl: testLoginPage)
        openLoginsSettings()
        // Enter on Search mode
        Base.app.searchFields["Filter"].tap()
        // Type Text that matches user, website
        Base.app.searchFields["Filter"].typeText("test")
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)

        // Type Text that does not match
        Base.app.typeText("b")
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsEmptyFilterList)
        //Base.helper.waitForExistence(Base.app.tables["No logins found"])

        // Clear Text
        Base.app.buttons["Clear text"].tap()
        XCTAssertEqual(Base.app.tables["Login List"].cells.count, defaultNumRowsLoginsList + 1)
    }

    // Smoketest
    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        Base.helper.waitUntilPageLoad()
        // Provided text fields are completely empty
        Base.helper.waitForExistence(Base.app.webViews.staticTexts["Username:"])
        
        // Fill in the username text box
        Base.app.webViews.textFields.element(boundBy: 0).tap()
        Base.app.webViews.textFields.element(boundBy: 0).typeText(mailLogin)
        
        // Fill in the password text box
        Base.app.webViews.secureTextFields.element(boundBy: 0).tap()
        Base.app.webViews.secureTextFields.element(boundBy: 0).typeText("test15mz")
        
        // Submit form and choose to save the logins
        Base.app.buttons["submit"].tap()
        Base.app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Clear Data and go to test page, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)
        
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.openURL(urlLogin)
        Base.helper.waitUntilPageLoad()
        Base.helper.waitForExistence(Base.app.webViews.textFields.element(boundBy: 0), timeout: 3)
        let emailValue = Base.app.webViews.textFields.element(boundBy: 0).value!
        XCTAssertEqual(emailValue as! String, mailLogin)
        let passwordValue =  Base.app.webViews.secureTextFields.element(boundBy: 0).value!
        XCTAssertEqual(passwordValue as! String, "••••••••")
    }
}
