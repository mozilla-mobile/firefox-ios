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
    var DEFAULT_SEARCH_ENGINE_SECTION_TITLE: Selector { get }
    var ALTERNATIVE_SEARCH_ENGINES_SECTION_TITLE: Selector { get }
    var ADD_SEARCH_ENGINE_ROW: Selector { get }
    var SHOW_SEARCH_SUGGESTIONS_SWITCH: Selector { get }
    var SHOW_IN_PRIVATE_SESSIONS_SWITCH: Selector { get }
    var SEARCH_BROWSING_HISTORY_SWITCH: Selector { get }
    var SEARCH_BOOKMARKS_SWITCH: Selector { get }
    var SEARCH_SYNCED_TABS_SWITCH: Selector { get }
    var SUGGESTIONS_FROM_THE_WEB_SWITCH: Selector { get }
    var SUGGESTIONS_FROM_SPONSORS_SWITCH: Selector { get }
    var LEARN_MORE_ABOUT_FIREFOX_SUGGEST_ROW: Selector { get }
    func searchEngineRow(named engineName: String) -> Selector
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
        static let defaultSearchEngineSectionTitle = "Default Search Engine"
        static let alternativeSearchEnginesSectionTitle = "Alternative Search Engines"
        static let addSearchEngineRow          = AccessibilityIdentifiers.Settings.Search.customEngineViewButton
        static let showSearchSuggestionsSwitch = AccessibilityIdentifiers.Settings.Search.showSearchSuggestions
        static let showInPrivateSessionsSwitch =
            AccessibilityIdentifiers.Settings.Search.showPrivateModeSearchSuggestionsSwitch
        static let searchBrowsingHistorySwitch =
            AccessibilityIdentifiers.Settings.Search.showBrowsingHistorySuggestionsSwitch
        static let searchBookmarksSwitch       = AccessibilityIdentifiers.Settings.Search.showBookmarksSuggestionsSwitch
        static let searchSyncedTabsSwitch      = AccessibilityIdentifiers.Settings.Search.showSyncedTabsSuggestionsSwitch
        static let suggestionsFromTheWebSwitch =
            AccessibilityIdentifiers.Settings.Search.showNonSponsoredSuggestionsSwitch
        static let suggestionsFromSponsorsSwitch =
            AccessibilityIdentifiers.Settings.Search.showSponsoredSuggestionsSwitch
        static let learnMoreAboutFirefoxSuggestRow = "Learn more about Firefox Suggest"
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

    let DEFAULT_SEARCH_ENGINE_SECTION_TITLE = Selector.staticTextByExactLabel(
        IDs.defaultSearchEngineSectionTitle,
        description: "Section title for the default search engine on Settings → Search",
        groups: ["settings", "search"]
    )

    let ALTERNATIVE_SEARCH_ENGINES_SECTION_TITLE = Selector.staticTextByExactLabel(
        IDs.alternativeSearchEnginesSectionTitle,
        description: "Section title for alternative search engines on Settings → Search",
        groups: ["settings", "search"]
    )

    let ADD_SEARCH_ENGINE_ROW = Selector.tableCellById(
        IDs.addSearchEngineRow,
        description: "Add Search Engine row on Settings → Search",
        groups: ["settings", "search"]
    )

    let SHOW_SEARCH_SUGGESTIONS_SWITCH = Selector.switchById(
        IDs.showSearchSuggestionsSwitch,
        description: "Switch for 'Show Search Suggestions' on Settings → Search",
        groups: ["settings", "search"]
    )

    let SHOW_IN_PRIVATE_SESSIONS_SWITCH = Selector.switchById(
        IDs.showInPrivateSessionsSwitch,
        description: "Switch for 'Show in Private Sessions' on Settings → Search",
        groups: ["settings", "search"]
    )

    let SEARCH_BROWSING_HISTORY_SWITCH = Selector.switchById(
        IDs.searchBrowsingHistorySwitch,
        description: "Switch for 'Search Browsing History' on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    let SEARCH_BOOKMARKS_SWITCH = Selector.switchById(
        IDs.searchBookmarksSwitch,
        description: "Switch for 'Search Bookmarks' on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    let SEARCH_SYNCED_TABS_SWITCH = Selector.switchById(
        IDs.searchSyncedTabsSwitch,
        description: "Switch for 'Search Synced Tabs' on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    let SUGGESTIONS_FROM_THE_WEB_SWITCH = Selector.switchById(
        IDs.suggestionsFromTheWebSwitch,
        description: "Switch for 'Suggestions from the Web' on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    let SUGGESTIONS_FROM_SPONSORS_SWITCH = Selector.switchById(
        IDs.suggestionsFromSponsorsSwitch,
        description: "Switch for 'Suggestions from Sponsors' on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    let LEARN_MORE_ABOUT_FIREFOX_SUGGEST_ROW = Selector.staticTextInTablesByLabel(
        IDs.learnMoreAboutFirefoxSuggestRow,
        description: "'Learn more about Firefox Suggest' row on Settings → Search",
        groups: ["settings", "search", "firefox suggest"]
    )

    func searchEngineRow(named engineName: String) -> Selector {
        Selector.staticTextInTablesByLabel(
            engineName,
            description: "Row for '\(engineName)' search engine on Settings → Search",
            groups: ["settings", "search"]
        )
    }

    var all: [Selector] {
        [
            NAVBAR, BACK_BUTTON_iOS26, BACK_BUTTON, TRENDING_SEARCH_SWITCH, RECENT_SEARCH_SWITCH,
            DEFAULT_SEARCH_ENGINE_NAVBAR, DEFAULT_SEARCH_ENGINE_SECTION_TITLE, ALTERNATIVE_SEARCH_ENGINES_SECTION_TITLE,
            ADD_SEARCH_ENGINE_ROW, SHOW_SEARCH_SUGGESTIONS_SWITCH, SHOW_IN_PRIVATE_SESSIONS_SWITCH,
            SEARCH_BROWSING_HISTORY_SWITCH, SEARCH_BOOKMARKS_SWITCH, SEARCH_SYNCED_TABS_SWITCH,
            SUGGESTIONS_FROM_THE_WEB_SWITCH, SUGGESTIONS_FROM_SPONSORS_SWITCH, LEARN_MORE_ABOUT_FIREFOX_SUGGEST_ROW
        ]
    }
}
