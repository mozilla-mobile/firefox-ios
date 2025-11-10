// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

final class AddCreditCardScreen {
    private let app: XCUIApplication
    private let sel: AddCreditCardSelectorsSet
    private var loginScreen: LoginSettingsScreen

    init(app: XCUIApplication, selectors: AddCreditCardSelectorsSet = AddCreditCardSelectors()) {
        self.app = app
        self.sel = selectors
        self.loginScreen = LoginSettingsScreen(app: app)
    }

    private var creditCard_NameField: XCUIElement { sel.NAME_FIELD.element(in: app) }
    private var creditCard_TitleField: XCUIElement { sel.TITLE.element(in: app) }
    private var creditCard_CardNumberField: XCUIElement { sel.CARD_NUMBER_FIELD.element(in: app)}
    private var creditCard_ExpirationField: XCUIElement { sel.EXPIRATION_FIELD.element(in: app)}
    private var creditCard_ExpirationFieldButton: XCUIElement { sel.EXPIRATION_FIELD_BUTTON.element(in: app)}
    private var creditCard_CloseButton: XCUIElement { sel.CLOSE_BUTTON.element(in: app)}
    private var creditCard_SaveButton: XCUIElement { sel.SAVE_BUTTON.element(in: app)}
    private var creditCard_InvalidCardNumberMessage: XCUIElement { sel.INVALID_CARD_NUMBER_LABEL.element(in: app)}
    private var creditCard_InvalidExpirationMessage: XCUIElement { sel.INVALID_EXPIRATION_LABEL.element(in: app)}
    private var creditCard_UseSavedCardButton: XCUIElement { sel.USE_SAVED_CARD_BUTTON.element(in: app)}
    private var creditCard_ManageCardButton: XCUIElement { sel.MANAGE_CARDS_BUTTON.element(in: app)}

    func waitForFormVisible() {
        BaseTestCase().waitForElementsToExist([
            creditCard_TitleField,
            creditCard_NameField,
            creditCard_CardNumberField,
            creditCard_ExpirationField,
            creditCard_CloseButton,
            creditCard_SaveButton
        ])
    }

    func fillCreditCard(name: String, number: String, expiration: String) {
        creditCard_NameField.waitAndTap()
        loginScreen.enterTextInField(typedText: name)

        creditCard_CardNumberField.waitAndTap()
        loginScreen.enterTextInField(typedText: number)

        creditCard_ExpirationField.waitAndTap()
        loginScreen.enterTextInField(typedText: expiration)

        creditCard_SaveButton.waitAndTap()
    }

    func waitForCardFields() {
        BaseTestCase().waitForElementsToExist([
            sel.NAME_FIELD_BUTTON.element(in: app),
            sel.CARD_NUMBER_FIELD_BUTTON.element(in: app),
            sel.EXPIRATION_FIELD_BUTTON.element(in: app),
            sel.SAVE_BUTTON.element(in: app)
        ])
    }

    func fillCardFields(name: String, number: String, expiration: String) {
        creditCard_NameField.waitAndTap()
        loginScreen.enterTextInField(typedText: name)

        creditCard_CardNumberField.waitAndTap()
        loginScreen.enterTextInField(typedText: number)

        creditCard_ExpirationFieldButton.waitAndTap()
        loginScreen.enterTextInField(typedText: expiration)
    }

    func tapSave() {
        creditCard_SaveButton.waitAndTap()
    }

    private func fillName(_ name: String) {
        sel.NAME_FIELD_BUTTON.element(in: app).waitAndTap()
        loginScreen.enterTextInField(typedText: name)
    }

    private func fillCardNumber(_ number: String) {
        sel.CARD_NUMBER_FIELD_BUTTON.element(in: app).waitAndTap()
        loginScreen.enterTextInField(typedText: number)
    }

    private func fillExpiration(_ expiration: String) {
        creditCard_ExpirationFieldButton.waitAndTap()
        loginScreen.enterTextInField(typedText: expiration)
    }

    private func retryCardNumberIfInvalid(_ number: String) {
        if creditCard_InvalidCardNumberMessage.exists {
            fillCardNumber(number)
        }
    }

    private func retryExpirationIfInvalid(_ expiration: String) {
        if creditCard_InvalidExpirationMessage.exists {
            fillExpiration(expiration)
        }
    }

    func addCreditCard(name: String, cardNumber: String, expirationDate: String) {
        waitForCardFields()

        fillName(name)
        fillCardNumber(cardNumber)
        fillExpiration(expirationDate)

        retryCardNumberIfInvalid(cardNumber)
        retryExpirationIfInvalid(expirationDate)

        if !creditCard_SaveButton.isEnabled {
            fillCardNumber(cardNumber)
            fillExpiration(expirationDate)
            BaseTestCase().mozWaitForElementToExist(creditCard_SaveButton)
        }

        creditCard_SaveButton.waitAndTap()
    }

    func interactWithCreditCardForm() {
        var cardField = creditCard_CardNumberField
        if #unavailable(iOS 17) {
            cardField = creditCard_CardNumberField
        }

        BaseTestCase().mozWaitForElementToExist(cardField)

        if BaseTestCase().iPad() {
            cardField.waitAndTap()
            creditCard_ExpirationField.waitAndTap()
        }

        cardField.waitAndTap()
    }

    func useSavedCardPrompt() {
        BaseTestCase().mozWaitForElementToExist(creditCard_UseSavedCardButton)
        creditCard_UseSavedCardButton.waitAndTap()

        loginScreen.unlockLoginsView()

        BaseTestCase().waitForElementsToExist([
            creditCard_UseSavedCardButton,
            creditCard_ManageCardButton
        ])
    }
}
