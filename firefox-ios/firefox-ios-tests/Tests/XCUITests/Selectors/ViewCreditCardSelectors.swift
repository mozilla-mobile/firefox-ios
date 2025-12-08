// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ViewCreditCardSelectorsSet {
    var NAVBAR_VIEW_CARD: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    func savedCardButton(containing text: String) -> Selector
    func cardDetailLabel(_ text: String) -> Selector
    var all: [Selector] { get }
}

struct ViewCreditCardSelectors: ViewCreditCardSelectorsSet {
    private enum IDs {
        static let viewCardNavBar = "View Card"
        static let closeButton = AccessibilityIdentifiers.Settings.CreditCards.ViewCreditCard.close
    }

    let NAVBAR_VIEW_CARD = Selector.navigationBarByTitle(
        IDs.viewCardNavBar,
        description: "Navigation bar title in View Card screen",
        groups: ["viewcreditcards"]
    )

    let CLOSE_BUTTON = Selector.buttonByLabel(
        IDs.closeButton,
        description: "Close button in View Credit Card screen",
        groups: ["viewcreditcards"]
    )

    func savedCardButton(containing text: String) -> Selector {
        Selector.buttonLabelContains(
            text,
            description: "Saved credit card button containing \(text)",
            groups: ["viewcreditcards"]
        )
    }

    func cardDetailLabel(_ text: String) -> Selector {
        Selector.anyId(
            text,
            description: "Card detail label or button '\(text)'",
            groups: ["viewcreditcards"]
        )
    }

    var all: [Selector] { [NAVBAR_VIEW_CARD, CLOSE_BUTTON] }
}
