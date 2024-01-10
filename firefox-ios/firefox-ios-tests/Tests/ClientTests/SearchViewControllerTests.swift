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
    func query(
        _ keyword: String,
        includeSponsored: Bool,
        includeNonSponsored: Bool
    ) async throws -> [RustFirefoxSuggestion] {
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
    var remoteClient: RemoteClient!

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

        searchViewController = SearchViewController(
            profile: profile,
            viewModel: viewModel,
            model: engines,
            tabManager: MockTabManager()
        )

        remoteClient = RemoteClient(
            guid: nil,
            name: "Fake client",
            modified: 1,
            type: nil,
            formfactor: nil,
            os: nil,
            version: nil,
            fxaDeviceId: nil
        )
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

    func testHistoryandBookmarksAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        profile.prefs.setBool(true, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])
        searchViewController.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 2)
    }

    func testHistoryAndBookmarksAreNotFilteredWhenShowSponsoredSuggestionsIsFalse() {
        profile.prefs.setBool(false, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])
        searchViewController.loader(dataLoaded: data)
        XCTAssertEqual(searchViewController.data.count, 3)
    }

    func testSyncTabsAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        profile.prefs.setBool(true, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)
        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil
        )
        searchViewController.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        searchViewController.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(searchViewController.filteredRemoteClientTabs.count, 2)
    }

    func testSyncedTabssAreNotFilteredWhenShowSponsoredSuggestionsIsTrue() {
        profile.prefs.setBool(false, forKey: PrefsKeys.FirefoxSuggestShowSponsoredSuggestions)

        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil
        )
        searchViewController.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        searchViewController.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(searchViewController.filteredRemoteClientTabs.count, 3)
    }
}
