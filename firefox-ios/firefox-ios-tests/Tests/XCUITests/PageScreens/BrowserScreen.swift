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
        let backButton = sel.BACK_BUTTON.element(in: app)
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

    private func assertUserAgentTextExists(_ text: String, timeout: TimeInterval = TIMEOUT) {
        let pred = NSPredicate(
            format: "elementType == %d AND label == %@",
            XCUIElement.ElementType.staticText.rawValue,
            text
        )
        let query = app.webViews.descendants(matching: .staticText).matching(pred)
        let element = query.firstMatch

        BaseTestCase().mozWaitForElementToExist(element, timeout: timeout)
        XCTAssertTrue(element.exists, "Expected UA text '\(text)' was not found in the web view.")
    }

    func assertDesktopUserAgentIsDisplayed(timeout: TimeInterval = TIMEOUT) {
        assertUserAgentTextExists("DESKTOP_UA", timeout: timeout)
    }

    func assertMobileUserAgentIsDisplayed(timeout: TimeInterval = TIMEOUT) {
        assertUserAgentTextExists("MOBILE_UA", timeout: timeout)
    }

    func handleIos15ToastIfNecessary() {
        if #unavailable(iOS 16) {
            // iOS 15 displays a toast that covers the reload button
            sleep(2)
        }
    }

    func tapDownloadsToastButton() {
        let downloadsButton = sel.DOWNLOADS_TOAST_BUTTON.element(in: app)
        downloadsButton.waitAndTap()
    }
}
