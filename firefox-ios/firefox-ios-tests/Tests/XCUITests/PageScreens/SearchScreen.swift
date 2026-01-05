// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SearchScreen {
    private let app: XCUIApplication
    private let sel: SearchSelectorsSet

    private var searchTable: XCUIElement { sel.SEARCH_TABLE.element(in: app) }
    private var recentSearchesSectionTitle: XCUIElement { sel.RECENT_SEARCHES_SECTION_TITLE.element(in: app) }

    init(app: XCUIApplication, selectors: SearchSelectorsSet = SearchSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertSearchTableVisible() {
        BaseTestCase().mozWaitForElementToExist(searchTable)
    }

    func assertSearchSectionVisible(with engineName: String) {
        let text = sel.searchSectionTitle(with: engineName).element(in: app)
        BaseTestCase().mozWaitForElementToExist(text)
    }

    func tapOnFirstCell() {
        searchTable.cells.firstMatch.waitAndTap()
    }

    func assertTrendingSearchesSectionTitle(with engineName: String) {
        let text = sel.trendingSearchesSectionTitle(with: engineName).element(in: app)
        BaseTestCase().mozWaitForElementToExist(text)
    }

    func assertTrendingSearchesSectionTitleDoesNotExist(with engineName: String) {
        _ = sel.trendingSearchesSectionTitle(with: engineName).element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(recentSearchesSectionTitle)
    }

    func assertRecentSearchesSectionTitle() {
        BaseTestCase().mozWaitForElementToExist(recentSearchesSectionTitle)
    }

    func assertRecentSearchesSectionTitleDoesNotExist() {
        BaseTestCase().mozWaitForElementToNotExist(recentSearchesSectionTitle)
    }
}
