// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol BrowserSelectorsSet {
    var ADDRESS_BAR: Selector { get }
    var DOWNLOADS_TOAST_BUTTON: Selector { get }
    var BACK_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct BrowserSelectors: BrowserSelectorsSet {
    private enum IDs {
        static let addressBar = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        static let backButton = AccessibilityIdentifiers.Toolbar.backButton
    }

    let ADDRESS_BAR = Selector.textFieldId(
        IDs.addressBar,
        description: "Browser address bar",
        groups: ["browser"]
    )

    let DOWNLOADS_TOAST_BUTTON = Selector.buttonByLabel(
        "Downloads",
        description: "Button in the toast/notification to go to downloads list",
        groups: ["browser", "downloads"]
    )

    let BACK_BUTTON = Selector.buttonId(
        IDs.backButton,
        description: "Back button",
        groups: ["browser"]
    )

    var all: [Selector] { [ADDRESS_BAR, DOWNLOADS_TOAST_BUTTON, BACK_BUTTON] }
}
