// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ToolbarSelectorsSet {
    var SETTINGS_MENU_BUTTON: Selector { get }
    var TABS_BUTTON: Selector { get }
    var NEW_TAB_BUTTON: Selector { get }
    var BACK_BUTTON: Selector { get }
    var FORWARD_BUTTON: Selector { get }
    var TABTOOLBAR_MENUBUTTON: Selector { get }
    var RELOAD_BUTTON: Selector { get }
    var SHARE_BUTTON: Selector { get }
    var TRANSLATE_BUTTON: Selector { get }
    var TRANSLATE_LOADING_BUTTON: Selector { get }
    var TRANSLATE_ACTIVE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct ToolbarSelectors: ToolbarSelectorsSet {
    private enum IDs {
        static let settingsMenuButton = AccessibilityIdentifiers.Toolbar.settingsMenuButton
        static let tabsButton = AccessibilityIdentifiers.Toolbar.tabsButton
        static let newTabButton = AccessibilityIdentifiers.Toolbar.addNewTabButton
        static let backButton = AccessibilityIdentifiers.Toolbar.backButton
        static let forwardButton = AccessibilityIdentifiers.Toolbar.forwardButton
        static let tabToolbar_MenuButton = "TabToolbar.menuButton"
        static let reloadButton = AccessibilityIdentifiers.Toolbar.reloadButton
        static let shareButton = AccessibilityIdentifiers.Toolbar.shareButton
        static let translateButton = AccessibilityIdentifiers.Toolbar.translateButton
        static let translateLoadingButton = AccessibilityIdentifiers.Toolbar.translateLoadingButton
        static let translateActiveButton = AccessibilityIdentifiers.Toolbar.translateActiveButton
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

    let BACK_BUTTON = Selector.buttonId(
        IDs.backButton,
        description: "Back navigation button in the toolbar",
        groups: ["toolbar"]
    )

    let FORWARD_BUTTON = Selector.buttonId(
        IDs.forwardButton,
        description: "Forward navigation button in the toolbar",
        groups: ["toolbar"]
    )

    let TABTOOLBAR_MENUBUTTON = Selector.buttonId(
        IDs.tabToolbar_MenuButton,
        description: "TabToolbar Menu Button",
        groups: ["toolbar"]
    )

    let RELOAD_BUTTON = Selector.buttonId(
        IDs.reloadButton,
        description: "Reload button on browser toolbar",
        groups: ["browser", "toolbar"]
    )

    let SHARE_BUTTON = Selector.buttonId(
        IDs.shareButton,
        description: "Share button on browser toolbar",
        groups: ["browser", "toolbar"]
    )

    let TRANSLATE_BUTTON = Selector.buttonId(
        IDs.translateButton,
        description: "Translate button on browser toolbar",
        groups: ["browser", "toolbar", "translation"]
    )

    let TRANSLATE_LOADING_BUTTON = Selector.buttonId(
        IDs.translateLoadingButton,
        description: "Translate loading button on browser toolbar",
        groups: ["browser", "translation"]
    )

    let TRANSLATE_ACTIVE_BUTTON = Selector.buttonId(
        IDs.translateActiveButton,
        description: "Translate active button on browser toolbar",
        groups: ["browser", "toolbar", "translation"]
    )

    var all: [Selector] { [
        SETTINGS_MENU_BUTTON,
        TABS_BUTTON,
        NEW_TAB_BUTTON,
        BACK_BUTTON,
        FORWARD_BUTTON,
        TABTOOLBAR_MENUBUTTON,
        RELOAD_BUTTON,
        SHARE_BUTTON,
        TRANSLATE_BUTTON,
        TRANSLATE_LOADING_BUTTON,
        TRANSLATE_ACTIVE_BUTTON
    ] }
}
