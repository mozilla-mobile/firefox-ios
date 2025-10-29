// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol HistorySelectorsSet {
    var HISTORY_ENTRY_EXAMPLE: Selector { get }
    var DELETE_BUTTON: Selector { get }
    var EMPTY_RECENTLY_CLOSED_MSG: Selector { get }
    var all: [Selector] { get }
}

struct HistorySelectors: HistorySelectorsSet {
    private enum IDs {
        static let exampleEntry = "http://example.com/"
        static let deleteButton = "Delete"
        static let emptyMsg     = emptyRecentlyClosedMesg
        static let tableViewId  = AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView
    }

    let HISTORY_ENTRY_EXAMPLE = Selector.staticTextByExactLabel(
        IDs.exampleEntry,
        description: "History entry for example.com",
        groups: ["library", "history"]
    )

    let DELETE_BUTTON = Selector.buttonByLabel(
        IDs.deleteButton,
        description: "Delete button after swiping history entry",
        groups: ["library", "history"]
    )

    let EMPTY_RECENTLY_CLOSED_MSG = Selector.staticTextByExactLabel(
        IDs.emptyMsg,
        description: "Empty message shown when history is cleared",
        groups: ["library", "history"]
    )

    var all: [Selector] { [HISTORY_ENTRY_EXAMPLE, DELETE_BUTTON, EMPTY_RECENTLY_CLOSED_MSG] }
}
