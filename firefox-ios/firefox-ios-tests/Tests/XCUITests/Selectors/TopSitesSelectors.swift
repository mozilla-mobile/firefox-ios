// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

protocol TopSitesSelectorsSet {
    var TOP_SITE_ITEM_CELL: Selector { get }
    var COLLECTION_VIEW: Selector { get }
    var TOPSITE_YOUTUBE: Selector { get }
    var PIN_ICON: Selector { get }
    var PIN: Selector { get }
    var UNPIN: Selector { get }
    var OPEN_IN_NEW_TAB: Selector { get }
    var OPEN_IN_PRIVATE_TAB: Selector { get }
    var REMOVE: Selector { get }
    var SHARE: Selector { get }
    var all: [Selector] { get }
}

struct TopSitesSelectors: TopSitesSelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.FirefoxHomepage.collectionView
        static let itemCell = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        static let youtube = "YouTube"
        static let pinIcon = StandardImageIdentifiers.ExtraSmall.pin
        static let pin = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.pin
        static let unpin = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.unpin
        static let openInNewTab = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.openInNewTab
        static let openInPrivateTab = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.openInPrivateTab
        static let remove = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.remove
        static let share = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu.share
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

    let PIN_ICON = Selector.imageId(
        IDs.pinIcon,
        description: "Pin icon image",
        groups: ["homepage", "topsites"]
    )

    let PIN = Selector.buttonId(
        IDs.pin,
        description: "Pin option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    let UNPIN = Selector.buttonId(
        IDs.unpin,
        description: "Unpin option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    let OPEN_IN_NEW_TAB = Selector.buttonId(
        IDs.openInNewTab,
        description: "Open in New Tab option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    let OPEN_IN_PRIVATE_TAB = Selector.buttonId(
        IDs.openInPrivateTab,
        description: "Open in Private Tab option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    let REMOVE = Selector.buttonId(
        IDs.remove,
        description: "Remove option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    let SHARE = Selector.buttonId(
        IDs.share,
        description: "Share option in the top site context menu",
        groups: ["homepage", "topsites"]
    )

    var all: [Selector] {
        [
            TOP_SITE_ITEM_CELL,
            COLLECTION_VIEW,
            TOPSITE_YOUTUBE,
            PIN_ICON, PIN, UNPIN,
            OPEN_IN_NEW_TAB, OPEN_IN_PRIVATE_TAB,
            REMOVE, SHARE
        ]
    }
}
