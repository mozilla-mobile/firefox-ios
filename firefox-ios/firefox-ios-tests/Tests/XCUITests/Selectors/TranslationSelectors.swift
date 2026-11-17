// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TranslationSettingsSelectorsSet {
    var NAVBAR: Selector { get }
    var BACK_BUTTON_iOS26: Selector { get }
    var BACK_BUTTON: Selector { get }
    var TRANSLATION_SWITCH: Selector { get }
    var ADD_LANGUAGE_CELL: Selector { get }
    var LANGUAGE_PICKER_NAVBAR: Selector { get }
    var LANGUAGE_PICKER_LIST: Selector { get }
    var LANGUAGE_PICKER_SEARCH_FIELD: Selector { get }
    var LANGUAGE_PICKER_HEADER: Selector { get }
    var LANGUAGE_PICKER_ROW: Selector { get }
    var LANGUAGE_PICKER_CLOSE_BUTTON: Selector { get }
    var LANGUAGE_PICKER_SEARCH_CLOSE_BUTTON_iOS26: Selector { get }
    var KEYBOARD: Selector { get }
    var PREFERRED_LANGUAGES_LIST: Selector { get }
    var EDIT_BUTTON: Selector { get }
    var DONE_BUTTON: Selector { get }
    var all: [Selector] { get }
    func languagePickerRows(containing text: String) -> Selector
    func languagePickerOption(_ language: String) -> Selector
    func preferredLanguage(_ language: String) -> Selector
    func preferredLanguageCell(containing text: String) -> Selector
    func removeLanguageIcon(inCellContaining text: String) -> Selector
    func reorderHandle(inCellContaining text: String) -> Selector
}

struct TranslationSettingsSelectors: TranslationSettingsSelectorsSet {
    private enum IDs {
        static let navBar              = AccessibilityIdentifiers.Settings.Translation.navigationBar
        static let translationSwitch   = AccessibilityIdentifiers.Settings.Translation.toggleSwitch
        static let backButtoniOS26     = AccessibilityIdentifiers.Settings.Translation.backButtoniOS26
        static let backButton          = AccessibilityIdentifiers.Settings.Translation.backButton
        static let addLanguage         = String.Settings.Translation.PreferredLanguages.AddLanguage
        static let pickerTitle         = String.Settings.Translation.LanguagePicker.NavTitle
        static let pickerList          = AccessibilityIdentifiers.Settings.Translation.languagePickerList
        static let pickerSearch        = String.Settings.Translation.LanguagePicker.SearchPlaceholder
        static let pickerClose         = "Cancel"
        static let pickerSearchClose   = "close"
        static let edit                = "Edit"
        static let done                = String.AppSettingsDone
        static let removeIcon          = "minus.circle.fill"
        static let reorderHandle       = "Reorder"
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

    let ADD_LANGUAGE_CELL = Selector.cellByLabel(
        IDs.addLanguage,
        description: "'Add Language…' row in Settings → Translation",
        groups: ["settings", "translation"]
    )

    let LANGUAGE_PICKER_NAVBAR = Selector.navigationBarByTitle(
        IDs.pickerTitle,
        description: "'Select Language' sheet navigation bar",
        groups: ["settings", "translation"]
    )

    let LANGUAGE_PICKER_LIST = Selector.tableById(
        IDs.pickerList,
        description: "Language list in the 'Select Language' sheet",
        groups: ["settings", "translation"]
    )

    let LANGUAGE_PICKER_SEARCH_FIELD = Selector.searchFieldByIdOrLabel(
        IDs.pickerSearch,
        description: "Search field in the 'Select Language' sheet",
        groups: ["settings", "translation"]
    )

    var LANGUAGE_PICKER_HEADER: Selector {
        Selector.staticTextByExactLabel(
            IDs.pickerTitle,
            in: LANGUAGE_PICKER_NAVBAR,
            description: "'Select Language' title in the sheet navigation bar",
            groups: ["settings", "translation"]
        )
    }

    var LANGUAGE_PICKER_ROW: Selector {
        Selector.element(
            .cell,
            in: LANGUAGE_PICKER_LIST,
            value: "cell",
            description: "Any row of the 'Select Language' list",
            groups: ["settings", "translation"]
        )
    }

