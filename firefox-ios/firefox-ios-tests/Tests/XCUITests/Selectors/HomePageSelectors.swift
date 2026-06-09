// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol HomePageSelectorsSet {
    var COLLECTION_VIEW: Selector { get }
    var TABS_BUTTON: Selector { get }
    var HOME_LOGO: Selector { get }
    var PRIVATE_HOME_TITLE: Selector { get }
    var all: [Selector] { get }
}

struct HomePageSelectors: HomePageSelectorsSet {
    private enum IDs {
        static let collectionView = "FxCollectionView"
        static let tabsButton = AccessibilityIdentifiers.Toolbar.tabsButton
        static let homeLogo = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.logoID
        static let privateHomepageTitle = AccessibilityIdentifiers.PrivateMode.Homepage.title
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

    let HOME_LOGO = Selector.imageId(
        IDs.homeLogo,
        description: "Firefox Home logo image",
        groups: ["homepage"]
    )

    let PRIVATE_HOME_TITLE = Selector.staticTextId(
        IDs.privateHomepageTitle,
        description: "Title of the private browsing homepage",
        groups: ["homepage", "private_browsing"]
    )

    var all: [Selector] { [COLLECTION_VIEW, TABS_BUTTON, HOME_LOGO, PRIVATE_HOME_TITLE] }
}
