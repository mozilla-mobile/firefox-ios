// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class AutofillFormScreen {
    private let app: XCUIApplication
    private let sel: AutofillSelectorsSet

    init(app: XCUIApplication, selectors: AutofillSelectorsSet = AutofillSelectors()) {
        self.app = app
        self.sel = selectors
    }

    // Form fields

    func tapField(at index: Int) {
        app.webViews.textFields.element(boundBy: index).waitAndTap()
    }

    // iPad navigation keys

    func handleiPadNavigationKeys() {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        app.buttons["_previousTapped"].waitAndTap()
        app.buttons["_nextTapped"].waitAndTap()
    }

    // Autofill

    func tapKeyboardAccessoryAutofill() {
        let button = sel.KEYBOARD_AUTOFILL_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(button)
        button.waitAndTap()
    }

    func selectSavedAddress() {
        app.otherElements.buttons.elementContainingText("Address").waitAndTap()
    }

    // Validation

    func validateAutofillAddressInfo() {
        let addressInfo = ["Test", "organization test", "test address", "city test", "AL",
                           "123456", "US", "test@mozilla.com", "01234567"]
        for index in 0...addressInfo.count - 1 {
            XCTAssertEqual(app.webViews.textFields.element(boundBy: index).value! as? String, addressInfo[index])
        }
    }
}
