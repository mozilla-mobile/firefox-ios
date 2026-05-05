// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class LoginSettingsScreen {
    private let app: XCUIApplication
    private let sel: LoginSettingsSelectorsSet

    init(app: XCUIApplication, selectors: LoginSettingsSelectorsSet = LoginSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func waitForLoginList() {
        let table = sel.LOGIN_LIST.element(in: app)
        BaseTestCase().mozWaitForElementToExist(table)
    }

    func assertLoginCount(is expected: Int) {
        let table = sel.LOGIN_LIST.element(in: app)
        BaseTestCase().mozWaitForElementToExist(table)
        let count = table.cells.count
        XCTAssertEqual(count, expected, "Expected \(expected) rows in login list but found \(count)")
    }

    func tapSaveButtonIfExists() {
        sel.SAVE_BUTTON_CELL.element(in: app).tapIfExists()
    }

    func assertDomainVisible(_ domain: String) {
        let domainText = sel.domainLabel(domain).element(in: app)
        BaseTestCase().mozWaitForElementToExist(domainText)
    }

    func assertLoginListExist() {
        BaseTestCase().mozWaitForElementToExist(sel.LOGIN_LIST.element(in: app))
    }

    func tapOnSubmitButton() {
        sel.SUBMIT_BUTTON.element(in: app).waitAndTap()
    }

    func tapOnSaveButton() {
        sel.SAVE_BUTTON.element(in: app).waitAndTap()
    }

    func waitForInitialState() {
        BaseTestCase().mozWaitForElementToExist(sel.LOGIN_LIST.element(in: app))
        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR_PASSWORDS.element(in: app))
        BaseTestCase().mozWaitForElementToExist(sel.EMPTY_STATE_LABEL.element(in: app))
        BaseTestCase().mozWaitForElementToExist(sel.ADD_BUTTON.element(in: app))
        BaseTestCase().mozWaitForElementToExist(sel.EDIT_BUTTON.element(in: app))
    }

    func assertInitialButtonStates() {
        XCTAssertFalse(sel.EDIT_BUTTON.element(in: app).isEnabled, "Expected Edit button to be disabled")
        XCTAssertTrue(sel.ADD_BUTTON.element(in: app).isEnabled, "Expected Add button to be enabled")
    }

    func assertLoginCreated(for domain: String) {
        let loginCell = sel.createdLoginCell(domain).element(in: app)
        BaseTestCase().mozWaitForElementToExist(loginCell)
    }

    func createLoginManually(site: String = "testweb", username: String = "foo", password: String = "bar") {
        sel.ADD_BUTTON.element(in: app).waitAndTap()

        BaseTestCase().waitForElementsToExist([
            sel.ADD_CREDENTIAL_TABLE.element(in: app),
            sel.WEBSITE_FIELD_CELL.element(in: app),
            sel.USERNAME_FIELD_CELL.element(in: app),
            sel.PASSWORD_FIELD_CELL.element(in: app)
        ])

        sel.WEBSITE_FIELD_CELL.element(in: app).waitAndTap()
        enterTextInField(typedText: site)

        sel.USERNAME_FIELD_CELL.element(in: app).waitAndTap()
        enterTextInField(typedText: username)

        sel.PASSWORD_FIELD_CELL.element(in: app).waitAndTap()
        enterTextInField(typedText: password)

        sel.SAVE_BUTTON_ADD_LOGIN.element(in: app).waitAndTap()

        BaseTestCase().mozWaitForElementToExist(sel.SAVED_PASSWORDS_LABEL.element(in: app))
    }

    func enterTextInField(typedText: String) {
        if app.keyboards.element.exists {
            if app.keyboards.buttons["Continue"].exists {
                app.keyboards.buttons["Continue"].waitAndTap()
                BaseTestCase().mozWaitForElementToNotExist(app.keyboards.buttons["Continue"])
                BaseTestCase().mozWaitForElementToExist(app.keyboards.keys.firstMatch)
            }
            for letter in typedText {
                app.keyboards.keys["\(letter)"].waitAndTap()
            }
        } else {
            // Without visual keyboard (hardware connected), use typeText
            app.typeText(typedText)
        }
    }

    func assertSavePasswordsToggleIsEnabled() {
        let toggle = sel.SAVE_PASSWORDS_TOGGLE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)
        XCTAssertEqual(toggle.value as? String, "1", "Save passwords toggle is not enabled by default")
    }

    func openLoginAtIndex(_ index: Int) {
        let cell = sel.LOGIN_LIST.element(in: app).cells.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(cell)
        cell.waitAndTap()
    }

    func revealPassword() {
        sel.PASSWORD_FIELD_CELL.element(in: app).waitAndTap()
        sel.REVEAL_BUTTON.element(in: app).waitAndTap()
    }

    func assertPasswordVisible(_ value: String) {
        let match = app.tables.cells.containing(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
        BaseTestCase().mozWaitForElementToExist(match)
    }

    func assertPasswordNotVisible(_ value: String) {
        let match = app.tables.cells.containing(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
        BaseTestCase().mozWaitForElementToNotExist(match)
    }

    func unlockLoginsView() {
        let passcodeValue = "foo\n"
        if sel.ONBOARDING_CONTINUE_BUTTON.element(in: app).exists {
            sel.ONBOARDING_CONTINUE_BUTTON.element(in: app).waitAndTap()
        }

        let passcode = sel.PASSCODE_FIELD.element(in: springboard)
        BaseTestCase().mozWaitForElementToExist(passcode)
        passcode.tapAndTypeText(passcodeValue)
        BaseTestCase().mozWaitForElementToNotExist(passcode)
    }

    func assertLoginCreatedFirstMatch() {
        let firstStaticText = sel.LOGIN_LIST.element(in: app).staticTexts.firstMatch
        BaseTestCase().mozWaitForElementToExist(firstStaticText)
    }
}
