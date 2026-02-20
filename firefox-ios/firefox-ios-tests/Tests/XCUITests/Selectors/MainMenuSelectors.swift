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
    var SETTINGS_CELL: Selector { get }
    var all: [Selector] { get }
}

struct MainMenuSelectors: MainMenuSelectorSet {
    private enum IDs {
        static let desktopSite = AccessibilityIdentifiers.MainMenu.desktopSite
        static let bookmarks = AccessibilityIdentifiers.MainMenu.bookmarks
        static let history   = AccessibilityIdentifiers.MainMenu.history
        static let downloads = AccessibilityIdentifiers.MainMenu.downloads
        static let passwords = AccessibilityIdentifiers.MainMenu.passwords
        static let settings  = AccessibilityIdentifiers.MainMenu.settings
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

    let SETTINGS_CELL = Selector.tableCellById(
        IDs.settings,
        description: "Settings cell in Main Menu",
        groups: ["MainMenu"]
    )

    var all: [Selector] { [DESKTOP_SITE, BOOKMARKS_BUTTON, HISTORY_BUTTON, DOWNLOADS_BUTTON,
                           PASSWORDS_BUTTON, SETTINGS_CELL] }
}
