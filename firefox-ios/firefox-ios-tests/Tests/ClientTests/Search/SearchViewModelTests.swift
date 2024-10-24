// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
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
        super.tearDown()
        profile = nil
    }

    func testFirefoxSuggestionReturnsNoSuggestions() async throws {
        FxNimbus.shared.features.firefoxSuggestFeature.with(initializer: { _, _ in
            FirefoxSuggestFeature(availableSuggestionsTypes:
                                    [.amp: false, .ampMobile: false, .wikipedia: false])
       })

        searchEnginesManager.shouldShowFirefoxSuggestions = false
        searchEnginesManager.shouldShowSponsoredSuggestions = false

        let subject = createSubject()
        await subject.loadFirefoxSuggestions()?.value
        XCTAssertEqual(subject.firefoxSuggestions.count, 0)

        // Providers set to false, so regardless of the prefs, we shouldn't see anything
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        await subject.loadFirefoxSuggestions()?.value
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

        await subject.loadFirefoxSuggestions()?.value
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
        await subject.loadFirefoxSuggestions()?.value

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

    func testSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()?.value
        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true

        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredAndSponsoredSuggestionsInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = true
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredInPrivateModeWithPrivateSuggestionsOn() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)
        searchEnginesManager.shouldShowFirefoxSuggestions = true
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = true
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertTrue(subject.firefoxSuggestions.isEmpty)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 0)
    }

    func testNonSponsoredAndSponsoredSuggestionsAreNotShownInPrivateBrowsingMode() async throws {
        let subject = createSubject(isPrivate: true, isBottomSearchBar: false)

        searchEnginesManager.shouldShowPrivateModeFirefoxSuggestions = false
        await subject.loadFirefoxSuggestions()?.value

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
        await subject.loadFirefoxSuggestions()?.value
        await subject.loadFirefoxSuggestions()?.value

        XCTAssertEqual(subject.firefoxSuggestions.count, 2)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    func testLoad_forHistoryAndBookmarks_doesNotTriggerReloadForSameSuggestions() async throws {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let subject = createSubject()
        XCTAssertEqual(subject.delegate?.searchData.count, 0)
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])
        subject.loader(dataLoaded: data)
        XCTAssertEqual(subject.delegate?.searchData.count, 3)
        XCTAssertEqual(mockDelegate.didReloadTableViewCount, 1)
    }

    func testLoad_multipleTimes_doesNotTriggerReloadForSameSuggestions() async throws {
        searchEnginesManager.shouldShowSponsoredSuggestions = false
        let subject = createSubject()
        let data = ArrayCursor<Site>(data: [ Site(url: "https://example.com?mfadid=adm", title: "Test1"),
                                             Site(url: "https://example.com", title: "Test2"),
                                             Site(url: "https://example.com?a=b&c=d", title: "Test3")])
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
        await subject.loadFirefoxSuggestions()?.value

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
        await subject.loadFirefoxSuggestions()?.value

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

    private func createSubject(
        isPrivate: Bool = false,
        isBottomSearchBar: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) -> SearchViewModel {
        let subject = SearchViewModel(
            isPrivate: isPrivate,
            isBottomSearchBar: isBottomSearchBar,
            profile: profile,
            model: searchEnginesManager,
            tabManager: MockTabManager()
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
