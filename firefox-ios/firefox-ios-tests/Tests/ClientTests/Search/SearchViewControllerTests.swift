// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import XCTest

@testable import Client

class SearchViewControllerTest: XCTestCase {
    var profile: MockProfile!
    var searchEnginesManager: SearchEnginesManager!
    var searchViewController: SearchViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        LegacyFeatureFlagsManager.shared.set(feature: .firefoxSuggestFeature, to: true)

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
            tabManager: MockTabManager()
        )

        searchViewController = SearchViewController(
            profile: profile,
            viewModel: viewModel,
            tabManager: MockTabManager()
        )
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testHistoryAndBookmarksAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])

        searchViewController.viewModel.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 2)
    }

    func testHistoryAndBookmarksAreNotFilteredWhenShowSponsoredSuggestionsIsFalse() {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])
        searchViewController.viewModel.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 3)
    }
}
