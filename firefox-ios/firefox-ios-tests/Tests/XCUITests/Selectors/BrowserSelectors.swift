// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol BrowserSelectorsSet {
    var ADDRESS_BAR: Selector { get }
    var SEARCH_ENGINE_LOGO: Selector { get }
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
    var BOOK_OF_MOZILLA_VERSE_TEXT: Selector { get }
    var ADDRESSTOOLBAR_LOCKICON: Selector { get }
    var ADDRESSTOOLBAR_LOCKICON_OFF: Selector { get }
    var TOPTABS_COLLECTIONVIEW: Selector { get }
    var MICROSURVEY_CLOSE_BUTTON: Selector { get }
    var BOOK_OF_MOZILLA_TEXT_IN_TABLE: Selector { get }
    var SAVE_BUTTON: Selector { get }
    var CLIPBOARD_TOAST: Selector { get }
    var BOOKMARK_SAVED_TOAST: Selector { get }
    var PRIVATE_MODE_HOMEPAGE_TITLE: Selector { get }
    var PRIVATE_MODE_HOMEPAGE_LINK: Selector { get }
    var SEARCH_SETTINGS_BUTTON: Selector { get }
    var SPONSORED_LABEL: Selector { get }
    var PASTE_BUTTON: Selector { get }
    var OPEN_DESIGNATED_URL_BUTTON: Selector { get }
    var ADDRESS_BAR_CONTEXT_MENU: Selector { get }
    var CONTEXT_MENU_PASTE_AND_GO: Selector { get }
    var CONTEXT_MENU_PASTE: Selector { get }
    var CONTEXT_MENU_COPY_ADDRESS: Selector { get }
    var CONTEXT_MENU_CLOSE_BUTTON: Selector { get }
    func linkElement(named name: String) -> Selector
    func linkPreview(named preview: String) -> Selector
    func webPageElement(with text: String) -> Selector
    var all: [Selector] { get }
}

struct BrowserSelectors: BrowserSelectorsSet {
    private enum IDs {
        static let addressBar = AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField
        static let searchEngineLogo = AccessibilityIdentifiers.Browser.AddressToolbar.searchEngine
        static let backButton = AccessibilityIdentifiers.Toolbar.backButton
        static let menuButton = "Menu"
        static let clearTextLabel = "Clear text"
        static let downloadLabel = "Downloads"
        static let cancelButtonUrlBar = AccessibilityIdentifiers.Browser.UrlBar.cancelButton
        static let privateBrowsingLabel = "Private Browsing"
        static let cancelButton = "Cancel"
        static let rfc = "RFC 2606"
        static let AddressToolbar_LockIcon = AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon
        static let AddressToolbar_LockIcon_Off = AccessibilityIdentifiers.Browser.AddressToolbar.lockIconOff
        static let topTabsCollectionView = AccessibilityIdentifiers.Browser.TopTabs.collectionView
        static let microsurveyCloseButton = AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
        static let saveButton = "Save"
        static let clipboardToast = "Fennec pasted from CoreSimulatorBridge"
        static let bookmarkSavedToast = "Saved in"
        static let privateModeHomepageTitle = "PrivateMode.Homepage.Title"
        static let privateModeHomepageLink = AccessibilityIdentifiers.PrivateMode.Homepage.link
        static let bookOfMozilla = "The Book of Mozilla"
        static let bookOfMozillaVerseText = "And the beast shall come forth"
        static let searchSettingsButton = "Search Settings"
        static let sponsoredLabel = "Sponsored"
        // In-page button of the test-window-open-on-tap fixture
        static let openDesignatedURLButton = "Open designated URL"
        static let addressBarContextMenu = AccessibilityIdentifiers.Photon.tableView
        static let contextMenuPasteAndGo = AccessibilityIdentifiers.Photon.pasteAndGoAction
        static let contextMenuPaste = AccessibilityIdentifiers.Photon.pasteAction
        static let contextMenuCopyAddress = AccessibilityIdentifiers.Photon.copyAddressAction
        static let contextMenuCloseButton = AccessibilityIdentifiers.Photon.closeButton
    }

    let ADDRESS_BAR = Selector.textFieldId(
        IDs.addressBar,
        description: "Browser address bar",
        groups: ["browser"]
    )

    let SEARCH_ENGINE_LOGO = Selector.imageId(
        IDs.searchEngineLogo,
        description: "Search engine logo in the address toolbar",
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
        TestLabels.exampleDomain,
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
        IDs.bookOfMozilla,
        description: "StaticText 'The Book of Mozilla' within table",
        groups: ["browser", "visualCheck"]
    )

    // The "The Book of Mozilla" heading sits below the fold, and the accessibility tree only exposes
    // the visible part of a web page, so the opening verse is what identifies this page on screen.
    let BOOK_OF_MOZILLA_VERSE_TEXT = Selector.staticTextLabelContains(
        IDs.bookOfMozillaVerseText,
        description: "Opening verse of the Mozilla book test page",
        groups: ["browser", "webview"]
    )

    let ADDRESSTOOLBAR_LOCKICON = Selector.buttonId(
        IDs.AddressToolbar_LockIcon,
        description: "Lock Icon on the Address toolbar",
        groups: ["browser"]
    )