    /// The sheet's system Cancel item, an X on iOS 26. Below iOS 26 the search bar's Cancel takes its place while searching.
    var LANGUAGE_PICKER_CLOSE_BUTTON: Selector {
        Selector.buttonByLabel(
            IDs.pickerClose,
            in: LANGUAGE_PICKER_NAVBAR,
            description: "Cancel (X) button that closes the 'Select Language' sheet",
            groups: ["settings", "translation"]
        )
    }

    /// iPhone on iOS 26 moves the active search field above the keyboard, with this button next to it in an unnamed
    /// container. Its exact lowercase label sets it apart from the sheet's "Cancel".
    let LANGUAGE_PICKER_SEARCH_CLOSE_BUTTON_iOS26 = Selector.buttonByLabel(
        IDs.pickerSearchClose,
        description: "'close' button that ends search in the 'Select Language' sheet (iPhone, iOS 26)",
        groups: ["settings", "translation"]
    )

    let KEYBOARD = Selector.elementType(
        .keyboard,
        description: "Software keyboard",
        groups: ["settings", "translation"]
    )

    /// The Translation settings list has no identifier, so this covers every collection view on screen.
    let PREFERRED_LANGUAGES_LIST = Selector.elementType(
        .collectionView,
        description: "Translation settings list holding the Preferred Languages",
        groups: ["settings", "translation"]
    )

    let EDIT_BUTTON = Selector.buttonInNavigationBarByLabel(
        IDs.edit,
        description: "Edit button for the Preferred Languages list",
        groups: ["settings", "translation"]
    )

    let DONE_BUTTON = Selector.buttonInNavigationBarByLabel(
        IDs.done,
        description: "Done button that saves Preferred Languages edits",
        groups: ["settings", "translation"]
    )

    func languagePickerRows(containing text: String) -> Selector {
        Selector.element(
            .cell,
            in: LANGUAGE_PICKER_LIST,
            containing: NSPredicate(format: "elementType == %d AND label CONTAINS[c] %@",
                                    XCUIElement.ElementType.staticText.rawValue,
                                    text),
            value: text,
            description: "Rows of the 'Select Language' list whose text contains '\(text)'",
            groups: ["settings", "translation"]
        )
    }

    func languagePickerOption(_ language: String) -> Selector {
        Selector.staticTextByExactLabel(
            language,
            in: LANGUAGE_PICKER_LIST,
            description: "'\(language)' option in the 'Select Language' list",
            groups: ["settings", "translation"]
        )
    }

    func preferredLanguage(_ language: String) -> Selector {
        Selector.staticTextByExactLabel(
            language,
            in: PREFERRED_LANGUAGES_LIST,
            description: "'\(language)' in the Preferred Languages list",
            groups: ["settings", "translation"]
        )
    }

    func preferredLanguageCell(containing text: String) -> Selector {
        Selector.cellContainingStaticText(
            text,
            in: PREFERRED_LANGUAGES_LIST,
            description: "Preferred Languages row showing '\(text)'",
            groups: ["settings", "translation"]
        )
    }

    /// The edit-mode delete (-) accessory is exposed as an image, not a button.
    func removeLanguageIcon(inCellContaining text: String) -> Selector {
        Selector.imageId(
            IDs.removeIcon,
            in: preferredLanguageCell(containing: text),
            description: "Delete (-) accessory on the '\(text)' Preferred Languages row in edit mode",
            groups: ["settings", "translation"]
        )
    }

    /// System reorder control, labelled "Reorder <language>".
    func reorderHandle(inCellContaining text: String) -> Selector {
        Selector.buttonLabelBeginsWith(
            IDs.reorderHandle,
            in: preferredLanguageCell(containing: text),
            description: "Drag (reorder) handle on the '\(text)' Preferred Languages row",
            groups: ["settings", "translation"]
        )
    }

    var all: [Selector] {
        [NAVBAR, BACK_BUTTON_iOS26, BACK_BUTTON, TRANSLATION_SWITCH, ADD_LANGUAGE_CELL, LANGUAGE_PICKER_NAVBAR,
         LANGUAGE_PICKER_LIST, LANGUAGE_PICKER_SEARCH_FIELD, LANGUAGE_PICKER_HEADER, LANGUAGE_PICKER_ROW,
         LANGUAGE_PICKER_CLOSE_BUTTON, LANGUAGE_PICKER_SEARCH_CLOSE_BUTTON_iOS26, KEYBOARD, PREFERRED_LANGUAGES_LIST,
         EDIT_BUTTON, DONE_BUTTON]
    }
}
