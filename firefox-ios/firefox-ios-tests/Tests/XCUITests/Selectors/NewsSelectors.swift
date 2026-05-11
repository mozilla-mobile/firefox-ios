// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol NewsSelectorsSet {
    var NEWS_SECTION: Selector { get }
    var ALL_CATEGORY_BUTTON: Selector { get }
    var CATEGORY_BUTTONS: Selector { get }
    var FIRST_STORY_CELL: Selector { get }
    var all: [Selector] { get }
}

struct NewsSelectors: NewsSelectorsSet {
    private enum IDs {
        static let newsSection = "News"
        static let allCategory = AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory
        static let categoryPrefix = AccessibilityIdentifiers.FirefoxHomepage.Pocket.category + "."
        static let itemCell = AccessibilityIdentifiers.FirefoxHomepage.Pocket.itemCell
    }

    let NEWS_SECTION = Selector(
        strategy: .predicate(
            NSPredicate(
                format: "elementType == %d AND (identifier == %@ OR label == %@)",
                XCUIElement.ElementType.other.rawValue,
                IDs.newsSection,
                IDs.newsSection
            )
        ),
        value: IDs.newsSection,
        description: "News section on Firefox homepage",
        groups: ["homepage", "news"]
    )

    let ALL_CATEGORY_BUTTON = Selector.buttonId(
        IDs.allCategory,
        description: "All news category button",
        groups: ["homepage", "news"]
    )

    let CATEGORY_BUTTONS = Selector(
        strategy: .predicate(
            NSPredicate(
                format: "elementType == %d AND identifier BEGINSWITH %@ AND identifier != %@",
                XCUIElement.ElementType.button.rawValue,
                IDs.categoryPrefix,
                IDs.allCategory
            )
        ),
        value: IDs.categoryPrefix,
        description: "News category buttons except All",
        groups: ["homepage", "news"]
    )

    let FIRST_STORY_CELL = Selector.cellById(
        IDs.itemCell,
        description: "First news story cell",
        groups: ["homepage", "news"]
    )

    var all: [Selector] {
        [
            NEWS_SECTION,
            ALL_CATEGORY_BUTTON,
            CATEGORY_BUTTONS,
            FIRST_STORY_CELL
        ]
    }
}
