// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TranslationSettingsSelectorsSet {
    var NAVBAR: Selector { get }
    var BACK_BUTTON_iOS26: Selector { get }
    var BACK_BUTTON: Selector { get }
    var TRANSLATION_SWITCH: Selector { get }
    var all: [Selector] { get }
}

struct TranslationSettingsSelectors: TranslationSettingsSelectorsSet {
    private enum IDs {
        static let navBar              = AccessibilityIdentifiers.Settings.Translation.navigationBar
        static let translationSwitch   = AccessibilityIdentifiers.Settings.Translation.toggleSwitch
        static let backButtoniOS26     = AccessibilityIdentifiers.Settings.Translation.backButtoniOS26
        static let backButton          = AccessibilityIdentifiers.Settings.Translation.backButton
    }

    let NAVBAR = Selector.navigationBarId(
        IDs.navBar,
        description: "Translation settings navigation bar",
        groups: ["settings", "translation"]
    )

    let BACK_BUTTON_iOS26 = Selector.buttonId(
        IDs.backButtoniOS26,
        description: "Translation settings back button for iOS 26",
        groups: ["settings", "translation"]
    )

    let BACK_BUTTON = Selector.buttonByLabel(
        IDs.backButton,
        description: "Translation settings back button (< iOS 26)",
        groups: ["settings", "translation"]
    )

    let TRANSLATION_SWITCH = Selector.switchById(
        IDs.translationSwitch,
        description: "Switch for 'Translation Enabled' in Settings → Translation",
        groups: ["settings", "translation"]
    )

    var all: [Selector] {
        [NAVBAR, BACK_BUTTON_iOS26, BACK_BUTTON, TRANSLATION_SWITCH]
    }
}
