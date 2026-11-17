// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SummarizeSettingsSelectorsSet {
    var SUMMARIZE_SWITCH: Selector { get }
    var SHAKE_GESTURE_SWITCH: Selector { get }
    var GESTURES_SECTION_HEADER: Selector { get }
    var LANGUAGE_SECTION_HEADER: Selector { get }
    var LANGUAGE_CELL: Selector { get }
    var WEBSITE_LANGUAGE_VALUE: Selector { get }
    var LANGUAGE_OPTIONS: [Selector] { get }
    var all: [Selector] { get }
}

struct SummarizeSettingsSelectors: SummarizeSettingsSelectorsSet {
    private enum IDs {
        static let summarizeSwitch = AccessibilityIdentifiers.Settings.Summarize.summarizeContentSwitch
        static let shakeGestureSwitch = AccessibilityIdentifiers.Settings.Summarize.shakeGestureSwitch
        static let languageCell = AccessibilityIdentifiers.Settings.Summarize.languageCell
        static let gesturesSectionHeader = "GESTURES"
        static let languageSectionHeader = "LANGUAGE"
        static let websiteLanguage = "Website Language"
        static let languageOptions = [websiteLanguage, "English", "Italian", "French", "Spanish", "German", "Portuguese"]
    }

    let SUMMARIZE_SWITCH = Selector.switchById(
        IDs.summarizeSwitch,
        description: "Switch for 'Summarize Pages' in Settings → Page Summaries",
        groups: ["settings", "summarizer"]
    )

    let SHAKE_GESTURE_SWITCH = Selector.switchById(
        IDs.shakeGestureSwitch,
        description: "Switch for 'Shake to Summarize' in Settings → Page Summaries",
        groups: ["settings", "summarizer"]
    )

    let GESTURES_SECTION_HEADER = Selector.staticTextInTablesByLabel(
        IDs.gesturesSectionHeader,
        description: "Gestures section header in Settings → Page Summaries",
        groups: ["settings", "summarizer"]
    )

    let LANGUAGE_SECTION_HEADER = Selector.staticTextInTablesByLabel(
        IDs.languageSectionHeader,
        description: "Language section header in Settings → Page Summaries",
        groups: ["settings", "summarizer"]
    )

    let LANGUAGE_CELL = Selector.tableCellById(
        IDs.languageCell,
        description: "Language cell in Settings → Page Summaries",
        groups: ["settings", "summarizer"]
    )

    let WEBSITE_LANGUAGE_VALUE = Selector.staticTextInTablesByLabel(
        IDs.websiteLanguage,
        description: "'Website Language' value shown in the Page Summaries language cell",
        groups: ["settings", "summarizer"]
    )

    /// Every option listed by the language picker, which shows them as buttons.
    var LANGUAGE_OPTIONS: [Selector] {
        IDs.languageOptions.map {
            Selector.buttonByLabel(
                $0,
                description: "'\($0)' option in the Page Summaries language picker",
                groups: ["settings", "summarizer"]
            )
        }
    }

    var all: [Selector] {
        [SUMMARIZE_SWITCH, SHAKE_GESTURE_SWITCH, GESTURES_SECTION_HEADER, LANGUAGE_SECTION_HEADER,
         LANGUAGE_CELL, WEBSITE_LANGUAGE_VALUE] + LANGUAGE_OPTIONS
    }
}
