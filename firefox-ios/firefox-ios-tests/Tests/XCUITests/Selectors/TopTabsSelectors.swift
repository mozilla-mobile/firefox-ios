// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol TopTabsSelectorsSet {
    var PRIVATE_MODE_BUTTON: Selector { get }
    var all: [Selector] { get }
}

struct TopTabsSelectors: TopTabsSelectorsSet {
    private enum IDs {
        static let privateModeButton = AccessibilityIdentifiers.Browser.TopTabs.privateModeButton
    }

    let PRIVATE_MODE_BUTTON = Selector.buttonId(
        IDs.privateModeButton,
        description: "Private Browsing button in the Top Tabs bar",
        groups: ["browser", "topTabs"]
    )

    var all: [Selector] { [PRIVATE_MODE_BUTTON] }
}
