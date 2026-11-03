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
    var LANGUAGE_PICKER_CANCEL_BUTTON: Selector { get }
    var EDIT_BUTTON: Selector { get }
    var DONE_BUTTON: Selector { get }
    var REMOVE_LANGUAGE_ICON: Selector { get }
    var REORDER_HANDLE: Selector { get }
    var all: [Selector] { get }
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
        static let cancelLabels        = ["Cancel", "Close"]
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

    /// System cancel button: "Cancel" below iOS 26; on iOS 26 the sheet's X and the search bar's "close".
    let LANGUAGE_PICKER_CANCEL_BUTTON = Selector(
        strategy: .predicate(NSPredicate(
            format: "elementType == %d AND (label ==[c] %@ OR label ==[c] %@ OR identifier ==[c] %@ OR identifier ==[c] %@)",
            XCUIElement.ElementType.button.rawValue,
            IDs.cancelLabels[0],
            IDs.cancelLabels[1],
            IDs.cancelLabels[0],
            IDs.cancelLabels[1]
        )),
        value: IDs.cancelLabels.joined(separator: "|"),
        description: "Cancel/X button of the 'Select Language' sheet or its search bar",
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

    let REMOVE_LANGUAGE_ICON = Selector.imageId(
        IDs.removeIcon,
        description: "Delete (-) accessory on a Preferred Languages row in edit mode",
        groups: ["settings", "translation"]
    )

    /// System reorder control, labelled "Reorder <language>".
    let REORDER_HANDLE = Selector.buttonLabelContains(
        IDs.reorderHandle,
        description: "Drag (reorder) handle on a Preferred Languages row",
        groups: ["settings", "translation"]
    )

    var all: [Selector] {
        [NAVBAR, BACK_BUTTON_iOS26, BACK_BUTTON, TRANSLATION_SWITCH, ADD_LANGUAGE_CELL, LANGUAGE_PICKER_NAVBAR,
         LANGUAGE_PICKER_LIST, LANGUAGE_PICKER_SEARCH_FIELD, LANGUAGE_PICKER_CANCEL_BUTTON, EDIT_BUTTON, DONE_BUTTON,
         REMOVE_LANGUAGE_ICON, REORDER_HANDLE]
    }
}
