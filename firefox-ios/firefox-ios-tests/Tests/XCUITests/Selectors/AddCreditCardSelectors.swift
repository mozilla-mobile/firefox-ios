// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol AddCreditCardSelectorsSet {
    var TITLE: Selector { get }
    var NAME_FIELD: Selector { get }
    var CARD_NUMBER_FIELD: Selector { get }
    var EXPIRATION_FIELD: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var NAME_FIELD_BUTTON: Selector { get }
    var CARD_NUMBER_FIELD_BUTTON: Selector { get }
    var EXPIRATION_FIELD_BUTTON: Selector { get }
    var SAVE_BUTTON: Selector { get }
    var INVALID_CARD_NUMBER_LABEL: Selector { get }
    var INVALID_EXPIRATION_LABEL: Selector { get }
    var USE_SAVED_CARD_BUTTON: Selector { get }
    var MANAGE_CARDS_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct AddCreditCardSelectors: AddCreditCardSelectorsSet {
    private enum IDs {
        static let addCreditCard = "Add Credit Card"
        static let nameOnCard = "Name on card"
        static let cardNumber = "Card number"
        static let expiration = "Expiration"
        static let close = "Close"
        static let nameButtonId = "name"
        static let numberButtonId = "number"
        static let expirationButtonId = "expiration"
        static let save = AccessibilityIdentifiers.Settings.CreditCards.AddCreditCard.save
        static let invalidCardNumberMessage = "Enter a valid card number"
        static let invalidExpirationDateMessage = "Enter a valid expiration date"
        static let usedSavedCardLabel = "Use saved card"
        static let manageCard = "Manage cards"
    }

    let TITLE = Selector.staticTextByLabel(
        IDs.addCreditCard,
        description: "Title on Add Credit Card screen",
        groups: ["addcreditcards"]
    )

    let NAME_FIELD = Selector.staticTextByLabel(
        IDs.nameOnCard,
        description: "Name on card field",
        groups: ["addcreditcards"]
    )

    let CARD_NUMBER_FIELD = Selector.staticTextByLabel(
        IDs.cardNumber,
        description: "Card number field",
        groups: ["addcreditcards"]
    )

    let EXPIRATION_FIELD = Selector.staticTextByLabel(
        IDs.expiration,
        description: "Expiration date field",
        groups: ["addcreditcards"]
    )

    let CLOSE_BUTTON = Selector.buttonByLabel(
        IDs.close,
        description: "Close button in Add Credit Card screen",
        groups: ["addcreditcards"]
    )

    let NAME_FIELD_BUTTON = Selector.buttonId(
        IDs.nameButtonId,
        description: "Button or field for 'Name on Card'",
        groups: ["addcreditcards"]
    )

    let CARD_NUMBER_FIELD_BUTTON = Selector.buttonId(
        IDs.numberButtonId,
        description: "Button or field for 'Card Number'",
        groups: ["addcreditcards"]
    )

    let EXPIRATION_FIELD_BUTTON = Selector.buttonId(
        IDs.expirationButtonId,
        description: "Button or field for 'Expiration date'",
        groups: ["addcreditcards"]
    )

    let SAVE_BUTTON = Selector.buttonId(
        IDs.save,
        description: "Save button in Add Credit Card screen",
        groups: ["addcreditcards"]
    )

    let INVALID_CARD_NUMBER_LABEL = Selector.staticTextByLabel(
        IDs.invalidCardNumberMessage,
        description: "Error message for invalid card number",
        groups: ["addcreditcards"]
    )

    let INVALID_EXPIRATION_LABEL = Selector.staticTextByLabel(
        IDs.invalidExpirationDateMessage,
        description: "Error message for invalid expiration date",
        groups: ["addcreditcards"]
    )

    let USE_SAVED_CARD_BUTTON = Selector.buttonByLabel(
        IDs.usedSavedCardLabel,
        description: "Prompt button to use a saved card",
        groups: ["addcreditcards"]
    )

    let MANAGE_CARDS_BUTTON = Selector.buttonByLabel(
        IDs.manageCard,
        description: "Manage cards button shown after using a saved card",
        groups: ["addcreditcards"]
    )

    var all: [Selector] { [TITLE, NAME_FIELD, CARD_NUMBER_FIELD, EXPIRATION_FIELD, CLOSE_BUTTON,
                           NAME_FIELD_BUTTON, CARD_NUMBER_FIELD_BUTTON, EXPIRATION_FIELD_BUTTON, SAVE_BUTTON,
                           INVALID_CARD_NUMBER_LABEL, INVALID_EXPIRATION_LABEL] }
}
