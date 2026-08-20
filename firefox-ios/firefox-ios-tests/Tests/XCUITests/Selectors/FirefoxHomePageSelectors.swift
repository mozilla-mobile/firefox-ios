// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol FirefoxHomePageSelectorsSet {
    var TOPSITES_ITEMCELL: Selector { get }
    var BOOKMARKS_ITEMCELL: Selector { get }
    var BOOKMARKS_SHOW_ALL_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct FirefoxHomePageSelectors: FirefoxHomePageSelectorsSet {
    private enum IDs {
        static let topSites_ItemCell = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        static let bookmarks_ItemCell = AccessibilityIdentifiers.FirefoxHomepage.Bookmarks.itemCell
        static let bookmarks_ShowAllButton = AccessibilityIdentifiers.FirefoxHomepage.MoreButtons.bookmarks
    }

    let TOPSITES_ITEMCELL = Selector.linkById(
        IDs.topSites_ItemCell,
        description: "Top Site link cell inside the collection view",
        groups: ["FxHomepage"]
    )

    let BOOKMARKS_ITEMCELL = Selector.cellById(
        IDs.bookmarks_ItemCell,
        description: "Bookmark link cell inside the collection view",
        groups: ["FxHomepage"]
    )

    // The header button is titled "Show All"; matched by identifier so the title can change freely.
    let BOOKMARKS_SHOW_ALL_BUTTON = Selector.buttonId(
        IDs.bookmarks_ShowAllButton,
        description: "Show All button in the homepage Bookmarks section header",
        groups: ["FxHomepage"]
    )

    var all: [Selector] { [TOPSITES_ITEMCELL, BOOKMARKS_ITEMCELL, BOOKMARKS_SHOW_ALL_BUTTON] }
}
