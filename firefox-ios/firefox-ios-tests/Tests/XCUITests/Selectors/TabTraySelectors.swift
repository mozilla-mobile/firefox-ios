// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TabTraySelectorsSet {
    var TABSTRAY_CONTAINER: Selector { get }
    var COLLECTION_VIEW: Selector { get }
    var FIRST_CELL: Selector { get }
    func cell(named name: String) -> Selector
    var all: [Selector] { get }
}

struct TabTraySelectors: TabTraySelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.TabTray.collectionView
        static let tabsTray = AccessibilityIdentifiers.TabTray.tabsTray
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

    let FIRST_CELL = Selector(
        strategy: .predicate(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.cell.rawValue)),
        value: "firstCell",
        description: "First Tab cell",
        groups: ["tabtray"]
    )

    func cell(named name: String) -> Selector {
        return Selector(
            strategy: .predicate(NSPredicate(format: "label == %@", name)),
            value: name,
            description: "Tab cell named \(name)",
            groups: ["tabtray"]
        )
    }

    var all: [Selector] { [TABSTRAY_CONTAINER, COLLECTION_VIEW, FIRST_CELL] }
}
