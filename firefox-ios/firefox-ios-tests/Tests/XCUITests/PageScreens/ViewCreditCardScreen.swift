// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class ViewCreditCardScreen {
    private let app: XCUIApplication
    private let sel: ViewCreditCardSelectorsSet

    init(app: XCUIApplication, selectors: ViewCreditCardSelectorsSet = ViewCreditCardSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func waitForViewCardScreen(containing lastDigits: String) {
        if #available(iOS 26, *) {
            // https://github.com/mozilla-mobile/firefox-ios/issues/31079
            BaseTestCase().restartInBackground()
            BaseTestCase().unlockLoginsView()
            BaseTestCase().waitForElementsToExist([
                sel.NAVBAR_VIEW_CARD.element(in: app),
                sel.savedCardButton(containing: lastDigits).element(in: app)
            ])
        } else {
            BaseTestCase().waitForElementsToExist([
                sel.NAVBAR_VIEW_CARD.element(in: app),
                sel.savedCardButton(containing: lastDigits).element(in: app)
            ])
        }
    }

    func assertCardDetails(_ details: [String]) {
        for detail in details {
            if #available(iOS 26, *) {
                let textField = app.textFields[detail]
                BaseTestCase().mozWaitForElementToExist(textField)
                XCTAssertTrue(textField.exists, "\(detail) does not exist (textField)")
            } else if #available(iOS 16, *) {
                let button = app.buttons[detail]
                BaseTestCase().mozWaitForElementToExist(button)
                XCTAssertTrue(button.exists, "\(detail) does not exist (button)")
            } else {
                let label = app.staticTexts[detail]
                BaseTestCase().mozWaitForElementToExist(label)
                XCTAssertTrue(label.exists, "\(detail) does not exist (label)")
            }
        }
    }

    func goBackToSavedCardsSection() {
        let closeButton = sel.CLOSE_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(closeButton)
        closeButton.waitAndTap()

        let creditCardsScreen = CreditCardsSelectors()

        BaseTestCase().waitForElementsToExist([
            creditCardsScreen.AUTOFILL_TITLE.element(in: app),
            creditCardsScreen.SAVE_AUTOFILL_SWITCH.element(in: app),
            creditCardsScreen.SAVED_CARD.element(in: app)
        ])
    }
}
