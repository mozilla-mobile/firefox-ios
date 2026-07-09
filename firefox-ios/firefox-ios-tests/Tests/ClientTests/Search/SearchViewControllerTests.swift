// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import UIKit
import XCTest

@testable import Client

@MainActor
class SearchViewControllerTest: XCTestCase {
    var profile: MockProfile!
    var searchEnginesManager: SearchEnginesManager!
    var searchViewController: SearchViewController!
    var mockSearchDelegate: MockSearchViewControllerDelegate!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
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
        mockSearchDelegate = MockSearchViewControllerDelegate()
        searchViewController.searchDelegate = mockSearchDelegate
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        mockSearchDelegate = nil
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

    // MARK: - Append button

    func testAppendButton_onSuggestionRow_fillsThatRowsTextWithoutSubmitting() {
        searchViewController.loadViewIfNeeded()
        searchViewController.tableView.layoutIfNeeded()
        searchViewController.viewModel.suggestions = ["hello", "hello fresh", "hello kitty"]
        searchViewController.viewModel.savedQuery = "hello"

        let indexPath = IndexPath(row: 2, section: SearchListSection.searchSuggestions.rawValue)
        let cell = searchViewController.tableView(searchViewController.tableView, cellForRowAt: indexPath)

        guard let appendButton = firstButton(in: cell.accessoryView) else {
            XCTFail("Expected an accessory button on row \(indexPath.row)")
            return
        }

        appendButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(mockSearchDelegate.appendedTexts, ["hello kitty "])
        XCTAssertEqual(mockSearchDelegate.didSelectURLCallCount, 0)

        drainPendingViewControllerWork()
    }

    func testAppendButton_firstSuggestionRow_hasNoAccessoryView() {
        searchViewController.loadViewIfNeeded()
        searchViewController.tableView.layoutIfNeeded()
        searchViewController.viewModel.suggestions = ["hello", "hello fresh", "hello kitty"]
        searchViewController.viewModel.savedQuery = "hello"

        let indexPath = IndexPath(row: 0, section: SearchListSection.searchSuggestions.rawValue)
        let cell = searchViewController.tableView(searchViewController.tableView, cellForRowAt: indexPath)

        XCTAssertNil(firstButton(in: cell.accessoryView), "The typed-query row should not have an append button")

        drainPendingViewControllerWork()
    }

    func testAppendButton_afterSuggestionsRefresh_fillsUpdatedRowText() {
        searchViewController.loadViewIfNeeded()
        searchViewController.tableView.layoutIfNeeded()
        searchViewController.viewModel.suggestions = ["hello", "hello fresh", "hello kitty"]
        searchViewController.viewModel.savedQuery = "hello"

        let indexPath = IndexPath(row: 2, section: SearchListSection.searchSuggestions.rawValue)
        _ = searchViewController.tableView(searchViewController.tableView, cellForRowAt: indexPath)

        // Simulate cell reuse: suggestions changed, same row re-configured.
        searchViewController.viewModel.suggestions = ["hi", "hi there", "hi mom"]
        searchViewController.viewModel.savedQuery = "hi"
        let reusedCell = searchViewController.tableView(searchViewController.tableView, cellForRowAt: indexPath)

        guard let appendButton = firstButton(in: reusedCell.accessoryView) else {
            XCTFail("Expected an accessory button on the reused row")
            return
        }

        appendButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(mockSearchDelegate.appendedTexts, ["hi mom "])

        drainPendingViewControllerWork()
    }

    /// `loadViewIfNeeded()` can leave main-queue-deferred UIKit work (e.g. from `viewDidLoad`) pending past the
    /// end of the test. If it fires during a *later* test, after that test's `tearDown` has already reset the
    /// shared `AppContainer`, it crashes on a missing DI registration. Draining the run loop here lets any such
    /// work fire while this test's container registrations are still valid.
    private func drainPendingViewControllerWork() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    /// Recursively finds the first `UIButton`, since `OneLineTableViewCell` wraps the accessory view in a container.
    private func firstButton(in view: UIView?) -> UIButton? {
        guard let view else { return nil }
        if let button = view as? UIButton { return button }
        for subview in view.subviews {
            if let button = firstButton(in: subview) {
                return button
            }
        }
        return nil
    }
}

final class MockSearchViewControllerDelegate: SearchViewControllerDelegate {
    var didSelectURLCallCount = 0
    var lastSelectedURL: URL?
    var lastSearchTerm: String?
    var lastUUID: String?
    var presentSearchSettingsControllerCallCount = 0
    var highlightedTexts: [String] = []
    var lastHighlightSearch: Bool?
    var appendedTexts: [String] = []
    var willHideCallCount = 0

    func searchViewController(_ searchViewController: SearchViewController, didSelectURL url: URL, searchTerm: String?) {
        didSelectURLCallCount += 1
        lastSelectedURL = url
        lastSearchTerm = searchTerm
    }

    func searchViewController(_ searchViewController: SearchViewController, uuid: String) {
        lastUUID = uuid
    }

    func presentSearchSettingsController() {
        presentSearchSettingsControllerCallCount += 1
    }

    func searchViewController(_ searchViewController: SearchViewController, didHighlightText text: String, search: Bool) {
        highlightedTexts.append(text)
        lastHighlightSearch = search
    }

    func searchViewController(_ searchViewController: SearchViewController, didAppend text: String) {
        appendedTexts.append(text)
    }

    func searchViewControllerWillHide(_ searchViewController: SearchViewController) {
        willHideCallCount += 1
    }
}
