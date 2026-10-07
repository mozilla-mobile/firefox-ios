// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol WebFormSelectorsSet {
    var USERNAME_LABEL: Selector { get }
    var USERNAME_FIELD: Selector { get }
    var PASSWORD_FIELD: Selector { get }
    var USE_SAVED_PASSWORD_BUTTON: Selector { get }
    var KEYBOARD_NEXT_BUTTON: Selector { get }
    var KEYBOARD_DONE_BUTTON: Selector { get }
    var SAVED_LOGINS_SHEET_CLOSE_BUTTON: Selector { get }
    var IPAD_ASSISTANT_PREVIOUS_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct WebFormSelectors: WebFormSelectorsSet {
    private enum IDs {
        static let usernameLabel = "Username:"
        static let usernameField = "username"
        static let passwordField = "password"
        static let useSavedPasswordLabel = "Use saved password"
        static let keyboardNextButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.nextButton
        static let keyboardDoneButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.doneButton
        static let savedLoginsSheetCloseButton = AccessibilityIdentifiers.Autofill.loginCloseButton
        static let iPadAssistantPreviousButton = "_previousTapped"
    }

    let USERNAME_LABEL = Selector.staticTextByLabel(
        IDs.usernameLabel,
        description: "Username label in the web form",
        groups: ["browser", "webform"]
    )

    let USERNAME_FIELD = Selector.textFieldId(
        IDs.usernameField,
        description: "Username input field in web form",
        groups: ["browser", "webform"]
    )

    let PASSWORD_FIELD = Selector.textFieldId(
        IDs.passwordField,
        description: "Password input field in web form",
        groups: ["browser", "webform"]
    )

    // Not exposed to accessibility on iOS 26; WebFormScreen falls back to tapping between Next and Done.
    let USE_SAVED_PASSWORD_BUTTON = Selector.anyIdOrLabel(
        IDs.useSavedPasswordLabel,
        description: "Use saved password button on the keyboard accessory bar",
        groups: ["browser", "webform", "keyboard"]
    )

    let KEYBOARD_NEXT_BUTTON = Selector.buttonId(
        IDs.keyboardNextButton,
        description: "Next form field button on the keyboard accessory bar",
        groups: ["browser", "webform", "keyboard"]
    )

    let KEYBOARD_DONE_BUTTON = Selector.buttonId(
        IDs.keyboardDoneButton,
        description: "Done button on the keyboard accessory bar",
        groups: ["browser", "webform", "keyboard"]
    )

    let SAVED_LOGINS_SHEET_CLOSE_BUTTON = Selector.buttonId(
        IDs.savedLoginsSheetCloseButton,
        description: "Close button of the saved logins bottom sheet",
        groups: ["browser", "webform"]
    )

    // iPad's system shortcut bar above the keyboard, which replaces Firefox's own Next and Done buttons.
    let IPAD_ASSISTANT_PREVIOUS_BUTTON = Selector.buttonId(
        IDs.iPadAssistantPreviousButton,
        description: "Previous field button on the iPad keyboard shortcut bar",
        groups: ["browser", "webform", "keyboard"]
    )

    var all: [Selector] { [USERNAME_LABEL, USERNAME_FIELD, PASSWORD_FIELD,
                           USE_SAVED_PASSWORD_BUTTON, KEYBOARD_NEXT_BUTTON, KEYBOARD_DONE_BUTTON,
                           SAVED_LOGINS_SHEET_CLOSE_BUTTON, IPAD_ASSISTANT_PREVIOUS_BUTTON] }
}
