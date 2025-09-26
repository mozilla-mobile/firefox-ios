// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest

@testable import Client

final class SearchViewModelTests: XCTestCase {
    var profile: MockProfile!
    var mockDelegate: MockSearchDelegate!
    var searchEnginesManager: SearchEnginesManager!
    var remoteClient: RemoteClient!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        LegacyFeatureFlagsManager.shared.set(feature: .firefoxSuggestFeature, to: true)

        let mockSearchEngineProvider = MockSearchEngineProvider()
        mockDelegate = MockSearchDelegate()

        searchEnginesManager = SearchEnginesManager(
            prefs: profile.prefs,
            files: profile.files,
            engineProvider: mockSearchEngineProvider
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
        profile = nil
        super.tearDown()
    }

    func testHasFirefoxSuggestionsWhenAllConditionsAreFalse() {
        let subject = createSubject()
        searchEnginesManager.shouldShowBookmarksSuggestions = false
        searchEnginesManager.shouldShowBrowsingHistorySuggestions = false
        subject.filteredOpenedTabs = []
        subject.filteredRemoteClientTabs = []
        searchEnginesManager.shouldShowSyncedTabsSuggestions = false
        subject.firefoxSuggestions = []
        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        XCTAssertFalse(subject.hasFirefoxSuggestions)
    }

    func testHasFirefoxSuggestionsWhenFirefoxSuggestionsExistButShouldNotShowIsFalse() {
        let subject = createSubject()
        subject.firefoxSuggestions = [
            RustFirefoxSuggestion(title: "Test", url: URL(string: "https://google.com")!, isSponsored: true, iconImage: nil)
        ]
        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        XCTAssertFalse(subject.hasFirefoxSuggestions)
    }

    func testHasFirefoxSuggestionsWhenFirefoxSuggestionsExistAndShouldShowIsTrue() {
        let subject = createSubject()
        subject.firefoxSuggestions = [
            RustFirefoxSuggestion(title: "Test", url: URL(string: "https://google.com")!, isSponsored: true, iconImage: nil)
        ]
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        XCTAssertTrue(subject.hasFirefoxSuggestions)
    }

