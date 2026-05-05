// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol LibrarySelectorsSet {
    var BOOKMARKS_LIST: Selector { get }
    var DELETE_BUTTON: Selector { get }
    var SIGN_IN_BUTTON: Selector { get }
    var BOOKMARK_EMPTY_STATE: Selector { get }
    var EDIT_BUTTON: Selector { get }
    var DONE_BUTTON: Selector { get }
    var BOTTOM_LEFT_BUTTON: Selector { get }
    var TITLE_TEXT_FIELD: Selector { get }
    var BOOKMARKS_FOLDER: Selector { get }
    var SAVE_BUTTON: Selector { get }
    var BACK_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct LibrarySelectors: LibrarySelectorsSet {
    private enum IDs {
        static let bookMarkPanel = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.self
        static let bookmarksList = bookMarkPanel.tableView
        static let deleteButton = "Delete"
        static let signInButton = bookMarkPanel.emptyStateSignInButton
        static let bookmarkEmptyState = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.emptyStateTitleLabel
        static let editButton = "Edit"
        static let doneButton = "Done"
        static let bottomLeftButton = AccessibilityIdentifiers.LibraryPanels.bottomLeftButton
        static let titleTextFields = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.titleTextField
        static let bookmarksFolder = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.bookmarksFolder
        static let saveButton = AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.saveButton
        static let backButton = AccessibilityIdentifiers.Settings.Search.backButtoniOS26
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

    let BACK_BUTTON = Selector.buttonId(
        IDs.backButton,
        description: "Boomark new folder back button",
        groups: ["bookmark", "search"]
    )

    let BOOKMARK_EMPTY_STATE = Selector.staticTextId(
        IDs.bookmarkEmptyState,
        description: "Empty state text in the bookmarks panel",
        groups: ["library", "bookmarks"]
    )

    let EDIT_BUTTON = Selector.buttonId(
        IDs.editButton,
        description: "Edit right buttons in the library panels",
        groups: ["library"]
    )

    let DONE_BUTTON = Selector.buttonId(
        IDs.doneButton,
        description: "Done right buttons in the library panels",
        groups: ["library"]
    )

    let BOTTOM_LEFT_BUTTON = Selector.buttonId(
        IDs.bottomLeftButton,
        description: "Bottom left buttons in the library panels",
        groups: ["library"]
    )

    let TITLE_TEXT_FIELD = Selector.textFieldId(
        IDs.titleTextFields,
        description: "Title text field in the edit bookmark screen",
        groups: ["library", "bookmarks", "editBookmark"]
    )

    let BOOKMARKS_FOLDER = Selector.tableCellByLabel(
        IDs.bookmarksFolder,
        description: "Bookmarks folder cell in the bookmarks panel",
        groups: ["library", "bookmarks"]
    )

    let SAVE_BUTTON = Selector.buttonId(
        IDs.saveButton,
        description: "Save button in the edit bookmark screen",
        groups: ["library", "bookmarks", "editBookmark"]
    )

    var all: [Selector] { [BOOKMARKS_LIST, DELETE_BUTTON, SIGN_IN_BUTTON, BOOKMARK_EMPTY_STATE,
                           EDIT_BUTTON, BOTTOM_LEFT_BUTTON, TITLE_TEXT_FIELD, BOOKMARKS_FOLDER,
                           DONE_BUTTON, BACK_BUTTON] }
}
