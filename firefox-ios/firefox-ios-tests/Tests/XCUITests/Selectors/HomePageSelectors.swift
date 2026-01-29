// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol HomePageSelectorsSet {
    var COLLECTION_VIEW: Selector { get }
    var TABS_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct HomePageSelectors: HomePageSelectorsSet {
    private enum IDs {
        static let collectionView = "FxCollectionView"
        static let tabsButton = AccessibilityIdentifiers.Toolbar.tabsButton
    }

    let COLLECTION_VIEW = Selector.collectionViewIdOrLabel(
        IDs.collectionView,
        description: "Firefox Home main collection view",
        groups: ["homepage"]
    )

    let TABS_BUTTON = Selector.buttonId(
        IDs.tabsButton,
        description: "Tabs button on Firefox Home",
        groups: ["homepage", "toolbar"]
    )

    var all: [Selector] { [COLLECTION_VIEW] }
}
