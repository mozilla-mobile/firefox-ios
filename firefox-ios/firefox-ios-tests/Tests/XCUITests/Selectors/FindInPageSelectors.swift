// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol FindInPageSelectorsSet {
    var FIND_NEXT_BUTTON: Selector { get }
    var FIND_PREVIOUS_BUTTON: Selector { get }
    var FIND_SEARCH_FIELD_IOS: Selector { get } // searchField for iOS 16+
    var FIND_SEARCH_FIELD_LEGACY: Selector { get } // textField for iOS < 16
    var all: [Selector] { get }
    func resultsCount(text: String) -> Selector
}

struct FindInPageSelectors: FindInPageSelectorsSet {
    private enum IDs {
        static let findNextButton = AccessibilityIdentifiers.FindInPage.findNextButton
        static let findPreviousButton = AccessibilityIdentifiers.FindInPage.findPreviousButton
        // The IDs for iOS 16 are different
        static let searchFieldLegacy = "FindInPage.searchField"
        static let searchFieldiOS = "find.searchField"
    }

    let FIND_NEXT_BUTTON = Selector.buttonId(
        IDs.findNextButton,
        description: "Find Next button in Find In Page bar",
        groups: ["findinpage"]
    )

    let FIND_PREVIOUS_BUTTON = Selector.buttonId(
        IDs.findPreviousButton,
        description: "Find Previous button in Find In Page bar",
        groups: ["findinpage"]
    )

    let FIND_SEARCH_FIELD_IOS = Selector.searchFieldById(
        IDs.searchFieldiOS,
        description: "Find In Page search field (iOS 16+)",
        groups: ["findinpage"]
    )

    let FIND_SEARCH_FIELD_LEGACY = Selector.textFieldId(
        IDs.searchFieldLegacy,
        description: "Find In Page search field (iOS < 16)",
        groups: ["findinpage"]
    )

    // Selector for the result label ("1 of 6")
    func resultsCount(text: String) -> Selector {
        Selector.staticTextByExactLabel(
            text,
            description: "Find In Page results count: \(text)",
            groups: ["findinpage"]
        )
    }

    var all: [Selector] {
        [FIND_NEXT_BUTTON, FIND_PREVIOUS_BUTTON, FIND_SEARCH_FIELD_IOS, FIND_SEARCH_FIELD_LEGACY]
    }
}
