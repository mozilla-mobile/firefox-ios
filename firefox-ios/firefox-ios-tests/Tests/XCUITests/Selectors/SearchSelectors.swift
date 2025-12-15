// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol SearchSelectorsSet {
    var SEARCH_TABLE: Selector { get }
    var RECENT_SEARCHES_SECTION_TITLE: Selector { get }
    func searchSectionTitle(with text: String) -> Selector
    func trendingSearchesSectionTitle(with text: String) -> Selector
    var all: [Selector] { get }
}

struct SearchSelectors: SearchSelectorsSet {
    private enum IDs {
        static let table                          = "SiteTable"
        static let recentSearchesSectionTitle     = "Recent Searches"
    }

    let SEARCH_TABLE = Selector.tableIdOrLabel(
        IDs.table,
        description: "Search screen table view cell",
        groups: ["settings", "search"]
    )

    let RECENT_SEARCHES_SECTION_TITLE = Selector.staticTextByLabel(
        IDs.recentSearchesSectionTitle,
        description: "Search screen table view cell",
        groups: ["settings", "search", "recent searches"]
    )

    func searchSectionTitle(with engineName: String) -> Selector {
        Selector.staticTextByExactLabel(
            "\(engineName) Search",
            description: "Search screen general searches section title",
            groups: ["browser", "search"]
        )
    }

    func trendingSearchesSectionTitle(with engineName: String) -> Selector {
        Selector.staticTextByExactLabel(
            "Trending on \(engineName)",
            description: "Search screen trending searches section title",
            groups: ["browser", "search", "trending searches"]
        )
    }

    var all: [Selector] {
        [SEARCH_TABLE, RECENT_SEARCHES_SECTION_TITLE]
    }
}
