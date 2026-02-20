// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

protocol TopSitesSelectorsSet {
    var TOP_SITE_ITEM_CELL: Selector { get }
    var COLLECTION_VIEW: Selector { get }
    var TOPSITE_YOUTUBE: Selector { get }
    var PIN: Selector { get }
    var PIN_SLASH: Selector { get }
    var all: [Selector] { get }
}

struct TopSitesSelectors: TopSitesSelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.FirefoxHomepage.collectionView
        static let itemCell = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        static let youtube = "YouTube"
        static let pin = StandardImageIdentifiers.Large.pinFill
        static let pinSlash = StandardImageIdentifiers.Large.pinSlash
    }

    let TOP_SITE_ITEM_CELL = Selector.linkById(
        IDs.itemCell,
        description: "Generic Top Site cell group",
        groups: ["homepage", "topsites"]
    )

    let COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "Top Sites collection view",
        groups: ["homepage", "topsites"]
    )

    let TOPSITE_YOUTUBE = Selector.linkStaticTextById(
        IDs.youtube,
        description: "YouTube Top Site link label inside a Link element",
        groups: ["homepage", "topsites"]
    )

    let PIN = Selector.imageId(
        IDs.pin,
        description: "Pin icon image",
        groups: ["homepage", "topsites"]
    )

    let PIN_SLASH = Selector.buttonId(
        IDs.pinSlash,
        description: "Unpinned button",
        groups: ["homepage", "topsites"]
    )

    var all: [Selector] {
        [
            TOP_SITE_ITEM_CELL,
            COLLECTION_VIEW,
            TOPSITE_YOUTUBE,
            PIN, PIN_SLASH
        ]
    }
}
