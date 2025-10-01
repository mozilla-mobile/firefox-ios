// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol LibrarySelectorsSet {
    var BOOKMARKS_LIST: Selector { get }
    var all: [Selector] { get }
}

struct LibrarySelectors: LibrarySelectorsSet {
    private enum IDs {
        static let bookmarksList = "Bookmarks List"
    }

    let BOOKMARKS_LIST = Selector.tableIdOrLabel(
        IDs.bookmarksList,
        description: "Bookmarks List table",
        groups: ["library", "bookmarks"]
    )

    var all: [Selector] { [BOOKMARKS_LIST] }
}
