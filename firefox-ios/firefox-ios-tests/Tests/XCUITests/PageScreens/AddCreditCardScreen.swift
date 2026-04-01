// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
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

    func tapCreditCardForm() {
        // https://github.com/mozilla-mobile/firefox-ios/issues/31079
        if #available(iOS 26, *) {
            sel.NAME_FIELD_BUTTON.element(in: app).waitAndTap()
        }
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
            var elementsToWait = [
                sel.NAME_FIELD_BUTTON.element(in: app),
                sel.CARD_NUMBER_FIELD_BUTTON.element(in: app),
                sel.EXPIRATION_FIELD_BUTTON.element(in: app)
            ]

            // Only check SAVE_BUTTON on iPhone
            if UIDevice.current.userInterfaceIdiom == .phone {
                elementsToWait.append(sel.SAVE_BUTTON.element(in: app))
            }

            BaseTestCase().waitForElementsToExist(elementsToWait)
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
        let nameField = sel.NAME_FIELD_BUTTON.element(in: app)
        nameField.waitAndTap()
        nameField.typeText(name)
    }

    private func fillCardNumber(_ number: String) {
        let cardNumber = sel.CARD_NUMBER_FIELD_BUTTON.element(in: app)
        cardNumber.waitAndTap()
        cardNumber.typeTextWithDelay(number, delay: 0.1)
    }

    private func fillExpiration(_ expiration: String) {
        creditCard_ExpirationFieldButton.waitAndTap()
        creditCard_ExpirationFieldButton.typeText(expiration)
    }

    private func retryCardNumberIfInvalid(_ number: String) {
        if creditCard_InvalidCardNumberMessage.exists {
            let cardNumber = sel.CARD_NUMBER_FIELD_BUTTON.element(in: app)
            cardNumber.waitAndTap()
            pressDelete()
            fillCardNumber(number)
            sel.EXPIRATION_FIELD_BUTTON.element(in: app).waitAndTap()
        }
    }

    private func retryExpirationIfInvalid(_ expiration: String) {
        if creditCard_InvalidExpirationMessage.exists {
            pressDelete()
            fillExpiration(expiration)
        }
    }

    func addCreditCard(name: String, cardNumber: String, expirationDate: String) {
        // https://github.com/mozilla-mobile/firefox-ios/issues/31079
        if #available(iOS 26, *) {
            tapCreditCardForm()
        }
        waitForCardFields()

        fillName(name)
        fillCardNumber(cardNumber)

        sel.EXPIRATION_FIELD_BUTTON.element(in: app).waitAndTap()
        retryCardNumberIfInvalid(cardNumber)

        fillExpiration(expirationDate)

        retryExpirationIfInvalid(expirationDate)

        if !creditCard_SaveButton.isEnabled {
            retryCardNumberIfInvalid(cardNumber)
            fillExpiration(expirationDate)
            retryExpirationIfInvalid(expirationDate)
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

    private func pressDelete() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            BaseTestCase().mozWaitForElementToExist(app.keyboards.keys["delete"])
            app.keyboards.keys["delete"].press(forDuration: 2.2)
        } else {
            BaseTestCase().mozWaitForElementToExist(app.keyboards.keys["Delete"])
            app.keyboards.keys["Delete"].press(forDuration: 2.2)
        }
    }

    private func typeExpiration(_ expiration: String) {
        creditCard_ExpirationFieldButton.typeText(expiration)
    }
}
