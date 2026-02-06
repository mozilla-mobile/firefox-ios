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
    var CANCEL_BUTTON_URL_BAR: Selector { get }
    var PRIVATE_BROWSING: Selector { get }
    var CANCEL_BUTTON: Selector { get }
    var LINK_RFC_2606: Selector { get }
    var BOOK_OF_MOZILLA_TEXT: Selector { get }
    var ADDRESSTOOLBAR_LOCKICON: Selector { get }
    var TOPTABS_COLLECTIONVIEW: Selector { get }
    var MICROSURVEY_CLOSE_BUTTON: Selector { get }
    func linkElement(named name: String) -> Selector
    func linkPreview(named preview: String) -> Selector
    func webPageElement(with text: String) -> Selector
    var all: [Selector] { get }
}

struct BrowserSelectors: BrowserSelectorsSet {
    private enum IDs {
        static let addressBar = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        static let backButton = AccessibilityIdentifiers.Toolbar.backButton
        static let menuButton = "Menu"
        static let clearTextLabel = "Clear text"
        static let downloadLabel = "Downloads"
        static let cancelButtonUrlBar = AccessibilityIdentifiers.Browser.UrlBar.cancelButton
        static let privateBrowsingLabel = "Private Browsing"
        static let cancelButton = "Cancel"
        static let rfc = "RFC 2606"
        static let AddressToolbar_LockIcon = AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon
        static let topTabsCollectionView = AccessibilityIdentifiers.Browser.TopTabs.collectionView
        static let microsurveyCloseButton = AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
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

    let CANCEL_BUTTON_URL_BAR = Selector.buttonId(
        IDs.cancelButtonUrlBar,
        description: "Cancel Button in the Url Bar",
        groups: ["browser"]
    )

    let PRIVATE_BROWSING = Selector.staticTextId(
        IDs.privateBrowsingLabel,
        description: "Private Browsing Label",
        groups: ["browser"]
    )

    let CANCEL_BUTTON = Selector.buttonId(
        IDs.cancelButton,
        description: "Cancel Button",
        groups: ["browser"]
    )

    let LINK_RFC_2606 = Selector.linkById(
        IDs.rfc,
        description: "Link to RFC 2606 in example page",
        groups: ["browser", "webview"]
    )

    let BOOK_OF_MOZILLA_TEXT = Selector.staticTextByExactLabel(
        "The Book of Mozilla",
        description: "StaticText 'The Book of Mozilla' within table",
        groups: ["browser", "visualCheck"]
    )

    let ADDRESSTOOLBAR_LOCKICON = Selector.buttonId(
        IDs.AddressToolbar_LockIcon,
        description: "Lock Icon on the Address toolbar",
        groups: ["browser"]
    )

    let TOPTABS_COLLECTIONVIEW = Selector.collectionViewIdOrLabel(
        IDs.topTabsCollectionView,
        description: "Collection View of Top tabs",
        groups: ["browser"]
    )

    let MICROSURVEY_CLOSE_BUTTON = Selector.buttonId(
        IDs.microsurveyCloseButton,
        description: "Microsurvey close button",
        groups: ["browser", "microsurvey"]
    )

    func linkElement(named name: String) -> Selector {
        Selector.linkById(
            name,
            description: "Web link named \(name)",
            groups: ["browser", "webview"]
        )
    }

    func linkPreview(named preview: String) -> Selector {
        Selector.staticTextByExactLabel(
            preview,
            description: "Long-press link preview label",
            groups: ["browser", "webview"]
        )
    }

    func webPageElement(with text: String) -> Selector {
        Selector.staticTextByExactLabel(
            text,
            description: "Web page text",
            groups: ["browser", "webview"]
        )
    }

    var all: [Selector] { [ADDRESS_BAR, DOWNLOADS_TOAST_BUTTON, BACK_BUTTON,
                           MENU_BUTTON, STATIC_TEXT_MOZILLA, STATIC_TEXT_EXAMPLE_DOMAIN,
                           CLEAR_TEXT_BUTTON, CANCEL_BUTTON_URL_BAR, PRIVATE_BROWSING, CANCEL_BUTTON,
                           LINK_RFC_2606, BOOK_OF_MOZILLA_TEXT, ADDRESSTOOLBAR_LOCKICON, TOPTABS_COLLECTIONVIEW,
                           MICROSURVEY_CLOSE_BUTTON]
    }
}
