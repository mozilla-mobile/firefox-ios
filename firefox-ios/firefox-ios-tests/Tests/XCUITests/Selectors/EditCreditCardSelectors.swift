// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol EditCreditCardSelectorsSet {
    var EDIT_BUTTON: Selector { get }
    var REMOVE_CARD_BUTTON: Selector { get }
    var ALERT_REMOVE_THIS_CARD: Selector { get }
    var CANCEL_BUTTON: Selector { get }
    var REMOVE_BUTTON: Selector { get }
    var NAVBAR_EDIT_CARD: Selector { get }
    var AUTOFILL_TITLE: Selector { get }
    var SAVED_CARDS_LABEL: Selector { get }
    var all: [Selector] { get }
}

struct EditCreditCardSelectors: EditCreditCardSelectorsSet {
    private enum IDs {
        static let editButton = "Edit"
        static let removeCard = "Remove Card"
        static let removeThisCard = AccessibilityIdentifiers.Settings.CreditCards.EditCreditCard.removeThisCard
        static let cancel = "Cancel"
        static let remove = "Remove"
        static let editCardNavBar = "Edit Card"
        static let autofillTitle = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.autoFillCreditCards
        static let savedCardsLabel = AccessibilityIdentifiers.Settings.CreditCards.AutoFillCreditCard.savedCards
    }

    let EDIT_BUTTON = Selector.buttonByLabel(
        IDs.editButton,
        description: "Edit button on View Credit Card screen",
        groups: ["settings", "creditcards"]
    )

    let REMOVE_CARD_BUTTON = Selector.buttonByLabel(
        IDs.removeCard,
        description: "Remove card button in Edit Credit Card screen",
        groups: ["settings", "creditcards"]
    )

    let ALERT_REMOVE_THIS_CARD = Selector.alertByTitle(
        IDs.removeThisCard,
        description: "Alert shown when removing a card",
        groups: ["settings", "creditcards"]
    )

    let CANCEL_BUTTON = Selector.buttonByLabel(
        IDs.cancel,
        description: "Cancel button in Remove Card alert",
        groups: ["settings", "creditcards"]
    )

    let REMOVE_BUTTON = Selector.buttonByLabel(
        IDs.remove,
        description: "Remove button in Remove Card alert",
        groups: ["settings", "creditcards"]
    )

    let NAVBAR_EDIT_CARD = Selector.navigationBarByTitle(
        IDs.editCardNavBar,
        description: "Navigation bar title in Edit Credit Card screen",
        groups: ["settings", "creditcards"]
    )

    let AUTOFILL_TITLE = Selector.staticTextByLabel(
        IDs.autofillTitle,
        description: "Autofill Credit Cards title after deletion",
        groups: ["settings", "creditcards"]
    )

    let SAVED_CARDS_LABEL = Selector.staticTextByLabel(
        IDs.savedCardsLabel,
        description: "Saved Cards label visible before deletion",
        groups: ["settings", "creditcards"]
    )

    var all: [Selector] {
        [EDIT_BUTTON, REMOVE_CARD_BUTTON, ALERT_REMOVE_THIS_CARD,
         CANCEL_BUTTON, REMOVE_BUTTON, NAVBAR_EDIT_CARD,
         AUTOFILL_TITLE, SAVED_CARDS_LABEL]
    }
}
