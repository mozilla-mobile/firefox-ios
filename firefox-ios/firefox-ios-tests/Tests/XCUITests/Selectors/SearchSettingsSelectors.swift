// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SearchSettingsSelectorsSet {
    var NAVBAR: Selector { get }
    var BACK_BUTTON_iOS26: Selector { get }
    var BACK_BUTTON: Selector { get }
    var TRENDING_SEARCH_SWITCH: Selector { get }
    var RECENT_SEARCH_SWITCH: Selector { get }
    var DEFAULT_SEARCH_ENGINE_NAVBAR: Selector { get }
    var all: [Selector] { get }
}

struct SearchSettingsSelectors: SearchSettingsSelectorsSet {
    private enum IDs {
        static let navBar                   = AccessibilityIdentifiers.Settings.Search.searchNavigationBar
        static let trendingSearchesSwitch   = AccessibilityIdentifiers.Settings.Search.showTrendingSearchesSwitch
        static let recentSearchesSwitch     = AccessibilityIdentifiers.Settings.Search.showRecentSearchesSwitch
        static let backButtoniOS26          = AccessibilityIdentifiers.Settings.Search.backButtoniOS26
        static let backButton               = AccessibilityIdentifiers.Settings.Search.backButton
        static let defaultSearchEngineNavBar = "Default Search Engine"
    }

    let NAVBAR = Selector.navigationBarId(
        IDs.navBar,
        description: "Search settings navigation bar",
        groups: ["settings", "search"]
    )

    let BACK_BUTTON_iOS26 = Selector.buttonId(
        IDs.backButtoniOS26,
        description: "Search settings back button for iOS 26",
        groups: ["settings", "search"]
    )

    let BACK_BUTTON = Selector.buttonByLabel(
        IDs.backButton,
        description: "Search settings back button (< iOS 26)",
        groups: ["settings", "search"]
    )

    let TRENDING_SEARCH_SWITCH = Selector.switchById(
        IDs.trendingSearchesSwitch,
        description: "Switch for 'Enable Trending Searches' in Settings → Search",
        groups: ["settings", "search", "trending searches"]
    )

    let RECENT_SEARCH_SWITCH = Selector.switchById(
        IDs.recentSearchesSwitch,
        description: "Switch for 'Enable Recent Searches' in Settings → Search",
        groups: ["settings", "search", "recent searches"]
    )

    let DEFAULT_SEARCH_ENGINE_NAVBAR = Selector.navigationBarId(
        IDs.defaultSearchEngineNavBar,
        description: "Default Search Engine navigation bar (appears when selecting engine)",
        groups: ["settings", "search"]
    )

    var all: [Selector] {
        [NAVBAR, BACK_BUTTON_iOS26, BACK_BUTTON, TRENDING_SEARCH_SWITCH, RECENT_SEARCH_SWITCH, DEFAULT_SEARCH_ENGINE_NAVBAR]
    }
}
