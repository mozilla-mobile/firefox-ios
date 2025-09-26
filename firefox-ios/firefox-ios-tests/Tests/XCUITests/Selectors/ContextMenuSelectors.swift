// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol ContextMenuSelectorsSet {
    var OPEN_IN_PRIVATE_TAB: Selector { get }
    var CONTEXT_MENU_TABLE: Selector { get }
    var all: [Selector] { get }
}

struct ContextMenuSelectors: ContextMenuSelectorsSet {
    let CONTEXT_MENU_TABLE = Selector.tableIdOrLabel(
        "Context Menu",
        description: "Context Menu table",
        groups: ["contextmenu"]
    )

    let OPEN_IN_PRIVATE_TAB = Selector.buttonId(
        "Open in a Private Tab",
        description: "Context menu option: Open in a Private Tab",
        groups: ["contextmenu"]
    )

    var all: [Selector] { [OPEN_IN_PRIVATE_TAB, CONTEXT_MENU_TABLE] }
}
