/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let domain = "http://localhost:\(serverPort)"
let testLoginPage = path(forTestPage: "test-password.html")
let savedLoginEntry = "test@example.com, http://localhost:\(serverPort)"
let urlLogin = "linkedin.com"
let mailLogin = "iosmztest@mailinator.com"

class SaveLoginTest: BaseTestCase {

    private func saveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        waitForExistence(app.buttons["submit"], timeout: 3)
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
    }

    private func openLoginsSettings() {
        navigator.goto(LoginsSettings)
        waitForExistence(app.tables["Login List"])
    }

    func testSaveLogin() {
        // Initially the login list should be empty
        openLoginsSettings()
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
        // Save a login and check that it appears on the list
        saveLogin()
        navigator.goto(LoginsSettings)
        waitForExistence(app.tables["Login List"])
        XCTAssertTrue(app.tables.cells[savedLoginEntry].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, 1)
    }

    func testDoNotSaveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.dontSaveButton"].tap()
        // There should not be any login saved
        openLoginsSettings()
        XCTAssertFalse(app.tables.cells[savedLoginEntry].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
    }

    // Smoketest
    func testSavedLoginSelectUnselect() {
        saveLogin()
        openLoginsSettings()
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.buttons["Select All"].exists)

        let selectionButton = app.tables["Login List"].cells.allElementsBoundByIndex[2].buttons.allElementsBoundByIndex.first!
        XCTAssertFalse(selectionButton.isSelected)
        app.tables["Login List"].cells.staticTexts["test@example.com"].tap()
        XCTAssertTrue(selectionButton.isSelected)
       
        XCTAssertTrue(app.buttons["Deselect All"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)

        app.buttons["Cancel"].tap()
        app.buttons["Edit"].tap()
    }

    func testDeleteLogin() {
        saveLogin()
        openLoginsSettings()
        app.tables.cells[savedLoginEntry].tap()
        app.cells.staticTexts["Delete"].tap()
        waitForExistence(app.alerts["Are you sure?"])
        app.alerts.buttons["Delete"].tap()
        waitForExistence(app.tables["Login List"])
        XCTAssertFalse(app.tables.cells[savedLoginEntry].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
        XCTAssertTrue(app.tables["No logins found"].exists)
    }


    func testEditOneLoginEntry() {
        saveLogin()
        openLoginsSettings()
        XCTAssertTrue(app.tables.cells[savedLoginEntry].exists)

        app.tables.cells[savedLoginEntry].tap()
        waitForExistence(app.tables["Login Detail List"])
        XCTAssertTrue(app.tables.cells["website, \(domain)"].exists)
        XCTAssertTrue(app.tables.cells["username, test@example.com"].exists)
        XCTAssertTrue(app.tables.cells["password"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Delete"].exists)
    }


    func testSearchLogin() {
        saveLogin()
        openLoginsSettings()

        // Enter on Search mode
        app.otherElements["Enter Search Mode"].tap()
        app.textFields["Search Input Field"].tap()

        // Type Text that matches user, website, password
        app.textFields["Search Input Field"].typeText("test")
        XCTAssertEqual(app.tables["Login List"].cells.count, 1)

        // Type Text that does not match
        app.typeText("b")
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
        waitForExistence(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear Search"].tap()
        XCTAssertEqual(app.tables["Login List"].cells.count, 1)
    }

    // Smoketest
    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        app.webViews.links["Sign in"].tap()
        waitForExistence(app.webViews.textFields["Email"])
        app.webViews.textFields["Email"].tap()
        app.webViews.textFields["Email"].typeText(mailLogin)

        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText("test15mz")

        app.webViews.buttons["Sign in"].tap()
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Clear Data and go to linkedin, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.goto(HomePanelsScreen)
        navigator.openNewURL(urlString: urlLogin)
        waitUntilPageLoad()
        waitForExistence(app.webViews.textFields["Email"], timeout: 3)
        let emailValue = app.webViews.textFields["Email"].value!
        XCTAssertEqual(emailValue as! String, mailLogin)
        let passwordValue = app.webViews.secureTextFields["Password"].value!
        XCTAssertEqual(passwordValue as! String, "••••••••")
    }
}
