// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol LibrarySelectorsSet {
    var BOOKMARKS_LIST: Selector { get }
    var DELETE_BUTTON: Selector { get }
    var SIGN_IN_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct LibrarySelectors: LibrarySelectorsSet {
    private enum IDs {
        static let bookMarkPanel = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.self
        static let bookmarksList = bookMarkPanel.tableView
        static let deleteButton = "Delete"
        static let signInButton = bookMarkPanel.emptyStateSignInButton
    }

    let BOOKMARKS_LIST = Selector.tableIdOrLabel(
        IDs.bookmarksList,
        description: "Bookmarks List table",
        groups: ["library", "bookmarks"]
    )

    let DELETE_BUTTON = Selector.buttonIdOrLabel(
        IDs.deleteButton,
        description: "Delete button in the bookmarks panel",
        groups: ["library", "bookmarks"]
    )

    let SIGN_IN_BUTTON = Selector.buttonIdOrLabel(
        IDs.signInButton,
        description: "Sign In button in the bookmarks panel empty state",
        groups: ["library", "bookmarks"]
    )

    var all: [Selector] { [BOOKMARKS_LIST, DELETE_BUTTON, SIGN_IN_BUTTON] }
}
