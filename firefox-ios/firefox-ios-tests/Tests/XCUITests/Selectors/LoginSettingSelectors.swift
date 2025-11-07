// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation

protocol LoginSettingsSelectorsSet {
    var LOGIN_LIST: Selector { get }
    var SUBMIT_BUTTON: Selector { get }
    var SAVE_BUTTON: Selector { get }
    var NAVBAR_PASSWORDS: Selector { get }
    var EMPTY_STATE_LABEL: Selector { get }
    var ADD_BUTTON: Selector { get }
    var EDIT_BUTTON: Selector { get }
    var PASSWORD_ADD_BUTTON: Selector { get }
    var ADD_CREDENTIAL_TABLE: Selector { get }
    var WEBSITE_FIELD_CELL: Selector { get }
    var USERNAME_FIELD_CELL: Selector { get }
    var PASSWORD_FIELD_CELL: Selector { get }
    var SAVE_BUTTON_CELL: Selector { get }
    var SAVED_PASSWORDS_LABEL: Selector { get }
    var SAVE_PASSWORDS_TOGGLE: Selector { get }
    var REVEAL_BUTTON: Selector { get }
    var PASSCODE_FIELD: Selector { get }
    var ONBOARDING_CONTINUE_BUTTON: Selector { get }
    var SAVE_BUTTON_ADD_LOGIN: Selector { get }
    func domainLabel(_ domain: String) -> Selector
    func createdLoginCell(_ domain: String) -> Selector
    var all: [Selector] { get }
}

struct LoginSettingsSelectors: LoginSettingsSelectorsSet {
    private enum IDs {
        static let loginList = "Login List"
        static let submitButton = "submit"
        static let saveButton = AccessibilityIdentifiers.SaveLoginAlert.saveButton
        static let navbarTitle = "Passwords"
        static let emptyState = "No passwords found"
        static let addButton = "Add"
        static let editButton = "Edit"
        static let password_Add_Button = AccessibilityIdentifiers.Settings.Logins.Passwords.addButton
        static let addCredentials = AccessibilityIdentifiers.Settings.Logins.Passwords.AddLogin.addCredential
        static let websiteCell = "Website, "
        static let usernameCell = "Username, "
        static let passwordCell = "Password"
        static let saveButtonCell = "Save"
        static let savedPasswordsLabel = "SAVED PASSWORDS"
        static let savePasswordsToggle = AccessibilityIdentifiers.Settings.Logins.Passwords.saveLogins
        static let revealButton = "Reveal"
        static let onboardingContinue = AccessibilityIdentifiers.Settings.Passwords.onboardingContinue
        static let saveButton_AddLogin = AccessibilityIdentifiers.Settings.Logins.Passwords.AddLogin.saveButton
    }

    let LOGIN_LIST = Selector.tableIdOrLabel(
        IDs.loginList,
        description: "Login List table",
        groups: ["settings", "logins"]
    )

    let SUBMIT_BUTTON = Selector.buttonId(
        IDs.submitButton,
        description: "Submit Button",
        groups: ["settings", "logins"]
    )

    let SAVE_BUTTON = Selector.buttonId(
        IDs.saveButton,
        description: "Save Button",
        groups: ["settings", "logins"]
    )

    let NAVBAR_PASSWORDS = Selector.navigationBarByTitle(
        IDs.navbarTitle,
        description: "Navigation bar title in Passwords screen",
        groups: ["settings", "logins"]
    )

    let EMPTY_STATE_LABEL = Selector.staticTextByLabel(
        IDs.emptyState,
        description: "Empty state label when no logins exist",
        groups: ["settings", "logins"]
    )

    let ADD_BUTTON = Selector.buttonByLabel(
        IDs.addButton,
        description: "Add button in Passwords screen",
        groups: ["settings", "logins"]
    )

    let EDIT_BUTTON = Selector.buttonByLabel(
        IDs.editButton,
        description: "Edit button in Passwords screen",
        groups: ["settings", "logins"]
    )

    let PASSWORD_ADD_BUTTON = Selector.buttonByLabel(
        IDs.password_Add_Button,
        description: "Add button to create a new login manually",
        groups: ["settings", "logins"]
    )

    let ADD_CREDENTIAL_TABLE = Selector.tableIdOrLabel(
        IDs.addCredentials,
        description: "Table for adding credentials manually",
        groups: ["settings", "logins"]
    )

    let WEBSITE_FIELD_CELL = Selector.tableCellByLabel(
        IDs.websiteCell,
        description: "Website field cell in Add Login table",
        groups: ["settings", "logins"]
    )

    let USERNAME_FIELD_CELL = Selector.tableCellByLabel(
        IDs.usernameCell,
        description: "Username field cell in Add Login table",
        groups: ["settings", "logins"]
    )

    let PASSWORD_FIELD_CELL = Selector.tableCellByLabel(
        IDs.passwordCell,
        description: "Password field cell in Add Login table",
        groups: ["settings", "logins"]
    )

    let SAVE_BUTTON_CELL = Selector.buttonIdOrLabel(
        IDs.saveButton,
        description: "Save button in Add Login screen",
        groups: ["settings", "logins"]
    )

    let SAVED_PASSWORDS_LABEL = Selector.staticTextByLabel(
        IDs.savedPasswordsLabel,
        description: "Label confirming that the password was saved successfully",
        groups: ["settings", "logins"]
    )

    let SAVE_PASSWORDS_TOGGLE = Selector.switchById(
        IDs.savePasswordsToggle,
        description: "Save passwords toggle in Logins settings",
        groups: ["settings", "logins"]
    )

    let REVEAL_BUTTON = Selector.staticTextId(
        IDs.revealButton,
        description: "Reveal password button",
        groups: ["settings", "logins"]
    )

    let PASSCODE_FIELD = Selector.springboardPasscodeField(
        description: "System passcode secure text field",
        groups: ["springboard", "logins"]
    )

    let ONBOARDING_CONTINUE_BUTTON = Selector.buttonId(
        IDs.onboardingContinue,
        description: "Continue button on password onboarding screen",
        groups: ["settings", "logins"]
    )

    let SAVE_BUTTON_ADD_LOGIN = Selector.buttonId(
        IDs.saveButton_AddLogin,
        description: "Save Button in Add Login Screen",
        groups: ["settings", "logins"]
    )

    func domainLabel(_ domain: String) -> Selector {
        Selector.staticTextByExactLabel(
            domain,
            description: "Saved login entry for domain \(domain)",
            groups: ["settings", "logins"]
        )
    }

    func createdLoginCell(_ domain: String) -> Selector {
        Selector.staticTextByExactLabel(
            domain,
            description: "Created login entry for domain \(domain)",
            groups: ["settings", "logins"]
        )
    }

    var all: [Selector] { [LOGIN_LIST, SUBMIT_BUTTON, SAVE_BUTTON, NAVBAR_PASSWORDS,
                           EMPTY_STATE_LABEL, EDIT_BUTTON, ADD_BUTTON, PASSWORD_ADD_BUTTON,
                           ADD_CREDENTIAL_TABLE, WEBSITE_FIELD_CELL, USERNAME_FIELD_CELL,
                           SAVE_BUTTON_CELL, SAVED_PASSWORDS_LABEL, SAVE_PASSWORDS_TOGGLE,
                           REVEAL_BUTTON, PASSCODE_FIELD, ONBOARDING_CONTINUE_BUTTON,
                           SAVE_BUTTON_ADD_LOGIN] }
}
