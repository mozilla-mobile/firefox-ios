// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TopSitesSelectorsSet {
    var TOP_SITE_ITEM_CELL: Selector { get }
    var COLLECTION_VIEW: Selector { get }
    var all: [Selector] { get }
}

struct TopSitesSelectors: TopSitesSelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.FirefoxHomepage.collectionView
        static let itemCell = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
    }

    let TOP_SITE_ITEM_CELL = Selector.anyId(
        IDs.itemCell,
        description: "Generic Top Site cell group",
        groups: ["homepage", "topsites"]
    )

    let COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "Top Sites collection view",
        groups: ["homepage", "topsites"]
    )

    var all: [Selector] {
        [
            TOP_SITE_ITEM_CELL,
            COLLECTION_VIEW
        ]
    }
}
