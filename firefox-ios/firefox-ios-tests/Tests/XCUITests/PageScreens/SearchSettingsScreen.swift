// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SearchSettingsScreen {
    private let app: XCUIApplication
    private let sel: SearchSettingsSelectorsSet

    private var navBar: XCUIElement { sel.NAVBAR.element(in: app) }
    private var trendingSearchesToggle: XCUIElement { sel.TRENDING_SEARCH_SWITCH.element(in: app) }
    private var recentSearchesToggle: XCUIElement { sel.RECENT_SEARCH_SWITCH.element(in: app) }

    init(app: XCUIApplication, selectors: SearchSettingsSelectorsSet = SearchSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertNavBarVisible() {
        BaseTestCase().mozWaitForElementToExist(navBar)
    }

    func tapOnBackButton() {
        var backButton = sel.BACK_BUTTON.element(in: app)
        if #available(iOS 26, *) {
            backButton = sel.BACK_BUTTON_iOS26.element(in: app)
        }
        backButton.waitAndTap()
    }

    func assertTrendingSearchesSwitchIsOn() {
        BaseTestCase().mozWaitForElementToExist(trendingSearchesToggle)

        let value = trendingSearchesToggle.value as? String
        XCTAssertEqual(value, "1", "Expected 'Enable Trending Searches' switch to be ON (value = 1), but got \(String(describing: value))")
    }

    func tapOnTrendingSearchesSwitch() {
        trendingSearchesToggle.waitAndTap()
    }

    func assertTrendingSearchesSwitchIsOff() {
        BaseTestCase().mozWaitForElementToExist(trendingSearchesToggle)

        let value = trendingSearchesToggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Enable Translations' switch to be OFF (value = 0), but got \(String(describing: value))")
    }

    func assertTrendingSearchesSwitchDoesNotExist() {
        BaseTestCase().mozWaitForElementToNotExist(trendingSearchesToggle)
    }

    func assertRecentSearchesSwitchIsOn() {
        BaseTestCase().mozWaitForElementToExist(recentSearchesToggle)

        let value = recentSearchesToggle.value as? String
        XCTAssertEqual(value, "1", "Expected 'Enable Recent Searches' switch to be ON (value = 1), but got \(String(describing: value))")
    }

    func tapOnRecentSearchesSwitch() {
        recentSearchesToggle.waitAndTap()
    }

    func assertRecentSearchesSwitchIsOff() {
        BaseTestCase().mozWaitForElementToExist(recentSearchesToggle)

        let value = recentSearchesToggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Enable Recent Searches' switch to be OFF (value = 0), but got \(String(describing: value))")
    }

    func assertRecentSearchesSwitchDoesNotExist() {
        BaseTestCase().mozWaitForElementToNotExist(recentSearchesToggle)
    }

    func waitForSearchEngineSelectionComplete(timeout: TimeInterval = TIMEOUT) {
        let defaultSearchEngineNavBar = sel.DEFAULT_SEARCH_ENGINE_NAVBAR.element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(defaultSearchEngineNavBar, timeout: timeout)
    }
}
