// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TopTabsSelectorsSet {
    var COLLECTION_VIEW: Selector { get }
    var PRIVATE_MODE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct TopTabsSelectors: TopTabsSelectorsSet {
    private enum IDs {
        static let collectionView = AccessibilityIdentifiers.Browser.TopTabs.collectionView
        static let privateModeButton = AccessibilityIdentifiers.Browser.TopTabs.privateModeButton
    }

    let COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "Top Tabs bar shown above the address bar on iPad",
        groups: ["browser", "topTabs"]
    )

    let PRIVATE_MODE_BUTTON = Selector.buttonId(
        IDs.privateModeButton,
        description: "Private Browsing button in the Top Tabs bar",
        groups: ["browser", "topTabs"]
    )

    var all: [Selector] { [COLLECTION_VIEW, PRIVATE_MODE_BUTTON] }
}
