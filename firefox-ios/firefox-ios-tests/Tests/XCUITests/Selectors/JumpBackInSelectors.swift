// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol JumpBackInSelectorsSet {
    var COLLECTION_VIEW: Selector { get }
    var SECTION_TITLE: Selector { get }
    var ITEM_CELL: Selector { get }
    var CONTEXT_MENU_TABLE: Selector { get }
    func itemTitle(_ title: String) -> Selector
    var all: [Selector] { get }
}

struct JumpBackInSelectors: JumpBackInSelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.FirefoxHomepage.collectionView
        static let sectionTitle = AccessibilityIdentifiers.FirefoxHomepage.SectionTitles.jumpBackIn
        static let itemCell = AccessibilityIdentifiers.FirefoxHomepage.JumpBackIn.itemCell
        static let contextMenu = "Context Menu"
    }

    let COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "Firefox Home main collection view",
        groups: ["jumpBackIn"]
    )

    let SECTION_TITLE = Selector.staticTextId(
        IDs.sectionTitle,
        description: "Jump Back In section title",
        groups: ["jumpBackIn"]
    )

    let ITEM_CELL = Selector.cellById(
        IDs.itemCell,
        description: "Jump Back In item cell",
        groups: ["jumpBackIn"]
    )

    let CONTEXT_MENU_TABLE = Selector.tableIdOrLabel(
        IDs.contextMenu,
        description: "Jump Back In context menu table",
        groups: ["jumpBackIn", "contextMenu"]
    )

    func itemTitle(_ title: String) -> Selector {
        Selector.staticTextByExactLabel(
            title,
            description: "Jump Back In item titled \(title)",
            groups: ["jumpBackIn"]
        )
    }

    var all: [Selector] { [COLLECTION_VIEW, SECTION_TITLE, ITEM_CELL, CONTEXT_MENU_TABLE] }
}