    let ADDRESSTOOLBAR_LOCKICON_OFF = Selector.buttonId(
        IDs.AddressToolbar_LockIcon_Off,
        description: "Lock Icon OFF on the Address toolbar",
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

    let BOOK_OF_MOZILLA_TEXT_IN_TABLE = Selector.staticTextInTablesByLabel(
        "The Book of Mozilla",
        description: "StaticText 'The Book of Mozilla' within table",
        groups: ["browser", "visualCheck"]
    )

    let SAVE_BUTTON = Selector.buttonByLabel(
        IDs.saveButton,
        description: "Save button for bookmarks and general actions",
        groups: ["browser", "bookmarks"]
    )

    let CLIPBOARD_TOAST = Selector.staticTextByLabel(
        IDs.clipboardToast,
        description: "Clipboard paste notification toast from simulator",
        groups: ["browser", "system"]
    )

    let BOOKMARK_SAVED_TOAST = Selector.staticTextLabelContains(
        IDs.bookmarkSavedToast,
        description: "Toast notification shown after a page is saved as a bookmark",
        groups: ["browser", "bookmarks"]
    )

    let PRIVATE_MODE_HOMEPAGE_LINK = Selector.anyElementById(
        IDs.privateModeHomepageLink,
        description: "\"Who might be able to see my activity?\" link on the private homepage",
        groups: ["browser", "private_browsing"]
    )

    let PRIVATE_MODE_HOMEPAGE_TITLE = Selector.staticTextId(
        IDs.privateModeHomepageTitle,
        description: "Private mode homepage title message",
        groups: ["browser", "private-mode"]
    )

    let SEARCH_SETTINGS_BUTTON = Selector.buttonByLabel(
        IDs.searchSettingsButton,
        description: "'Search Settings' button in the search suggestions scroll view",
        groups: ["browser", "search"]
    )

    let SPONSORED_LABEL = Selector.staticTextId(
        IDs.sponsoredLabel,
        description: "'Sponsored' label on a sponsored search suggestion",
        groups: ["browser", "search"]
    )

    let OPEN_DESIGNATED_URL_BUTTON = Selector.buttonByLabel(
        IDs.openDesignatedURLButton,
        description: "In-page button that opens the designated URL in a new tab",
        groups: ["browser", "webview"]
    )

    let PASTE_BUTTON = Selector.otherElementsButtonByLabel(
        "Paste",
        description: "Paste button in the address bar edit callout",
        groups: ["browser"]
    )

    // MARK: - Address bar long press menu

    let ADDRESS_BAR_CONTEXT_MENU = Selector.tableIdOrLabel(
        IDs.addressBarContextMenu,
        description: "Context menu presented by long pressing the address bar",
        groups: ["browser", "addressBarContextMenu"]
    )

    let CONTEXT_MENU_PASTE_AND_GO = Selector.tableCellButtonById(
        IDs.contextMenuPasteAndGo,
        description: "'Paste & Go' option in the address bar long press menu",
        groups: ["browser", "addressBarContextMenu"]
    )

    let CONTEXT_MENU_PASTE = Selector.tableCellButtonById(
        IDs.contextMenuPaste,
        description: "'Paste' option in the address bar long press menu",
        groups: ["browser", "addressBarContextMenu"]
    )

    let CONTEXT_MENU_COPY_ADDRESS = Selector.tableCellButtonById(
        IDs.contextMenuCopyAddress,
        description: "'Copy Address' option in the address bar long press menu",
        groups: ["browser", "addressBarContextMenu"]
    )

    let CONTEXT_MENU_CLOSE_BUTTON = Selector.buttonId(
        IDs.contextMenuCloseButton,
        description: "Close button of the address bar long press menu",
        groups: ["browser", "addressBarContextMenu"]
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

    var all: [Selector] { [ADDRESS_BAR, SEARCH_ENGINE_LOGO, DOWNLOADS_TOAST_BUTTON, BACK_BUTTON,
                           MENU_BUTTON, STATIC_TEXT_MOZILLA, STATIC_TEXT_EXAMPLE_DOMAIN,
                           CLEAR_TEXT_BUTTON, CANCEL_BUTTON_URL_BAR, PRIVATE_BROWSING, CANCEL_BUTTON,
                           LINK_RFC_2606, BOOK_OF_MOZILLA_TEXT, BOOK_OF_MOZILLA_VERSE_TEXT,
                           ADDRESSTOOLBAR_LOCKICON, ADDRESSTOOLBAR_LOCKICON_OFF,
                           TOPTABS_COLLECTIONVIEW, MICROSURVEY_CLOSE_BUTTON, BOOK_OF_MOZILLA_TEXT_IN_TABLE,
                           SAVE_BUTTON, CLIPBOARD_TOAST, PRIVATE_MODE_HOMEPAGE_TITLE, PRIVATE_MODE_HOMEPAGE_LINK,
                           PASTE_BUTTON, SEARCH_SETTINGS_BUTTON, SPONSORED_LABEL,
                           OPEN_DESIGNATED_URL_BUTTON, ADDRESS_BAR_CONTEXT_MENU,
                           CONTEXT_MENU_PASTE_AND_GO, CONTEXT_MENU_PASTE,
                           CONTEXT_MENU_COPY_ADDRESS, CONTEXT_MENU_CLOSE_BUTTON]
    }
}
