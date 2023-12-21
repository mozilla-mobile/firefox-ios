// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest
import Shared

@testable import Client

actor MockRustFirefoxSuggest: RustFirefoxSuggestActor {
    func ingest() async throws {
    }
    func query(_ keyword: String, includeSponsored: Bool, includeNonSponsored: Bool) async throws -> [RustFirefoxSuggestion] {
        return [RustFirefoxSuggestion(title: "Mozilla",
                                      url: URL(string: "https://mozilla.org")!,
                                      isSponsored: true,
                                      iconImage: nil,
                                      fullKeyword: "mozilla"
                                     )]
    }
    nonisolated func interruptReader() {
    }
}

@MainActor
class SearchViewControllerTest: XCTestCase {
    var profile: MockProfile!
    var searchViewController: SearchViewController!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        LegacyFeatureFlagsManager.shared.set(feature: .firefoxSuggestFeature, to: true)

        let mockSearchEngineProvider = MockSearchEngineProvider()
        let engines = SearchEngines(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
        )
        let viewModel = SearchViewModel(isPrivate: false, isBottomSearchBar: false)

        searchViewController = SearchViewController(profile: profile, viewModel: viewModel, model: engines, tabManager: MockTabManager())
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testFirefoxSuggestionReturnsSponsoredAndNonSponsored() async throws {
        profile.prefs.setBool(true, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)
        profile.prefs.setBool(true, forKey: PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions)
        await searchViewController.loadFirefoxSuggestions()?.value

        XCTAssertEqual(searchViewController.firefoxSuggestions.count, 1)
    }

    func testFirefoxSuggestionReturnsNoSuggestions() async throws {
        profile.prefs.setBool(false, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions )
        profile.prefs.setBool(false, forKey: PrefsKeys.FirefoxSuggestShowNonSponsoredSuggestions)
        await searchViewController.loadFirefoxSuggestions()?.value

        XCTAssertEqual(searchViewController.firefoxSuggestions.count, 0)
    }
}
