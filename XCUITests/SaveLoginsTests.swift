/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let domain = "http://localhost:6571"
let testLoginPage = path(forTestPage: "test-password.html")
let savedLoginEntry = "test@example.com, http://localhost:6571"
let urlLogin = "linkedin.com"
let mailLogin = "iosmztest@mailinator.com"

class SaveLoginTest: BaseTestCase {

    private func saveLogin() {
        navigator.openURL(testLoginPage)
        waitUntilPageLoad()
        waitforExistence(app.buttons["submit"], timeout: 3)
        app.buttons["submit"].tap()
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
    }

    private func openLoginsSettings() {
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
    }
    // Test disabled on iPhone schema due to bug 1488215
    func testSaveLogin() {
        // Initially the login list should be empty
        openLoginsSettings()
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
        // Save a login and check that it appears on the list
        saveLogin()
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
        XCTAssertTrue(app.tables.cells[savedLoginEntry].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, 1)
    }

    // Test disabled on iPhone schema due to bug 1488215
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

    func testSavedLoginSelectUnselect() {
        saveLogin()
        openLoginsSettings()
        XCTAssertTrue(app.tables.cells[savedLoginEntry].exists)

        app.buttons["Edit"].tap()
        XCTAssertTrue(app.cells.images["loginUnselected"].exists)
        XCTAssertTrue(app.buttons["Select All"].exists)

        app.tables.cells[savedLoginEntry].tap()
        XCTAssertTrue(app.cells.images["loginSelected"].exists)
        XCTAssertTrue(app.buttons["Deselect All"].exists)
        XCTAssertTrue(app.buttons["Delete"].exists)

        app.buttons["Cancel"].tap()
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.cells.images["loginUnselected"].exists)
    }

    // Test disabled on iPhone schema due to bug 1488215
    func testDeleteLogin() {
        saveLogin()
        openLoginsSettings()
        app.tables.cells[savedLoginEntry].tap()
        app.cells.staticTexts["Delete"].tap()
        waitforExistence(app.alerts["Are you sure?"])
        app.alerts.buttons["Delete"].tap()
        waitforExistence(app.tables["Login List"])
        XCTAssertFalse(app.tables.cells[savedLoginEntry].exists)
        XCTAssertEqual(app.tables["Login List"].cells.count, 0)
        XCTAssertTrue(app.tables["No logins found"].exists)
    }

    // Test disabled on iPhone schema due to bug 1488215
    func testEditOneLoginEntry() {
        saveLogin()
        openLoginsSettings()
        XCTAssertTrue(app.tables.cells[savedLoginEntry].exists)

        app.tables.cells[savedLoginEntry].tap()
        waitforExistence(app.tables["Login Detail List"])
        XCTAssertTrue(app.tables.cells["website, \(domain)"].exists)
        XCTAssertTrue(app.tables.cells["username, test@example.com"].exists)
        XCTAssertTrue(app.tables.cells["password"].exists)
        XCTAssertTrue(app.tables.cells.staticTexts["Delete"].exists)
    }

    // Test disabled on iPhone schema due to bug 1488215
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
        waitforExistence(app.tables["No logins found"])

        // Clear Text
        app.buttons["Clear Search"].tap()
        XCTAssertEqual(app.tables["Login List"].cells.count, 1)
    }

    func testSavedLoginAutofilled() {
        navigator.openURL(urlLogin)
        waitUntilPageLoad()
        app.webViews.links["Sign in"].tap()
        waitforExistence(app.webViews.textFields["Email"])
        app.webViews.textFields["Email"].tap()
        app.webViews.textFields["Email"].typeText(mailLogin)

        app.webViews.secureTextFields["Password"].tap()
        app.webViews.secureTextFields["Password"].typeText("test15mz")

        app.webViews.buttons["Sign in"].tap()
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()

        // Clear Data and go to linkedin, fields should be filled in
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.AcceptClearPrivateData)
        navigator.openNewURL(urlString: urlLogin)
        waitUntilPageLoad()
        let emailValue = app.webViews.textFields["Email"].value!
        XCTAssertEqual(emailValue as! String, mailLogin)
        let passwordValue = app.webViews.secureTextFields["Password"].value!
        XCTAssertEqual(passwordValue as! String, "••••••••")
    }
}
