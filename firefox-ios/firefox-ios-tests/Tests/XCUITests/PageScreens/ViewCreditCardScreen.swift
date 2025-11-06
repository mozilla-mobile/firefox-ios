// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class ViewCreditCardScreen {
    private let app: XCUIApplication
    private let sel: ViewCreditCardSelectorsSet

    init(app: XCUIApplication, selectors: ViewCreditCardSelectorsSet = ViewCreditCardSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func waitForViewCardScreen(containing lastDigits: String) {
        BaseTestCase().waitForElementsToExist([
            sel.NAVBAR_VIEW_CARD.element(in: app),
            sel.savedCardButton(containing: lastDigits).element(in: app)
        ])
    }

    func assertCardDetails(_ details: [String]) {
        for detail in details {
            let element = sel.cardDetailLabel(detail).element(in: app)
            BaseTestCase().mozWaitForElementToExist(element)
            XCTAssertTrue(element.exists, "\(detail) does not exist")
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
