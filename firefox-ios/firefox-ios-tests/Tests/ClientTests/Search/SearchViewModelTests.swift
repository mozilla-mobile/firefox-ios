// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest

@testable import Client

@MainActor
final class SearchViewModelTests: XCTestCase {
    var profile: MockProfile!
    var mockDelegate: MockSearchDelegate!
    var searchEnginesManager: SearchEnginesManager!
    var remoteClient: RemoteClient!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile(firefoxSuggest: MockRustFirefoxSuggest())
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)

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

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        mockDelegate = nil
        try await super.tearDown()
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

    func test_hasFirefoxSuggestions_whenFirefoxSuggestionsExist_andSearchTermIsNotEmpty_shouldShowIsTrue() {
        let subject = createSubject()
        subject.searchQuery = "searchTerm"
        subject.firefoxSuggestions = [
            RustFirefoxSuggestion(title: "Test", url: URL(string: "https://google.com")!, isSponsored: true, iconImage: nil)
        ]
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        XCTAssertTrue(subject.hasFirefoxSuggestions)
    }

    func testHasFirefoxSuggestions_whenFirefoxSuggestionsExist_andSearchTermIsEmpty_shouldShowIsTrue() {
        let subject = createSubject()
        subject.searchQuery = ""
        subject.firefoxSuggestions = [
            RustFirefoxSuggestion(title: "Test", url: URL(string: "https://google.com")!, isSponsored: true, iconImage: nil)
        ]
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        XCTAssertFalse(subject.hasFirefoxSuggestions)
    }

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
        let subject = createSubject()
        subject.remoteClientTabs = [ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab1),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab2),
                                                 ClientTabsSearchWrapper(client: remoteClient, tab: remoteTab3)]
        subject.searchRemoteTabs(for: "Mozilla")
        XCTAssertEqual(subject.filteredRemoteClientTabs.count, 3)
    }

    func testSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()
        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredAndSponsoredSuggestionsInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredAndSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = false
        await subject.loadFirefoxSuggestions()

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

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

    func test_historySites_excludesBookmarkedSites() {
        let subject = createSubject()
        XCTAssertEqual(subject.delegate?.searchData.count, 0)
        let data = ArrayCursor<Site>(data: [
            Site.createBasicSite(url: "https://example.com?mfadid=adm", title: "Test1", isBookmarked: true),
            Site.createBasicSite(url: "https://example.com", title: "Test2", isBookmarked: true),
            Site.createBasicSite(url: "https://example.com?a=b&c=d", title: "Test3", isBookmarked: false)
        ])

        subject.loader(dataLoaded: data)
        XCTAssertEqual(subject.historySites.count, 1)
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
    func test_shouldShowHeader_forTrendingSearches_withFFOn_andSearchTerm_doesNotShowHeader() async {
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        let subject = createSubject()
        subject.searchQuery = "hello"
        let trendingSearchesSectionIndex = 1
        let shouldShowHeader = subject.shouldShowHeader(for: trendingSearchesSectionIndex)
        XCTAssertFalse(shouldShowHeader)
    }

    func test_shouldShowHeader_withTrendingSearches_withFFOn_andSearchTermEmpty_showsHeader() {
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        let expectation = XCTestExpectation(description: "reload table view called")
        let mockClient = MockTrendingSearchClient(result: .success(["foo", "bar"]))
        mockDelegate.didReloadTableViewCalled = {
            expectation.fulfill()
        }
        let subject = createSubject(mockTrendingClient: mockClient)
        subject.loadTrendingSearches()

        wait(for: [expectation], timeout: 1)

        let trendingSearchesSectionIndex = 1
        let shouldShowHeader = subject.shouldShowHeader(for: trendingSearchesSectionIndex)

        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
        XCTAssertEqual(subject.trendingSearches, ["foo", "bar"])
        XCTAssertTrue(shouldShowHeader)
    }

    func test_shouldShowHeader_withNoTrendingSearches_withFFOn_andSearchTermEmpty_doesNotShowHeader() async {
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        let subject = createSubject()
        subject.searchQuery = ""
        let trendingSearchesSectionIndex = 1
        let shouldShowHeader = subject.shouldShowHeader(for: trendingSearchesSectionIndex)
        XCTAssertEqual(subject.trendingSearches, [])
        XCTAssertFalse(shouldShowHeader)
    }

    func test_shouldShowHeader_forTrendingSearches_withoutFeatureFlagOn_doesNotShowHeader() {
        setupNimbusTrendingSearchesTesting(isEnabled: false)
        let subject = createSubject()
        let trendingSearchesSectionIndex = 1
        let shouldShowHeader = subject.shouldShowHeader(for: trendingSearchesSectionIndex)
        XCTAssertEqual(subject.trendingSearches, [])
        XCTAssertFalse(shouldShowHeader)
    }

    func test_retrieveTrendingSearches_withSuccess_hasExpectedList() {
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        let expectation = XCTestExpectation(description: "reload table view called")
        let mockClient = MockTrendingSearchClient(result: .success(["foo", "bar"]))
        mockDelegate.didReloadTableViewCalled = {
            expectation.fulfill()
        }
        let subject = createSubject(mockTrendingClient: mockClient)

        subject.loadTrendingSearches()

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
        XCTAssertEqual(subject.trendingSearches, ["foo", "bar"])
    }

    func test_retrieveTrendingSearches_withError_hasEmptyList() {
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        enum TestError: Error { case example }
        let mockClient = MockTrendingSearchClient(result: .failure(TestError.example))
        let subject = createSubject(mockTrendingClient: mockClient)
        subject.loadTrendingSearches()
        XCTAssertEqual(subject.trendingSearches, [])
    }

    func test_retrieveTrendingSearches_withoutFFEnabled_hasEmptyList() {
        setupNimbusTrendingSearchesTesting(isEnabled: false)
        let mockClient = MockTrendingSearchClient(result: .success(["foo", "bar"]))
        let subject = createSubject(mockTrendingClient: mockClient)
        subject.loadTrendingSearches()
        XCTAssertEqual(subject.trendingSearches, [])
    }

    // MARK: - Recent Searches
    func test_shouldShowHeader_forRecentSearches_withFFOn_andSearchTerm_doesNotShowHeader() async {
        setupNimbusRecentSearchesTesting(isEnabled: true)
        let subject = createSubject()
        subject.searchQuery = "hello"
        let recentSearchesSectionIndex = 0
        let shouldShowHeader = subject.shouldShowHeader(for: recentSearchesSectionIndex)
        XCTAssertFalse(shouldShowHeader)
    }

    func test_shouldShowHeader_withRecentSearches_withFFOn_andSearchTermEmpty_showsHeader() async {
        setupNimbusRecentSearchesTesting(isEnabled: true)
        let mockRecentSearchProvider = MockRecentSearchProvider()
        let subject = createSubject(mockRecentSearchProvider: mockRecentSearchProvider)
        subject.retrieveRecentSearches()
        subject.searchQuery = ""
        let recentSearchesSectionIndex = 0
        let expectation = XCTestExpectation(description: "Recent Searches have been fetched")

        let shouldShowHeader = subject.shouldShowHeader(for: recentSearchesSectionIndex)

        mockRecentSearchProvider.loadRecentSearches { result in
            XCTAssertEqual(result, ["search term 1", "search term 2"])
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(shouldShowHeader)
    }

    func test_shouldShowHeader_withNoRecentSearches_withFFOn_andSearchTermEmpty_doesNotShowHeader() async {
        setupNimbusRecentSearchesTesting(isEnabled: true)
        let subject = createSubject()
        subject.searchQuery = ""
        let recentSearchesSectionIndex = 0
        let shouldShowHeader = subject.shouldShowHeader(for: recentSearchesSectionIndex)
        XCTAssertEqual(subject.recentSearches, [])
        XCTAssertFalse(shouldShowHeader)
    }

    func test_shouldShowHeader_forRecentSearches_withoutFeatureFlagOn_doesNotShowHeader() async {
        setupNimbusRecentSearchesTesting(isEnabled: false)
        let subject = createSubject()
        let recentSearchesSectionIndex = 0
        let shouldShowHeader = subject.shouldShowHeader(for: recentSearchesSectionIndex)
        XCTAssertEqual(subject.recentSearches, [])
        XCTAssertFalse(shouldShowHeader)
    }

    func test_retrieveRecentSearches_withSuccess_hasExpectedList() {
        setupNimbusRecentSearchesTesting(isEnabled: true)
        let mockRecentSearchProvider = MockRecentSearchProvider()
        let subject = createSubject(mockRecentSearchProvider: mockRecentSearchProvider)

        let expectation = XCTestExpectation(description: "Recent Searches have been fetched")

        subject.retrieveRecentSearches()

        mockRecentSearchProvider.loadRecentSearches { result in
            XCTAssertEqual(result, ["search term 1", "search term 2"])
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_retrieveRecentSearches_withoutFFEnabled_hasEmptyList() {
        setupNimbusRecentSearchesTesting(isEnabled: false)
        let mockRecentSearchProvider = MockRecentSearchProvider()
        let subject = createSubject(mockRecentSearchProvider: mockRecentSearchProvider)
        subject.retrieveRecentSearches()
        XCTAssertEqual(subject.recentSearches, [])
    }

    func test_clearRecentSearches_withFFEnabled_clearsSuccessfully() {
        let mockRecentSearchProvider = MockRecentSearchProvider()
        let subject = createSubject(mockRecentSearchProvider: mockRecentSearchProvider)
        subject.clearRecentSearches()
        XCTAssertEqual(mockRecentSearchProvider.clearRecentSearchCalledCount, 1)
    }

    func test_updateBottomSearchBarState_setsValueCorrectly() {
        let subject = createSubject()
        subject.updateBottomSearchBarState(isBottomSearchBar: true)
        XCTAssertTrue(subject.isBottomSearchBar)
    }

    // MARK: Search suggestions

    func test_querySuggestClient_whenStaleResponseArrives_discardsIt() async throws {
        // Firefox Suggest off, so the `Task` spawned by `querySuggestClient()` fails its guard without
        // awaiting a query, which would otherwise fire extra, non-deterministically timed reloads.
        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let mockSuggestClient = MockSearchSuggestClient()
        let subject = createSubject(mockSuggestClient: mockSuggestClient)
        // Required: `shouldShowSearchEngineSuggestions` reads `shouldShowSearchSuggestions` from the
        // manager. Assigning it also fires one empty-query pass that reloads the table.
        subject.searchEnginesManager = searchEnginesManager
        mockDelegate.didReloadTableViewCount = 0

        subject.searchQuery = "hello"
        let staleCallback = try XCTUnwrap(mockSuggestClient.lastCallback)
        subject.searchQuery = "hello world"
        XCTAssertEqual(mockSuggestClient.lastQuery, "hello world")
        // Let the spawned Firefox Suggest tasks finish before `tearDown` resets `AppContainer`.
        await Task.yield()

        staleCallback(["hello stale"], nil)

        XCTAssertEqual(subject.suggestions, [])
        XCTAssertEqual(subject.savedQuery, "")
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
        // Cancellation alone cannot stop an in-flight completion handler, which is why the guard is needed.
        XCTAssertEqual(mockSuggestClient.cancelPendingRequestCalledCount, 2)
    }

    func test_querySuggestClient_whenCurrentResponseArrives_appliesIt() async throws {
        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let mockSuggestClient = MockSearchSuggestClient()
        let subject = createSubject(mockSuggestClient: mockSuggestClient)
        subject.searchEnginesManager = searchEnginesManager
        mockDelegate.didReloadTableViewCount = 0

        subject.searchQuery = "hello"
        XCTAssertEqual(mockSuggestClient.lastQuery, "hello")
        let callback = try XCTUnwrap(mockSuggestClient.lastCallback)
        await Task.yield()

        callback(["hello", "hello world"], nil)

        // The response's own copy of the typed query is removed, then the typed query is re-inserted at index 0.
        XCTAssertEqual(subject.suggestions, ["hello", "hello world"])
        XCTAssertEqual(subject.suggestions?.filter { $0 == "hello" }.count, 1)
        XCTAssertEqual(subject.savedQuery, "hello")
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
        XCTAssertEqual(mockSuggestClient.cancelPendingRequestCalledCount, 1)
    }

    func test_querySuggestClient_whenStaleResponseArrivesAfterCurrentOne_keepsCurrentResults() async throws {
        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let mockSuggestClient = MockSearchSuggestClient()
        let subject = createSubject(mockSuggestClient: mockSuggestClient)
        subject.searchEnginesManager = searchEnginesManager
        mockDelegate.didReloadTableViewCount = 0

        subject.searchQuery = "hello"
        let staleCallback = try XCTUnwrap(mockSuggestClient.lastCallback)
        subject.searchQuery = "hello world"
        let currentCallback = try XCTUnwrap(mockSuggestClient.lastCallback)
        await Task.yield()

        // The current query's response lands first and is applied.
        currentCallback(["hello world news"], nil)
        XCTAssertEqual(subject.suggestions, ["hello world", "hello world news"])
        XCTAssertEqual(subject.savedQuery, "hello world")
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)

        // The older query's response arrives late and must not clobber what is already on screen.
        staleCallback(["hello stale"], nil)

        XCTAssertEqual(subject.suggestions, ["hello world", "hello world news"])
        XCTAssertFalse(subject.suggestions?.contains("hello stale") ?? true)
        XCTAssertEqual(subject.savedQuery, "hello world")
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    private func createSubject(
        isPrivate: Bool = false,
        isBottomSearchBar: Bool = false,
        mockTrendingClient: TrendingSearchClientProvider = MockTrendingSearchClient(),
        mockRecentSearchProvider: RecentSearchProvider = MockRecentSearchProvider(),
        mockSuggestClient: SearchSuggestClientProvider? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SearchViewModel {
        let subject = SearchViewModel(
            isPrivate: isPrivate,
            isBottomSearchBar: isBottomSearchBar,
            profile: profile,
            model: searchEnginesManager,
            tabManager: MockTabManager(),
            trendingSearchClient: mockTrendingClient,
            recentSearchProvider: mockRecentSearchProvider,
            suggestClient: mockSuggestClient
        )
        subject.delegate = mockDelegate
        return subject
    }

    private func setupNimbusTrendingSearchesTesting(isEnabled: Bool) {
        FxNimbus.shared.features.trendingSearchesFeature.with { _, _ in
            return TrendingSearchesFeature(
                enabled: isEnabled
            )
        }
    }

    private func setupNimbusRecentSearchesTesting(isEnabled: Bool) {
        FxNimbus.shared.features.recentSearchesFeature.with { _, _ in
            return RecentSearchesFeature(
                enabled: isEnabled
            )
        }
    }
}

final class MockSearchDelegate: SearchViewDelegate {
    var searchData = Cursor<Site>()
    var didReloadTableViewCount = 0
    var didReloadSearchEngines = 0
    var didReloadTableViewCalled: (() -> Void)?

    func reloadSearchEngines() {
        didReloadSearchEngines += 1
    }
    func reloadTableView() {
        didReloadTableViewCalled?()
        didReloadTableViewCount += 1
    }
}

/// Holds the most recent request instead of completing it, so a test can fire an older callback after a
/// newer query has already been issued.
final class MockSearchSuggestClient: SearchSuggestClientProvider, @unchecked Sendable {
    typealias QueryCallback = @Sendable (_ response: [String]?, _ error: NSError?) -> Void

    private(set) var lastQuery: String?
    private(set) var lastCallback: QueryCallback?
    private(set) var cancelPendingRequestCalledCount = 0

    func query(_ query: String, callback: @escaping QueryCallback) {
        lastQuery = query
        lastCallback = callback
    }

    /// Deliberately does not drop the pending callback: cancelling a `URLSessionTask` that is already completing
    /// does not stop its completion handler, which is the race the view model has to defend against.
    func cancelPendingRequest() {
        cancelPendingRequestCalledCount += 1
    }
}
