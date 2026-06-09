// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol CreditCardsSelectorsSet {
    var ADD_CARD_BUTTON: Selector { get }
    var AUTOFILL_TITLE: Selector { get }
    var SAVE_AUTOFILL_SWITCH: Selector { get }
    var SAVED_CARD: Selector { get }
    var CARD_NUMBER_STATIC_TEXT: Selector { get }
    var USE_SAVED_CARD_BUTTON: Selector { get }
    var DONE_KEYBOARD_BUTTON: Selector { get }
    var EXPIRATION_MONTH_FIELD: Selector { get }
    var EXPIRATION_YEAR_FIELD: Selector { get }
    var ADD_CREDIT_CARD: Selector { get }
    var ADD_CREDIT_CARD_NAME_ON_CARD: Selector { get }
    var ADD_CREDIT_CARD_CARD_NUMBER: Selector { get }
    var ADD_CREDIT_CARD_EXPIRATION: Selector { get }
    var ADD_CREDIT_CARD_CLOSE: Selector { get }
    var ADD_CREDIT_CARD_SAVE: Selector { get }
    var CARD_NUMBER_TEXT_FIELD: Selector { get }
    func savedCardButton(containing text: String) -> Selector
    var all: [Selector] { get }
}

struct CreditCardsSelectors: CreditCardsSelectorsSet {
    private enum IDs {
        static let addCard = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.addCard
        static let autoFillTitle = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.autoFillCreditCards
        static let saveAutofillSwitch = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.saveAutofillCards
        static let savedCard = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.savedCards
        static let cardNumber = "Card Number:"
        static let useSavedCard = AccessibilityIdentifiers.Browser.KeyboardAccessory.creditCardAutofillButton
        static let doneButton = "KeyboardAccessory.doneButton"
        static let addCreditCard = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.addCreditCard
        static let addCreditCardNameOnCard = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.nameOnCard
        static let addCreditCardCardNumber = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.cardNumber
        static let addCreditCardExpiration = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.expiration
        static let addCreditCardClose = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.close
        static let addCreditCardSave = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.save
    }

    let ADD_CARD_BUTTON = Selector.buttonId(
        IDs.addCard,
        description: "Add Credit Card button",
        groups: ["creditcards"]
    )

    let AUTOFILL_TITLE = Selector.staticTextId(
        IDs.autoFillTitle,
        description: "Title label for Autofill Credit Cards section",
        groups: ["creditcards"]
    )

    let SAVE_AUTOFILL_SWITCH = Selector.switchByIdOrLabel(
        IDs.saveAutofillSwitch,
        description: "Switch to enable saving credit cards",
        groups: ["creditcards"]
    )

    let SAVED_CARD = Selector.staticTextByLabel(
        IDs.savedCard,
        description: "Saved cards subtitle in Credit Cards section",
        groups: ["creditcards"]
    )

    let CARD_NUMBER_STATIC_TEXT = Selector.staticTextByLabel(
        IDs.cardNumber,
        description: "Fallback static text for Card Number field on iOS < 17",
        groups: ["creditcards"]
    )

    let USE_SAVED_CARD_BUTTON = Selector.buttonByLabel(
        IDs.useSavedCard,
        description: "Use saved card button prompt",
        groups: ["creditcards"]
    )

    let DONE_KEYBOARD_BUTTON = Selector.buttonId(
        IDs.doneButton,
        description: "Done button on keyboard accessory",
        groups: ["creditcards"]
    )

    let EXPIRATION_MONTH_FIELD = Selector.textFieldId(
        "Expiration month:",
        description: "Expiration month field in credit card form",
        groups: ["creditcards"]
    )

    let EXPIRATION_YEAR_FIELD = Selector.textFieldId(
        "Expiration year:",
        description: "Expiration year field in credit card form",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD = Selector.staticTextId(
        IDs.addCreditCard,
        description: "Add Credit Card on Credit Card Page",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD_NAME_ON_CARD = Selector.staticTextId(
        IDs.addCreditCardNameOnCard,
        description: "Name on Card on Credit Card Page",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD_CARD_NUMBER = Selector.staticTextId(
        IDs.addCreditCardCardNumber,
        description: "Card number on Credit Card Page",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD_EXPIRATION = Selector.staticTextId(
        IDs.addCreditCardExpiration,
        description: "Credit Card Expiration on Credit Card Page",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD_CLOSE = Selector.buttonId(
        IDs.addCreditCardClose,
        description: "Close option on Credit Card Page",
        groups: ["creditcards"]
    )

    let ADD_CREDIT_CARD_SAVE = Selector.buttonId(
        IDs.addCreditCardSave,
        description: "Save option on Credit Card Page",
        groups: ["creditcards"]
    )

    let CARD_NUMBER_TEXT_FIELD = Selector.textFieldId(
        IDs.cardNumber,
        description: "Fallback text field for Card Number field ",
        groups: ["creditcards"]
    )

    func savedCardButton(containing text: String) -> Selector {
        Selector.buttonByLabel(
            text,
            description: "Saved credit card button containing \(text)",
            groups: ["creditcards"]
        )
    }

    var all: [Selector] { [ADD_CARD_BUTTON, AUTOFILL_TITLE, SAVE_AUTOFILL_SWITCH, SAVED_CARD,
                           CARD_NUMBER_STATIC_TEXT, USE_SAVED_CARD_BUTTON, DONE_KEYBOARD_BUTTON,
                           EXPIRATION_MONTH_FIELD, EXPIRATION_YEAR_FIELD, ADD_CREDIT_CARD, ADD_CREDIT_CARD_NAME_ON_CARD,
                           ADD_CREDIT_CARD_CARD_NUMBER, ADD_CREDIT_CARD_EXPIRATION, ADD_CREDIT_CARD_CLOSE,
                           ADD_CREDIT_CARD_SAVE, CARD_NUMBER_TEXT_FIELD] }
}
