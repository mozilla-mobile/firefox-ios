// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class EditCreditCardScreen {
    private let app: XCUIApplication
    private let sel: EditCreditCardSelectorsSet

    init(app: XCUIApplication, selectors: EditCreditCardSelectorsSet = EditCreditCardSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var alertRemoveThisCard: XCUIElement { sel.ALERT_REMOVE_THIS_CARD.element(in: app) }
    private var cancelButton: XCUIElement { sel.CANCEL_BUTTON.element(in: app) }

    func openEditMode() {
        sel.EDIT_BUTTON.element(in: app).waitAndTap()
    }

    func tapRemoveCard() {
        sel.REMOVE_CARD_BUTTON.element(in: app).waitAndTap()
    }

    func waitForRemoveCardAlert() {
        BaseTestCase().waitForElementsToExist([
            alertRemoveThisCard,
            cancelButton,
            sel.REMOVE_BUTTON.element(in: app)
        ])
    }

    func cancelRemoval() {
        cancelButton.waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(alertRemoveThisCard)
        BaseTestCase().mozWaitForElementToExist(sel.NAVBAR_EDIT_CARD.element(in: app))
    }

    func confirmRemoval() {
        sel.REMOVE_BUTTON.element(in: app).waitAndTap()
    }

    func assertCardDeleted() {
        BaseTestCase().mozWaitForElementToExist(sel.AUTOFILL_TITLE.element(in: app))
        BaseTestCase().mozWaitForElementToNotExist(sel.SAVED_CARDS_LABEL.element(in: app))
        BaseTestCase().mozWaitForElementToNotExist(app.tables.cells.element(boundBy: 1))
    }
}
