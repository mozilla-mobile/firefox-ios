// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol NewTabSettingsSelectorsSet {
    var NAVIGATION_BAR: Selector { get }
    var FIREFOX_HOME_CELL: Selector { get }
    var BLANK_PAGE_CELL: Selector { get }
    var CUSTOM_URL_CELL: Selector { get }
    var CUSTOM_URL_TEXT_FIELD: Selector { get }
    var all: [Selector] { get }
}

struct NewTabSettingsSelectors: NewTabSettingsSelectorsSet {
    private enum IDs {
        static let navBarTitle = "New Tab"
        static let firefoxHomeCell = "Firefox Home"
        static let blankPageCell = "Blank Page"
        static let customURLCell = "NewTabAsCustomURL"
        static let customUrlTextField = "NewTabAsCustomURLTextField"
    }

    let NAVIGATION_BAR = Selector.navigationBarByIdOrLabel(
        IDs.navBarTitle,
        description: "Navigation Bar with title 'New Tab'",
        groups: ["settings"]
    )

    let FIREFOX_HOME_CELL = Selector.tableCellById(
        IDs.firefoxHomeCell,
        description: "New Tab setting cell for Firefox Home",
        groups: ["settings"]
    )

    let BLANK_PAGE_CELL = Selector.tableCellById(
        IDs.blankPageCell,
        description: "New Tab setting cell for Blank Page",
        groups: ["settings"]
    )

    let CUSTOM_URL_CELL = Selector.tableCellById(
        IDs.customURLCell,
        description: "New Tab setting cell for Custom URL",
        groups: ["settings"]
    )

    let CUSTOM_URL_TEXT_FIELD = Selector.textFieldId(
        IDs.customUrlTextField,
        description: "Text field for custom new tab URL entry",
        groups: ["settings", "newtab"]
    )

    var all: [Selector] {
        [NAVIGATION_BAR, FIREFOX_HOME_CELL, BLANK_PAGE_CELL, CUSTOM_URL_CELL, CUSTOM_URL_TEXT_FIELD]
    }
}
