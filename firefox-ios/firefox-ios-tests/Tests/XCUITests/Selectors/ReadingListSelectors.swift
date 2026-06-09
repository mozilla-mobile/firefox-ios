// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ReadingListSelectorsSet {
    var READER_VIEW_BUTTON: Selector { get }
    var DISPLAY_SETTINGS_BUTTON: Selector { get }
    var FENNEC_ALERT_TEXT: Selector { get }
    var READING_TABLE: Selector { get }
    var DONE_BUTTON_READING_LIST: Selector { get }
    var READERMODE_SETTINGS_BUTTON: Selector { get }
    var LAYOUT_OPTIONS: [Selector] { get }
    var EMPTY_READING_LIST_1: Selector { get }
    var EMPTY_READING_LIST_2: Selector { get }
    var EMPTY_READING_LIST_3: Selector { get }
    var MARK_AS_UNREAD_BUTTON: Selector { get }
    var REMOVE_BUTTON: Selector { get }
}

struct ReadingListSelectors: ReadingListSelectorsSet {
    private enum IDs {
        static let readerView = "Reader View"
        static let displaySettings = "Display Settings"
        static let fennecAlert = "Fennec pasted from XCUITests-Runner"
        static let readingTable = "ReadingTable"
        static let doneButton = "Done"
        static let readerModeSetting = "ReaderModeBarView.settingsButton"
        static let emptyReadingList1 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList1
        static let emptyReadingList2 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList2
        static let emptyReadingList3 = AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.emptyReadingList3
        static let markUnread = "Mark as  Unread"
        static let removeButton = "Remove"
    }

    let READER_VIEW_BUTTON = Selector.buttonByLabel(
        IDs.readerView,
        description: "Reader List button on the toolbar",
        groups: ["reader"]
    )

    let DISPLAY_SETTINGS_BUTTON = Selector.buttonByLabel(
        IDs.displaySettings,
        description: "Reader List display settings button",
        groups: ["reader"]
    )

    let FENNEC_ALERT_TEXT = Selector.staticTextByLabel(
        IDs.fennecAlert,
        description: "Reader List Fennec Alert",
        groups: ["reader"]
    )

    let READING_TABLE = Selector.tableById(
        IDs.readingTable,
        description: "The Reading Table in the Reader View",
        groups: ["reader"]
    )

    let DONE_BUTTON_READING_LIST = Selector.buttonId(
        IDs.doneButton,
        description: "Done Button in the Reading List",
        groups: ["reader"]
    )

    let READERMODE_SETTINGS_BUTTON = Selector.buttonId(
        IDs.readerModeSetting,
        description: "Reader Mode settings button",
        groups: ["reader"]
    )

    let LAYOUT_OPTIONS = [
        "Light",
        "Sepia",
        "Dark",
        "Decrease text size",
        "Reset text size",
        "Increase text size",
        "Remove from Reading List",
        "Mark as Read"
    ].map {
        Selector.buttonByLabel(
            $0,
            description: "Reader Mode layout option: \($0)",
            groups: ["reader"]
        )
    }

    let EMPTY_READING_LIST_1 = Selector.staticTextId(
        IDs.emptyReadingList1,
        description: "Empty Reading List 1 in the Reading Panel",
        groups: ["reader"]
    )

    let EMPTY_READING_LIST_2 = Selector.staticTextId(
        IDs.emptyReadingList2,
        description: "Empty Reading List 1 in the Reading Panel",
        groups: ["reader"]
    )

    let EMPTY_READING_LIST_3 = Selector.staticTextId(
        IDs.emptyReadingList3,
        description: "Empty Reading List 1 in the Reading Panel",
        groups: ["reader"]
    )

    let MARK_AS_UNREAD_BUTTON = Selector.buttonStaticTextByLabel(
        IDs.markUnread,
        description: "Mark as Unread button in Reading List swipe actions",
        groups: ["reader"]
    )

    let REMOVE_BUTTON = Selector.buttonStaticTextByLabel(
        IDs.removeButton,
        description: "Remove button in Reading List swipe actions",
        groups: ["reader"]
    )

    var all: [Selector] { [READER_VIEW_BUTTON, DISPLAY_SETTINGS_BUTTON, FENNEC_ALERT_TEXT, READING_TABLE,
                           DONE_BUTTON_READING_LIST, READERMODE_SETTINGS_BUTTON, EMPTY_READING_LIST_1, EMPTY_READING_LIST_2,
                           EMPTY_READING_LIST_3, MARK_AS_UNREAD_BUTTON, REMOVE_BUTTON] }
}
