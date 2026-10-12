// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class WebFormScreen {
    private let app: XCUIApplication
    private let webForm: WebFormSelectorsSet

    init(app: XCUIApplication, webForm: WebFormSelectorsSet = WebFormSelectors()) {
        self.app = app
        self.webForm = webForm
    }

    func waitForLoginForm() {
        let label = webForm.USERNAME_LABEL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(label)
    }

    func fillLoginForm(username: String, password: String) {
        let usernameField = app.webViews.textFields.element(boundBy: 0)
        let passwordField = app.webViews.secureTextFields.element(boundBy: 0)

        BaseTestCase().mozWaitForElementToExist(usernameField)
        usernameField.tapAndTypeText(username)

        BaseTestCase().mozWaitForElementToExist(passwordField)
        passwordField.tapAndTypeText(password)
    }

    func waitForUsernameField() {
        let usernameField = app.webViews.textFields.element(boundBy: 0)
        BaseTestCase().mozWaitForElementToExist(usernameField)
    }

    func tapUsernameField() {
        app.webViews.textFields.element(boundBy: 0).waitAndTap()
    }

    /// The "Use saved password" pill is missing from the accessibility tree on iOS 26, so when it can't be
    /// found, tap the spot it is drawn at: centred between the accessory bar's Next and Done buttons.
    func tapUseSavedPasswordButton() {
        let savedPasswordButton = webForm.USE_SAVED_PASSWORD_BUTTON.element(in: app)
        if savedPasswordButton.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) {
            savedPasswordButton.waitAndTap()
            return
        }
        if BaseTestCase().iPad() {
            tapUseSavedPasswordPillOnIPad()
            return
        }
        let nextButton = webForm.KEYBOARD_NEXT_BUTTON.element(in: app)
        let doneButton = webForm.KEYBOARD_DONE_BUTTON.element(in: app)
        BaseTestCase().waitForElementsToExist([nextButton, doneButton])
        let pillCenter = CGVector(
            dx: (nextButton.frame.maxX + doneButton.frame.minX) / 2,
            dy: nextButton.frame.midY
        )
        app.coordinate(withNormalizedOffset: .zero).withOffset(pillCenter).tap()
    }

    /// iPad has no Next and Done on the accessory bar, so the pill is trailing-aligned and sits right above
    /// the system shortcut bar; its Previous button lies horizontally within the pill.
    private func tapUseSavedPasswordPillOnIPad() {
        let pillOffsetAboveShortcutBar: CGFloat = 32
        let previousButton = webForm.IPAD_ASSISTANT_PREVIOUS_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(previousButton)
        let pillPoint = CGVector(
            dx: previousButton.frame.midX,
            dy: previousButton.frame.minY - pillOffsetAboveShortcutBar
        )
        app.coordinate(withNormalizedOffset: .zero).withOffset(pillPoint).tap()
    }

    func closeSavedLoginsSheet() {
        let closeButton = webForm.SAVED_LOGINS_SHEET_CLOSE_BUTTON.element(in: app)
        closeButton.waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(closeButton)
    }

    func assertUsernameFieldIsEmpty() {
        let usernameField = app.webViews.textFields.element(boundBy: 0)
        BaseTestCase().mozWaitForElementToExist(usernameField)
        let value = usernameField.value as? String ?? ""
        XCTAssertTrue(value.isEmpty, "The username should not be autofilled, found: \(value)")
    }
}
