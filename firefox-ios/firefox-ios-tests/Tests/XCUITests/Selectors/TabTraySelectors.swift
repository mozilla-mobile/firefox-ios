// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TabTraySelectorsSet {
    var TABSTRAY_CONTAINER: Selector { get }
    var COLLECTION_VIEW: Selector { get }
    var IPHONE_TAB_TRAY_COLLECTION_VIEW: Selector { get }
    var FIRST_CELL: Selector { get }
    var NEW_TAB_BUTTON: Selector { get }
    var UNDO_BUTTON: Selector { get }
    func cell(named name: String) -> Selector
    func tabCellWithIndex(_ index: Int, _ urlLabel: String, _ selectedTab: String) -> Selector
    func tabCellAtIndex(index: Int) -> Selector
    func tabSelectorButton(at index: Int) -> Selector
    var all: [Selector] { get }
}

struct TabTraySelectors: TabTraySelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.TabTray.collectionView
        static let tabsTray = AccessibilityIdentifiers.TabTray.tabsTray
        static let newTabButton = AccessibilityIdentifiers.TabTray.newTabButton
    }

    let TABSTRAY_CONTAINER = Selector(
        strategy: .anyById(IDs.tabsTray),
        value: IDs.tabsTray,
        description: "Tabs Tray container",
        groups: ["tabtray"]
    )

    let COLLECTION_VIEW = Selector(
        strategy: .collectionViewById(IDs.collectionView),
        value: IDs.collectionView,
        description: "Tab Tray collection view",
        groups: ["tabtray"]
    )

    let IPHONE_TAB_TRAY_COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "The main collection view for the tab tray on iPhone",
        groups: ["tabtray"]
    )

    let FIRST_CELL = Selector.staticTextByLabel(
        "firstCell",
        description: "First Tab cell",
        groups: ["tabtray"]
    )

    let NEW_TAB_BUTTON = Selector.buttonId(
        IDs.newTabButton,
        description: "New Tab Button on TabTray",
        groups: ["tabtray"]
    )

    let UNDO_BUTTON = Selector.otherElementsButtonStaticTextByLabel(
        "Undo",
        description: "Undo button displayed after removing all tabs",
        groups: ["tabtray"]
    )

    func cell(named name: String) -> Selector {
        Selector.staticTextByLabel(
            name,
            description: "Tab cell named \(name)",
            groups: ["tabtray"]
        )
    }

    func tabCellWithIndex(_ index: Int, _ urlLabel: String, _ selectedTab: String) -> Selector {
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_\(index)"
        let expectedLabel = "\(urlLabel). \(selectedTab)"

        return Selector.cellById(
            identifier,
            description: "Tab cell with ID \(identifier) and label '\(expectedLabel)'",
            groups: ["tabtray"]
        )
    }

    func tabCellAtIndex(index: Int) -> Selector {
        let identifier = "\(AccessibilityIdentifiers.TabTray.tabCell)_0_\(index)"

        return Selector.cellById(
            identifier,
            description: "Tab cell at index \(index) for tapping",
            groups: ["tabtray"]
        )
    }

    func tabSelectorButton(at index: Int) -> Selector {
        let id = "\(AccessibilityIdentifiers.TabTray.selectorCell)\(index)"
        return Selector.buttonId(
            id,
            description: "Button for Tab Tray cell at index \(index)",
            groups: ["tabtray"]
        )
    }

    var all: [Selector] { [TABSTRAY_CONTAINER, COLLECTION_VIEW,
                           IPHONE_TAB_TRAY_COLLECTION_VIEW, FIRST_CELL, NEW_TAB_BUTTON,
                            UNDO_BUTTON] }
}
