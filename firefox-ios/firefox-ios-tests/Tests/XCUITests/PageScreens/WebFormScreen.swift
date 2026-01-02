// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

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
}
