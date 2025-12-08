// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol HomepageSettingsSelectorSet {
    var BOOKMARK_TOGGLE: Selector { get }
    var HOMEPAGE_SETTINGS_TABLE: Selector { get }
    var all: [Selector] { get }
}

struct HomepageSettingsSelectors: HomepageSettingsSelectorSet {
    private enum IDs {
        static let bookmarkToogle = "Bookmarks"
    }

    let HOMEPAGE_SETTINGS_TABLE = Selector.firstTable(
        description: "Homepage settings table view (first table in hierarchy)",
        groups: ["homepage_settings"]
    )

    let BOOKMARK_TOGGLE = Selector.staticTextByLabel(
        IDs.bookmarkToogle,
        description: "Bookmark toggle in homepage settings",
        groups: ["homepage_settings"]
    )

    var all: [Selector] { [BOOKMARK_TOGGLE, HOMEPAGE_SETTINGS_TABLE] }
}
