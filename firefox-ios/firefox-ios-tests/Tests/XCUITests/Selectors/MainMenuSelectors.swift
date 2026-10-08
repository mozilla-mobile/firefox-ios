// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol MainMenuSelectorSet {
    var DESKTOP_SITE: Selector { get }
    var BOOKMARKS_BUTTON: Selector { get }
    var HISTORY_BUTTON: Selector { get }
    var DOWNLOADS_BUTTON: Selector { get }
    var PASSWORDS_BUTTON: Selector { get }
	var SIGN_IN_CELL: Selector { get }
    var SETTINGS_CELL: Selector { get }
    var BOOKMARK_PAGE: Selector { get }
    var SITE_PROTECTIONS: Selector { get }
    var PAGE_ZOOM: Selector { get }
    var READER_VIEW: Selector { get }
    var FIND_IN_PAGE: Selector { get }
    var SUMMARIZE_PAGE: Selector { get }
    var CLOSE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct MainMenuSelectors: MainMenuSelectorSet {
    private enum IDs {
        static let desktopSite = AccessibilityIdentifiers.MainMenu.desktopSite
        static let bookmarks = AccessibilityIdentifiers.MainMenu.bookmarks
        static let history   = AccessibilityIdentifiers.MainMenu.history
        static let downloads = AccessibilityIdentifiers.MainMenu.downloads
        static let passwords = AccessibilityIdentifiers.MainMenu.passwords
        static let signIn = AccessibilityIdentifiers.MainMenu.signIn
        static let settings  = AccessibilityIdentifiers.MainMenu.settings
        static let bookmarkPage = AccessibilityIdentifiers.MainMenu.bookmarkPage
        static let siteProtections = "Protections"
        static let pageZoom = AccessibilityIdentifiers.MainMenu.zoom
        static let readerView = AccessibilityIdentifiers.MainMenu.readerView
        static let findInPage = AccessibilityIdentifiers.MainMenu.findInPage
        static let summarizePage = AccessibilityIdentifiers.MainMenu.summarizePage
        static let closeButton = AccessibilityIdentifiers.MainMenu.HeaderView.closeButton
    }

    let DESKTOP_SITE = Selector.cellById(
        IDs.desktopSite,
        description: "Desktop Site",
        groups: ["MainMenu"]
    )

    let BOOKMARKS_BUTTON = Selector.tableCellButtonById(
        IDs.bookmarks,
        description: "Bookmarks button in Main Menu",
        groups: ["MainMenu"]
    )

    let HISTORY_BUTTON = Selector.tableCellButtonById(
        IDs.history,
        description: "History button in Main Menu",
        groups: ["MainMenu"]
    )

    let DOWNLOADS_BUTTON = Selector.tableCellButtonById(
        IDs.downloads,
        description: "Downloads button in Main Menu",
        groups: ["MainMenu"]
    )

    let PASSWORDS_BUTTON = Selector.tableCellButtonById(
        IDs.passwords,
        description: "Passwords button in Main Menu",
        groups: ["MainMenu"]
    )

	let SIGN_IN_CELL = Selector.cellById(
		IDs.signIn,
		description: "Sign In"
	)

    let SETTINGS_CELL = Selector.tableCellById(
        IDs.settings,
        description: "Settings cell in Main Menu",
        groups: ["MainMenu"]
    )

    let SITE_PROTECTIONS = Selector.buttonByLabel(
        IDs.siteProtections,
        description: "Protections button in the main menu header, opens the tracking protection panel",
        groups: ["menu", "privacy"]
    )

    let BOOKMARK_PAGE = Selector.tableCellById(
        IDs.bookmarkPage,
        description: "Bookmark page in Main Menu",
        groups: ["MainMenu"]
    )

    let PAGE_ZOOM = Selector.tableCellById(
        IDs.pageZoom,
        description: "Page Zoom cell in the expanded Main Menu",
        groups: ["MainMenu"]
    )

    let READER_VIEW = Selector.tableCellById(
        IDs.readerView,
        description: "Reader View cell in the expanded Main Menu",
        groups: ["MainMenu"]
    )

    let FIND_IN_PAGE = Selector.tableCellById(
        IDs.findInPage,
        description: "Find in Page cell in Main Menu",
        groups: ["MainMenu"]
    )

    let SUMMARIZE_PAGE = Selector.tableCellById(
        IDs.summarizePage,
        description: "Summarize Page cell in Main Menu, shown once the page is known to be summarizable",
        groups: ["MainMenu"]
    )

    let CLOSE_BUTTON = Selector.buttonId(
        IDs.closeButton,
        description: "Close button in the Main Menu header",
        groups: ["MainMenu"]
    )

    var all: [Selector] { [DESKTOP_SITE, BOOKMARKS_BUTTON, HISTORY_BUTTON, DOWNLOADS_BUTTON,
                           PASSWORDS_BUTTON, SIGN_IN_CELL, SETTINGS_CELL, BOOKMARK_PAGE,
                           SITE_PROTECTIONS, PAGE_ZOOM, READER_VIEW, FIND_IN_PAGE,
                           SUMMARIZE_PAGE, CLOSE_BUTTON] }
}