    @MainActor
    func testFirefoxSuggestionReturnsNoSuggestions() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: false, .wikipedia: false])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false

        let subject = createSubject()
        await subject.loadFirefoxSuggestions()
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)

        // Providers set to false, so regardless of the prefs, we shouldn't see anything
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        await subject.loadFirefoxSuggestions()
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)
    }

    @MainActor
    func testFirefoxSuggestionReturnsNoSuggestionsWhenSuggestionSettingsFalse() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false

        let subject = createSubject()

        await subject.loadFirefoxSuggestions()
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testFirefoxSuggestionReturnsSponsoredAndNonSponsored() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let subject = createSubject()
        await subject.loadFirefoxSuggestions()

        XCTAssertEqual(subject.firefoxSuggestions.count, 2)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    func testSyncedTabsAreFilteredWhenShowSponsoredSuggestionsIsTrue() {
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil,
            inactive: false
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil,
            inactive: false
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil,
            inactive: false
        )
        let subject = createSubject()
        subject.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        subject.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(subject.filteredRemoteClientTabs.count, 2)
    }

    func testSyncedTabsAreNotFilteredWhenShowSponsoredSuggestionsIsFalse() {
        searchEnginesManager.shouldShowSponsoredSuggestions = false

        let remoteTab1 = RemoteTab(
            clientGUID: "1",
            URL: URL(string: "www.mozilla.org?mfadid=adm")!,
            title: "Mozilla 1",
            history: [],
            lastUsed: UInt64(1),
            icon: nil,
            inactive: false
        )
        let remoteTab2 = RemoteTab(
            clientGUID: "2",
            URL: URL(string: "www.mozilla.org")!,
            title: "Mozilla 2",
            history: [],
            lastUsed: UInt64(2),
            icon: nil,
            inactive: false
        )
        let remoteTab3 = RemoteTab(
            clientGUID: "3",
            URL: URL(string: "www.mozilla.org?a=b")!,
            title: "Mozilla 3",
            history: [],
            lastUsed: UInt64(3),
            icon: nil,
            inactive: false
        )
        let subject = createSubject()
        subject.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        subject.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(subject.filteredRemoteClientTabs.count, 3)
    }

    @MainActor
    func testSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()
        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testNonSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testNonSponsoredAndSponsoredSuggestionsInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testNonSponsoredInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testNonSponsoredAndSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = false
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    @MainActor
    func testLoad_forFirefoxSuggestions_doesNotTriggerReloadForSameSuggestions() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let subject = createSubject()
        await subject.loadFirefoxSuggestions()
        await subject.loadFirefoxSuggestions()

        XCTAssertEqual(subject.firefoxSuggestions.count, 2)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    func testLoad_forHistoryAndBookmarks_doesNotTriggerReloadForSameSuggestions() async throws {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let subject = createSubject()
        XCTAssertEqual(subject.delegate?.searchData.count, 0)
        let data = ArrayCursor<Site>(data: [ Site.createBasicSite(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site.createBasicSite(url: "https://example.com", title: "Test2"),
                                             Site.createBasicSite(url: "https://example.com?a=b&c=d", title: "Test3")])
        subject.loader(dataLoaded: data)
        XCTAssertEqual(subject.delegate?.searchData.count, 3)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    func testLoad_multipleTimes_doesNotTriggerReloadForSameSuggestions() async throws {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let subject = createSubject()
        let data = ArrayCursor<Site>(data: [ Site.createBasicSite(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site.createBasicSite(url: "https://example.com", title: "Test2"),
                                             Site.createBasicSite(url: "https://example.com?a=b&c=d", title: "Test3")])
        subject.loader(dataLoaded: data)
        subject.loader(dataLoaded: data)
        XCTAssertEqual(subject.delegate?.searchData.count, 3)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    @MainActor
    func testFirefoxSuggestionReturnsSponsored() async {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        let subject = createSubject()
        await subject.loadFirefoxSuggestions()

        XCTAssertEqual(subject.firefoxSuggestions[0].title, "Mozilla")
        XCTAssertEqual(subject.firefoxSuggestions.count, 1)
    }

    @MainActor
    func testFirefoxSuggestionReturnsNonSponsored() async {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: true, .wikipedia: true])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let subject = createSubject()
        await subject.loadFirefoxSuggestions()

        XCTAssertEqual(subject.firefoxSuggestions[0].title, "California")
        XCTAssertEqual(subject.firefoxSuggestions.count, 1)
    }

    func testQuickSearchEnginesWithSearchSuggestionsEnabled() {
        let subject = createSubject()
        subject.searchEnginesManager = searchEnginesManager
        let quickSearchEngines = subject.quickSearchEngines

        let expectedEngineNames = ["BTester", "CTester", "DTester", "ETester", "FTester"]

        XCTAssertEqual(subject.searchEnginesManager?.defaultEngine?.shortName, "ATester")
        XCTAssertEqual(quickSearchEngines.map { $0.shortName }, expectedEngineNames)
        XCTAssertEqual(quickSearchEngines.count, 5)
    }

    func testQuickSearchEnginesWithSearchSuggestionsDisabled() {
        searchEnginesManager.shouldShowSearchSuggestions = false
        let subject = createSubject()
        subject.searchEnginesManager = searchEnginesManager
        let quickSearchEngines = subject.quickSearchEngines

        let expectedEngineNames = ["ATester", "BTester", "CTester", "DTester", "ETester", "FTester"]

        XCTAssertEqual(quickSearchEngines.first?.shortName, "ATester")
        XCTAssertEqual(subject.searchEnginesManager?.defaultEngine?.shortName, "ATester")
        XCTAssertEqual(quickSearchEngines.map { $0.shortName }, expectedEngineNames)
        XCTAssertEqual(quickSearchEngines.count, 6)
    }

    // MARK: Trending Searches
    func test_retrieveTrendingSearches_withSuccess_hasExpectedList() async {
        let mockClient = MockTrendingSearchClient(result: .success(["foo", "bar"]))
        let subject = createSubject(mockTrendingClient: mockClient)
        await subject.retrieveTrendingSearches()
        XCTAssertEqual(subject.trendingSearches, ["foo", "bar"])
    }

    func test_retrieveTrendingSearches_withError_hasEmptyList() async {
        enum TestError: Error { case example }
        let mockClient = MockTrendingSearchClient(result: .failure(TestError.example))
        let subject = createSubject(mockTrendingClient: mockClient)
        await subject.retrieveTrendingSearches()
        XCTAssertEqual(subject.trendingSearches, [])
    }

    private func createSubject(
        isPrivate: Bool = false,
        isBottomSearchBar: Bool = false,
        mockTrendingClient: TrendingSearchClientProvider = MockTrendingSearchClient(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SearchViewModel {
        let subject = SearchViewModel(
            isPrivate: isPrivate,
            isBottomSearchBar: isBottomSearchBar,
            profile: profile,
            model: searchEnginesManager,
            tabManager: MockTabManager(),
            trendingSearchClient: mockTrendingClient
        )
        subject.delegate = mockDelegate
        return subject
    }
}

class MockSearchDelegate: SearchViewDelegate {
    var searchData = Cursor<Site>()
    var didReloadTableViewCount = 0
    var didReloadSearchEngines = 0

    func reloadSearchEngines() {
        didReloadSearchEngines += 1
    }
    func reloadTableView() {
        didReloadTableViewCount += 1
    }
}
