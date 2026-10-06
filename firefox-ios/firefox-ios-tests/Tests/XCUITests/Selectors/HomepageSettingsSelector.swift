// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol HomepageSettingsSelectorSet {
    var BOOKMARK_TOGGLE: Selector { get }
    var JUMP_BACK_IN_TOGGLE: Selector { get }
    var HOMEPAGE_SETTINGS_TABLE: Selector { get }
    var CUSTOM_URL_TEXT_FIELD: Selector { get }
    var SHORTCUTS_SETTINGS_CELL: Selector { get }
    var SHORTCUTS_STATUS_ON: Selector { get }
    var all: [Selector] { get }
}

struct HomepageSettingsSelectors: HomepageSettingsSelectorSet {
    private enum IDs {
        // Mirrors PrefsKeys.HomepageSettings.BookmarksSection, used as the switch identifier
        static let bookmarkToogle = "BookmarksSectionUserPrefsKey"
        // Mirrors PrefsKeys.HomepageSettings.JumpBackInSection, used as the switch identifier
        static let jumpBackInToggle = "JumpBackInSectionUserPrefsKey"
        static let customURLTextField = "HomeAsCustomURLTextField"
        static let shortcutsSettingsCell = AccessibilityIdentifiers
            .Settings
            .Homepage
            .CustomizeFirefox
            .Shortcuts
            .settingsPage
        // The row status has no accessibility identifier, it is matched on its label
        static let shortcutsStatusOn = "On"
    }

    let HOMEPAGE_SETTINGS_TABLE = Selector.firstTable(
        description: "Homepage settings table view (first table in hierarchy)",
        groups: ["homepage_settings"]
    )

    let BOOKMARK_TOGGLE = Selector.switchByIdOrLabel(
        IDs.bookmarkToogle,
        description: "Bookmark toggle in homepage settings",
        groups: ["homepage_settings"]
    )

    let JUMP_BACK_IN_TOGGLE = Selector.switchByIdOrLabel(
        IDs.jumpBackInToggle,
        description: "Jump back in toggle in homepage settings",
        groups: ["homepage_settings"]
    )

    let CUSTOM_URL_TEXT_FIELD = Selector.textFieldId(
        IDs.customURLTextField,
        description: "Custom URL text field of the current homepage section",
        groups: ["homepage_settings"]
    )

    let SHORTCUTS_SETTINGS_CELL = Selector.tableCellById(
        IDs.shortcutsSettingsCell,
        description: "Shortcuts row of the include on homepage section",
        groups: ["homepage_settings"]
    )

    let SHORTCUTS_STATUS_ON = Selector.staticTextByLabel(
        IDs.shortcutsStatusOn,
        description: "On status of the shortcuts row in homepage settings",
        groups: ["homepage_settings"]
    )

    var all: [Selector] {
        [
            BOOKMARK_TOGGLE,
            HOMEPAGE_SETTINGS_TABLE,
            JUMP_BACK_IN_TOGGLE,
            CUSTOM_URL_TEXT_FIELD,
            SHORTCUTS_SETTINGS_CELL,
            SHORTCUTS_STATUS_ON
        ]
    }
}
