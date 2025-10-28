// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ToolbarSelectorsSet {
    var SETTINGS_MENU_BUTTON: Selector { get }
    var TABS_BUTTON: Selector { get }
    var NEW_TAB_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct ToolbarSelectors: ToolbarSelectorsSet {
    private enum IDs {
        static let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        static let tabsButton = AccessibilityIdentifiers.Toolbar.tabsButton
        static let newTabButton = AccessibilityIdentifiers.Toolbar.addNewTabButton
    }

    let SETTINGS_MENU_BUTTON = Selector.buttonId(
        IDs.settingsMenuButton,
        description: "Settings menu button on the toolbar",
        groups: ["toolbar"]
    )

    let TABS_BUTTON = Selector.buttonId(
        IDs.tabsButton,
        description: "Tabs button on the toolbar",
        groups: ["toolbar"]
    )

    let NEW_TAB_BUTTON = Selector.buttonId(
        IDs.newTabButton,
        description: "New Tab Button on Toolbar",
        groups: ["toolbar"]
    )

    var all: [Selector] { [SETTINGS_MENU_BUTTON, TABS_BUTTON] }
}
