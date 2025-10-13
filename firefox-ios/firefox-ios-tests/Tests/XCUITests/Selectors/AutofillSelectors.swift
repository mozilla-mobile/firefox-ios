// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol AutofillSelectorsSet {
    var KEYBOARD_AUTOFILL_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct AutofillSelectors: AutofillSelectorsSet {
    private enum IDs {
        static let addressAutofillButton = AccessibilityIdentifiers.Browser.KeyboardAccessory.addressAutofillButton
    }

    let KEYBOARD_AUTOFILL_BUTTON = Selector.buttonId(
        IDs.addressAutofillButton,
        description: "Keyboard accessory button for autofilling addresses",
        groups: ["autofill"]
    )

    var all: [Selector] { [KEYBOARD_AUTOFILL_BUTTON] }
}
