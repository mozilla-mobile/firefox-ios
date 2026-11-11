// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

protocol HomePageSelectorsSet {
    var COLLECTION_VIEW: Selector { get }
    var TABS_BUTTON: Selector { get }
    var HOME_LOGO: Selector { get }
    var PRIVATE_HOME_TITLE: Selector { get }
    var TRACKER_BLOCKER_PILL: Selector { get }
    var TRACKER_BLOCKER_SHEET_WEEKLY_COUNT: Selector { get }
    var TRACKER_BLOCKER_SHEET_TOTAL: Selector { get }
    var TRACKER_BLOCKER_SHEET_CLOSE_BUTTON: Selector { get }
    func trackerBlockerSheetCategoryRow(_ index: Int) -> Selector
    var all: [Selector] { get }
}

struct HomePageSelectors: HomePageSelectorsSet {
    private enum IDs {
        static let collectionView = "FxCollectionView"
        static let tabsButton = AccessibilityIdentifiers.Toolbar.tabsButton
        static let homeLogo = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons.logoID
        static let privateHomepageTitle = AccessibilityIdentifiers.PrivateMode.Homepage.title
        static let trackerBlockerPill = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.containerPill
        static let trackerBlockerWeeklyCount =
            AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.weeklyCountLabel
        static let trackerBlockerTotal = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.totalPill
        static let trackerBlockerClose = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.closeButton
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

    let TRACKER_BLOCKER_PILL = Selector.anyElementById(
        IDs.trackerBlockerPill,
        description: "Tracker Blocker pill showing the lifetime blocked trackers count",
        groups: ["homepage", "tracker_blocker"]
    )

    let TRACKER_BLOCKER_SHEET_WEEKLY_COUNT = Selector.anyElementById(
        IDs.trackerBlockerWeeklyCount,
        description: "Weekly blocked trackers total in the Tracker Blocker sheet",
        groups: ["homepage", "tracker_blocker"]
    )

    let TRACKER_BLOCKER_SHEET_TOTAL = Selector.anyElementById(
        IDs.trackerBlockerTotal,
        description: "Lifetime blocked trackers chip in the Tracker Blocker sheet footer",
        groups: ["homepage", "tracker_blocker"]
    )

    let TRACKER_BLOCKER_SHEET_CLOSE_BUTTON = Selector.buttonId(
        IDs.trackerBlockerClose,
        description: "Close button of the Tracker Blocker sheet",
        groups: ["homepage", "tracker_blocker"]
    )

    func trackerBlockerSheetCategoryRow(_ index: Int) -> Selector {
        Selector.anyElementById(
            AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet.categoryRow(index),
            description: "Tracker category row \(index) in the Tracker Blocker sheet",
            groups: ["homepage", "tracker_blocker"]
        )
    }

    var all: [Selector] {
        [
            COLLECTION_VIEW,
            TABS_BUTTON,
            HOME_LOGO,
            PRIVATE_HOME_TITLE,
            TRACKER_BLOCKER_PILL,
            TRACKER_BLOCKER_SHEET_WEEKLY_COUNT,
            TRACKER_BLOCKER_SHEET_TOTAL,
            TRACKER_BLOCKER_SHEET_CLOSE_BUTTON
        ]
    }
}
