// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol BrowserSelectorsSet {
    var ADDRESS_BAR: Selector { get }
    var DOWNLOADS_TOAST_BUTTON: Selector { get }
    var BACK_BUTTON: Selector { get }
    var MENU_BUTTON: Selector { get }
    var STATIC_TEXT_MOZILLA: Selector { get }
    var STATIC_TEXT_EXAMPLE_DOMAIN: Selector { get }
    var CLEAR_TEXT_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct BrowserSelectors: BrowserSelectorsSet {
    private enum IDs {
        static let addressBar = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        static let backButton = AccessibilityIdentifiers.Toolbar.backButton
        static let menuButton = "Menu"
        static let clearTextLabel = "Clear text"
        static let downloadLabel = "Downloads"
    }

    let ADDRESS_BAR = Selector.textFieldId(
        IDs.addressBar,
        description: "Browser address bar",
        groups: ["browser"]
    )

    let DOWNLOADS_TOAST_BUTTON = Selector.buttonByLabel(
        IDs.downloadLabel,
        description: "Button in the toast/notification to go to downloads list",
        groups: ["browser", "downloads"]
    )

    let BACK_BUTTON = Selector.buttonId(
        IDs.backButton,
        description: "Back button",
        groups: ["browser"]
    )

    let MENU_BUTTON = Selector.buttonByLabel(
        IDs.menuButton,
        description: "Browser menu button",
        groups: ["browser"]
    )

    let STATIC_TEXT_MOZILLA = Selector.staticTextLabelContains(
        "Mozilla",
        description: "Any static text containing 'Mozilla'",
        groups: ["browser"]
    )

    let STATIC_TEXT_EXAMPLE_DOMAIN = Selector.staticTextByExactLabel(
        "Example Domain",
        description: "Static text 'Example Domain'",
        groups: ["browser"]
    )

    let CLEAR_TEXT_BUTTON = Selector.buttonByLabel(
        IDs.clearTextLabel,
        description: "Clear text button in URL bar",
        groups: ["browser"]
    )

    var all: [Selector] { [ADDRESS_BAR, DOWNLOADS_TOAST_BUTTON, BACK_BUTTON,
                           MENU_BUTTON, STATIC_TEXT_MOZILLA, STATIC_TEXT_EXAMPLE_DOMAIN,
                           CLEAR_TEXT_BUTTON]
    }
}
