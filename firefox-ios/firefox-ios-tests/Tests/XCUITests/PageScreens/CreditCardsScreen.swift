// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class CreditCardsScreen {
    private let app: XCUIApplication
    private let sel: CreditCardsSelectorsSet
    private let toolbarScreen: ToolbarScreen
    private let loginScreen: LoginSettingsScreen

    init(app: XCUIApplication, selectors: CreditCardsSelectorsSet = CreditCardsSelectors()) {
        self.app = app
        self.sel = selectors
        self.toolbarScreen = ToolbarScreen(app: app)
        self.loginScreen = LoginSettingsScreen(app: app)
    }

    private var addCardButton: XCUIElement { sel.ADD_CARD_BUTTON.element(in: app) }
    private var autofillTitle: XCUIElement { sel.AUTOFILL_TITLE.element(in: app) }
    private var saveAutofillSwitch: XCUIElement { sel.SAVE_AUTOFILL_SWITCH.element(in: app) }
    private var useSavedCardButton: XCUIElement { sel.USE_SAVED_CARD_BUTTON.element(in: app) }
    private var cardNumber: XCUIElement { sel.CARD_NUMBER_STATIC_TEXT.element(in: app) }
    private var cardNumberTextField: XCUIElement { sel.CARD_NUMBER_TEXT_FIELD.element(in: app)}

    func getSaveAndFillSwitch() -> XCUIElement {
        return saveAutofillSwitch.firstMatch
    }

    func unlockIfNeeded() {
        loginScreen.unlockLoginsView()
    }

    func waitForSectionVisible() {
        BaseTestCase().waitForElementsToExist([
            addCardButton,
            autofillTitle,
            saveAutofillSwitch
        ])
    }

    func openAddCreditCardForm() {
        addCardButton.waitAndTap()
    }

    func assertCardSaved(containing lastDigits: String, details: [String]) {
        BaseTestCase().waitForElementsToExist([
                app.tables.cells.element(boundBy: 1).buttons.elementContainingText(lastDigits)
            ])

        for detail in details {
            BaseTestCase().mozWaitForElementToExist(app.tables.cells.element(boundBy: 1).buttons[detail])
        }
    }

    func enableSaveAndFillIfDisabled() {
        BaseTestCase().mozWaitForElementToExist(saveAutofillSwitch)
        let value = saveAutofillSwitch.value as? String
        if value == "0" {
            saveAutofillSwitch.waitAndTap()
        }
    }

    func addNewCreditCard(name: String, cardNumber: String, expirationDate: String) {
        addCardButton.waitAndTap()
        let addCard = AddCreditCardScreen(app: app)
        addCard.addCreditCard(name: name, cardNumber: cardNumber, expirationDate: expirationDate)
    }

    func openSavedCard(at index: Int = 1) {
        let cell = app.tables.cells.element(boundBy: index)
        BaseTestCase().mozWaitForElementToExist(cell)
        cell.waitAndTap()
    }

    func disableSaveAndFillAndOpenAddCardForm() {
        BaseTestCase().mozWaitForElementToExist(sel.AUTOFILL_TITLE.element(in: app))

        let autofillSwitch = getSaveAndFillSwitch()
        BaseTestCase().mozWaitForElementToExist(autofillSwitch)

        if let value = autofillSwitch.value as? String, value == "1" {
            autofillSwitch.waitAndTap()
        }

        let updatedValue = autofillSwitch.value as? String
        XCTAssertEqual(updatedValue, "0", "Expected 'Save and Fill Payment Methods' to be OFF")

        addCardButton.waitAndTap()
    }

    func expirationDateFiveYearsFromNow() -> String {
        let futureDate = Calendar.current.date(byAdding: .year, value: 5, to: Date())!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMyy"
        return formatter.string(from: futureDate)
    }

    func getSaveAndFillSwitchValue() -> String {
        BaseTestCase().mozWaitForElementToExist(saveAutofillSwitch)
        return saveAutofillSwitch.value as? String ?? "0"
    }

    func assertNoAutofillPromptWhenEnteringCard() {
        var cardNumberField = sel.CARD_NUMBER_TEXT_FIELD.element(in: app)
        if #unavailable(iOS 17) {
            cardNumberField = sel.CARD_NUMBER_STATIC_TEXT.element(in: app)
        }

        BaseTestCase().mozWaitForElementToExist(cardNumberField)
        cardNumberField.waitAndTap()

        BaseTestCase().mozWaitForElementToNotExist(useSavedCardButton)

        let doneButton = sel.DONE_KEYBOARD_BUTTON.element(in: app)
        doneButton.tapIfExists()
    }

    func getCardNumberField() -> XCUIElement {
        if #unavailable(iOS 17) {
            return cardNumber
        } else {
            return cardNumberTextField
        }
    }

    func assertAutofillCreditCardExists() {
        BaseTestCase().mozWaitForElementToExist(saveAutofillSwitch)
    }

    func prepareForSavedCardPrompt() {
        if BaseTestCase().iPad() {
            let expMonth = sel.EXPIRATION_MONTH_FIELD.element(in: app)
            let expYear = sel.EXPIRATION_YEAR_FIELD.element(in: app)
            expMonth.waitAndTap()
            expYear.waitAndTap()
        } else {
            toolbarScreen.tapReloadButton()

            let cardNumberStaticText = sel.CARD_NUMBER_STATIC_TEXT.element(in: app)
            cardNumberStaticText.waitAndTap()
        }

        BaseTestCase().mozWaitForElementToExist(useSavedCardButton)
    }

    func waitForAddCreditCardValues() {
        BaseTestCase().waitForElementsToExist(
            [
                sel.ADD_CREDIT_CARD.element(in: app),
                sel.ADD_CREDIT_CARD_NAME_ON_CARD.element(in: app),
                sel.ADD_CREDIT_CARD_CARD_NUMBER.element(in: app),
                sel.ADD_CREDIT_CARD_EXPIRATION.element(in: app),
                sel.ADD_CREDIT_CARD_CLOSE.element(in: app),
                sel.ADD_CREDIT_CARD_SAVE.element(in: app)
            ]
        )
    }
}
