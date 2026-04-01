// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

protocol NewTabSelectorSet {
    var ICON_PLUS: Selector { get }
    var ICON_CROSS: Selector { get }
    var ICON_PLUS_IN_CELLS: Selector { get }
    var ICON_CROSS_IN_CELLS: Selector { get }
    var ICON_PLUS_IN_TABLE_CELLS: Selector { get }
    var ICON_CROSS_IN_TABLE_CELLS: Selector { get }
    var NEW_PRIVATE_TAB_BUTTON: Selector { get }
    var NEW_PRIVATE_TAB_IN_TABLE_CELLS: Selector { get }
    var OPEN_NEW_TAB_BUTTON: Selector { get }
    var OPEN_NEW_PRIVATE_TAB_BUTTON: Selector { get }
    var SWITCH_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct NewTabSelectors: NewTabSelectorSet {
    private enum IDs {
        static let iconPlus = StandardImageIdentifiers.Large.plus
        static let iconCross = StandardImageIdentifiers.Large.cross
        static let newPrivateTab = "New Private Tab"
        static let openInNewTabButton = "Open in New Tab"
        static let openInNewPrivateTabButton = "Open in New Private Tab"
        static let switchButton = "Switch"
    }

    let ICON_PLUS = Selector.buttonId(
        IDs.iconPlus,
        description: "Icon Plus in new Tab",
        groups: ["NewTabSelector"]
    )

    let ICON_CROSS = Selector.buttonId(
        IDs.iconCross,
        description: "Icon Cross in new Tab",
        groups: ["NewTabSelector"]
    )

    let ICON_PLUS_IN_CELLS = Selector.cellButtonById(
          IDs.iconPlus,
          description: "Icon Plus in cells context",
          groups: ["NewTabSelector"]
    )

    let ICON_CROSS_IN_CELLS = Selector.cellButtonById(
        IDs.iconCross,
        description: "Icon Cross in cells context",
        groups: ["NewTabSelector"]
    )

    let ICON_PLUS_IN_TABLE_CELLS = Selector.tableCellButtonById(
        IDs.iconPlus,
        description: "Icon Plus in table cells context",
        groups: ["NewTabSelector"]
    )

    let ICON_CROSS_IN_TABLE_CELLS = Selector.tableCellButtonById(
        IDs.iconCross,
        description: "Icon Cross in table cells context",
        groups: ["NewTabSelector"]
    )

    let NEW_PRIVATE_TAB_BUTTON = Selector.buttonId(
        IDs.newPrivateTab,
        description: "New Private Tab",
        groups: ["NewTabSelector"]
    )

    let NEW_PRIVATE_TAB_IN_TABLE_CELLS = Selector.tableCellButtonById(
        IDs.newPrivateTab,
        description: "New Private Tab in table cells context",
        groups: ["NewTabSelector"]
    )

    let OPEN_NEW_TAB_BUTTON = Selector.buttonId(
        IDs.openInNewTabButton,
        description: "Open In New Tab button",
        groups: ["NewTabSelector"]
    )

    let OPEN_NEW_PRIVATE_TAB_BUTTON = Selector.buttonId(
        IDs.openInNewPrivateTabButton,
        description: "Open in New Private Tab Button",
        groups: ["NewTabSelector"]
    )

    let SWITCH_BUTTON = Selector.buttonId(
        IDs.switchButton,
        description: "Switch button",
        groups: ["NewTabSelector"]
    )

    var all: [Selector] { [ICON_PLUS, ICON_CROSS, NEW_PRIVATE_TAB_BUTTON,
                           OPEN_NEW_TAB_BUTTON, OPEN_NEW_PRIVATE_TAB_BUTTON, SWITCH_BUTTON] }
}
