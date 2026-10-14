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
    var HOME_BUTTON: Selector { get }
    var TRANSLATE_BUTTON: Selector { get }
    var TRANSLATE_LOADING_BUTTON: Selector { get }
    var TRANSLATE_ACTIVE_BUTTON: Selector { get }
    var TRANSLATE_LANGUAGE_ENGLISH_OPTION: Selector { get }
    var SUMMARIZE_BUTTON: Selector { get }
    var CONTEXTUAL_HINT_CLOSE_BUTTON: Selector { get }
    var GOOGLE_LENS_TIP_TITLE: Selector { get }
    var SUMMARIZE_CONTEXTUAL_HINT: Selector { get }
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
        static let homeButton = AccessibilityIdentifiers.Toolbar.homeButton
        static let translateButton = AccessibilityIdentifiers.Toolbar.translateButton
        static let translateLoadingButton = AccessibilityIdentifiers.Toolbar.translateLoadingButton
        static let translateActiveButton = AccessibilityIdentifiers.Toolbar.translateActiveButton
        static let translateLanguageEnglishOption = "English"
        static let summarizeButton = AccessibilityIdentifiers.Toolbar.summarizeButton
        static let summarizeContextualHint = "Tap to summarize this page. Touch and hold for Reader View."
        static let contextualHintCloseButton = "Close"
        static let googleLensTipTitle = "Search With Google Lens"
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

    let HOME_BUTTON = Selector.buttonId(
        IDs.homeButton,
        description: "Home button in the toolbar",
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

    // Language option in the translation language picker action sheet, matched by its title.
    let TRANSLATE_LANGUAGE_ENGLISH_OPTION = Selector.buttonId(
        IDs.translateLanguageEnglishOption,
        description: "English option in the translation language picker",
        groups: ["translation"]
    )

    let SUMMARIZE_BUTTON = Selector.buttonId(
        IDs.summarizeButton,
        description: "Summarize (lightning) button in the address bar",
        groups: ["browser", "toolbar", "summarizer"]
    )

    // The CFR has no identifier, so it is matched by its description.
    let SUMMARIZE_CONTEXTUAL_HINT = Selector.staticTextByLabel(
        IDs.summarizeContextualHint,
        description: "Contextual hint pointing at the summarize button",
        groups: ["toolbar", "summarizer"]
    )

    let CONTEXTUAL_HINT_CLOSE_BUTTON = Selector.buttonByLabel(
        IDs.contextualHintCloseButton,
        description: "The \"x\" button of the contextual hint or tip shown on the toolbar",
        groups: ["toolbar"]
    )

    let GOOGLE_LENS_TIP_TITLE = Selector.staticTextByLabel(
        IDs.googleLensTipTitle,
        description: "Title of the one-time Google Lens tip shown when the address bar is focused",
        groups: ["toolbar"]
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
        HOME_BUTTON,
        TRANSLATE_BUTTON,
        TRANSLATE_LOADING_BUTTON,
        TRANSLATE_ACTIVE_BUTTON,
        TRANSLATE_LANGUAGE_ENGLISH_OPTION,
        SUMMARIZE_BUTTON,
        SUMMARIZE_CONTEXTUAL_HINT,
        CONTEXTUAL_HINT_CLOSE_BUTTON,
        GOOGLE_LENS_TIP_TITLE
    ] }
}
