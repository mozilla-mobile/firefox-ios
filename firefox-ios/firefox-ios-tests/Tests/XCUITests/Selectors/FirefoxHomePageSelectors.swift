// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol FirefoxHomePageSelectorsSet {
    var TOPSITES_ITEMCELL: Selector { get }
    var all: [Selector] { get }
}

struct FirefoxHomePageSelectors: FirefoxHomePageSelectorsSet {
    private enum IDs {
        static let topSites_ItemCell = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        // app.collectionViews.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
    }

    let TOPSITES_ITEMCELL = Selector.linkById(
        IDs.topSites_ItemCell,
        description: "Top Site link cell inside the collection view",
        groups: ["FxHomepage"]
    )

    var all: [Selector] { [TOPSITES_ITEMCELL] }
}
