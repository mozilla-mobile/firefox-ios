// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest

@testable import Client

@MainActor
class SearchViewControllerTest: XCTestCase {
    var profile: MockProfile!
    var searchEnginesManager: SearchEnginesManager!
    var searchViewController: SearchViewController!

    override func setUp() async throws {
        try await super.setUp()
        profile = makeProfile(firefoxSuggest: MockRustFirefoxSuggest())
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)

        let mockSearchEngineProvider = MockSearchEngineProvider()
        searchEnginesManager = SearchEnginesManager(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
        )
        let viewModel = SearchViewModel(
            isPrivate: false,
            isBottomSearchBar: false,
            profile: profile,
            model: searchEnginesManager,
            tabManager: MockTabManager(),
            trendingSearchClient: MockTrendingSearchClient(),
            recentSearchProvider: MockRecentSearchProvider()
        )

        searchViewController = SearchViewController(
            profile: profile,
            viewModel: viewModel,
            tabManager: MockTabManager()
        )
    }

    override func tearDown() async throws {
        searchViewController = nil
        searchEnginesManager = nil
        DependencyHelperMock().reset()
        profile = nil
        try await super.tearDown()
    }

    func testHistoryAndBookmarksAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let data = ArrayCursor<Site>(data: [ Site.createBasicSite(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site.createBasicSite(url: "https://example.com", title: "Test2"),
                                             Site.createBasicSite(url: "https://example.com?a=b&c=d", title: "Test3")])

        searchViewController.viewModel.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 2)
    }

    func testHistoryAndBookmarksAreNotFilteredWhenShowSponsoredSuggestionsIsFalse() {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let data = ArrayCursor<Site>(data: [ Site.createBasicSite(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site.createBasicSite(url: "https://example.com", title: "Test2"),
                                             Site.createBasicSite(url: "https://example.com?a=b&c=d", title: "Test3")])
        searchViewController.viewModel.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 3)
    }

    // MARK: - Empty title fallback

    func testHistoryCell_withTitle_showsTitleAndURL() throws {
        setNonZeroSearchState()
        searchViewController.searchData = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://example.com", title: "Example")
        ])

        let cell = try cell(for: .history)

        XCTAssertEqual(cell.titleLabel.text, "Example")
        XCTAssertEqual(cell.descriptionLabel.text, "https://example.com")
        XCTAssertFalse(cell.descriptionLabel.isHidden)
    }

    func testHistoryCell_withEmptyTitle_showsURLAsTitleAndHidesDescription() throws {
        setNonZeroSearchState()
        searchViewController.searchData = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://example.com", title: "")
        ])

        let cell = try cell(for: .history)

        XCTAssertEqual(cell.titleLabel.text, "https://example.com")
        XCTAssertTrue(cell.descriptionLabel.isHidden)
    }

    func testBookmarkCell_withEmptyTitle_showsURLAsTitleAndHidesDescription() throws {
        setNonZeroSearchState()
        searchViewController.searchData = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://example.com", title: "", isBookmarked: true)
        ])

        let cell = try cell(for: .bookmarks)

        XCTAssertEqual(cell.titleLabel.text, "https://example.com")
        XCTAssertTrue(cell.descriptionLabel.isHidden)
    }

    func testHistoryCell_reusedAfterEmptyTitle_showsDescriptionAgain() throws {
        setNonZeroSearchState()
        searchViewController.searchData = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://example.com", title: "")
        ])
        let cell = try cell(for: .history)
        XCTAssertTrue(cell.descriptionLabel.isHidden)

        searchViewController.searchData = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://mozilla.org", title: "Mozilla")
        ])
        let reusedCell = try XCTUnwrap(
            searchViewController.tableView(
                searchViewController.tableView,
                cellForRowAt: IndexPath(row: 0, section: SearchListSection.history.rawValue)
            ) as? TwoLineImageOverlayCell
        )

        XCTAssertEqual(reusedCell.titleLabel.text, "Mozilla")
        XCTAssertEqual(reusedCell.descriptionLabel.text, "https://mozilla.org")
        XCTAssertFalse(reusedCell.descriptionLabel.isHidden)
    }

    func testOpenedTabCell_withLastTitle_showsLastTitle() throws {
        let tab = createTab(url: "https://example.com", lastTitle: "Example")
        setNonZeroSearchState()
        searchViewController.viewModel.filteredOpenedTabs = [tab]

        let cell = try cell(for: .openedTabs)

        XCTAssertEqual(cell.titleLabel.text, "Example")
    }

    func testOpenedTabCell_withEmptyLastTitle_fallsBackToURL() throws {
        let tab = createTab(url: "https://example.com", lastTitle: "")
        setNonZeroSearchState()
        searchViewController.viewModel.filteredOpenedTabs = [tab]

        let cell = try cell(for: .openedTabs)

        XCTAssertEqual(cell.titleLabel.text, "https://example.com")
    }

    func testOpenedTabCell_withNoTitle_fallsBackToURL() throws {
        let tab = createTab(url: "https://example.com", lastTitle: nil)
        setNonZeroSearchState()
        searchViewController.viewModel.filteredOpenedTabs = [tab]

        let cell = try cell(for: .openedTabs)

        XCTAssertEqual(cell.titleLabel.text, "https://example.com")
    }

    func testRemoteTabCell_withTitle_showsTitle() throws {
        setNonZeroSearchState()
        searchViewController.viewModel.filteredRemoteClientTabs = [
            ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab(title: "Example"))
        ]

        let cell = try cell(for: .remoteTabs)

        XCTAssertEqual(cell.titleLabel.text, "Example")
        XCTAssertEqual(cell.descriptionLabel.text, "Fake client")
    }

    func testRemoteTabCell_withEmptyTitle_fallsBackToURL() throws {
        setNonZeroSearchState()
        searchViewController.viewModel.filteredRemoteClientTabs = [
            ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab(title: ""))
        ]

        let cell = try cell(for: .remoteTabs)

        XCTAssertEqual(cell.titleLabel.text, "https://example.com")
        XCTAssertEqual(cell.descriptionLabel.text, "Fake client")
    }

    // MARK: - Helpers

    /// Uses a URL-like query so `querySuggestClient()` returns early instead of spawning a
    /// `loadFirefoxSuggestions()` task that would resolve dependencies after `tearDown` resets them.
    private func setNonZeroSearchState() {
        searchViewController.viewModel.searchQuery = "example.com/"
    }

    private func cell(for section: SearchListSection) throws -> TwoLineImageOverlayCell {
        let cell = searchViewController.tableView(
            searchViewController.tableView,
            cellForRowAt: IndexPath(row: 0, section: section.rawValue)
        )
        return try XCTUnwrap(cell as? TwoLineImageOverlayCell)
    }

    private func createTab(url: String, lastTitle: String?) -> Tab {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: url)
        tab.lastTitle = lastTitle
        return tab
    }

    private var remoteClient: RemoteClient {
        return RemoteClient(guid: nil,
                            name: "Fake client",
                            modified: 1,
                            type: nil,
                            formfactor: nil,
                            os: nil,
                            version: nil,
                            fxaDeviceId: nil)
    }

    private func remoteTab(title: String) -> RemoteTab {
        return RemoteTab(clientGUID: "1",
                         URL: URL(string: "https://example.com")!,
                         title: title,
                         history: [],
                         lastUsed: 1,
                         icon: nil)
    }
}
