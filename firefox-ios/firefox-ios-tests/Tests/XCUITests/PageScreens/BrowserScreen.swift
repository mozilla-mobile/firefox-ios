// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class BrowserScreen {
    private let app: XCUIApplication
    private let sel: BrowserSelectorsSet

    init(app: XCUIApplication, selectors: BrowserSelectorsSet = BrowserSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertAddressBarContains(value: String, timeout: TimeInterval = TIMEOUT) {
        let addressBar = sel.ADDRESS_BAR.element(in: app)
        BaseTestCase().mozWaitForValueContains(addressBar, value: value, timeout: timeout)
    }

    func handleHumanVerification() {
        let checkboxValidation = app.webViews["Web content"].staticTexts["Verify you are human"]
        if checkboxValidation.exists {
            checkboxValidation.waitAndTap()
        }
    }

    func tapBackButton() {
        let backButton = app.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        backButton.waitAndTap()
    }

    func assertAutofillOptionNotAvailable(
            forFieldsCount count: Int,
            autofillButtonID: String,
            timeout: TimeInterval = TIMEOUT) {
        let textFieldsQuery = app.webViews.textFields
        let addressAutofillButton = app.buttons[autofillButtonID]

        for index in 0..<count {
            let textField = textFieldsQuery.element(boundBy: index)

            BaseTestCase().mozWaitForElementToExist(textField)
            textField.waitAndTap()

            BaseTestCase().mozWaitForElementToNotExist(addressAutofillButton, timeout: timeout)
        }
    }
}
