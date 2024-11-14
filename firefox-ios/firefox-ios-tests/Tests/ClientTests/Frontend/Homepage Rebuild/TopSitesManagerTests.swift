// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

final class TopSitesManagerTests: XCTestCase {
    private var profile: MockProfile?
    override func setUp() {
        super.setUp()
        profile = MockProfile()
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: Google Top Site
    func test_getTopSites_shouldShowGoogle_returnGoogleTopSite() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())
        let topSites = await subject.getTopSites()

        XCTAssertEqual(topSites.count, 1)
        XCTAssertEqual(topSites.first?.isPinned, true)
        XCTAssertEqual(topSites.first?.isGoogleURL, true)
        XCTAssertEqual(topSites.first?.title, "Google Test")
    }

    func test_getTopSites_noGoogleSiteData_returnNoGoogleTopSite() async throws {
        let subject = try createSubject()
        let topSites = await subject.getTopSites()

        XCTAssertEqual(topSites.count, 0)
        XCTAssertNil(topSites.first)
    }

    // MARK: Sponsored Top Site
    func test_getTopSites_shouldShowSponsoredTiles_returnOnlyMaxSponsoredSites() async throws {
        // Max contiles is currently at 2, so it should add 2 contiles only.
        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            )
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 2)
        XCTAssertEqual(topSites.compactMap { $0.isSponsoredTile }, [true, true])
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Firefox Sponsored Tile", "Mozilla Sponsored Tile"])
    }

    func test_getTopSites_shouldNotShowSponsoredTiles_returnNoSponsoredSites() async throws {
        profile?.prefs.setBool(false, forKey: PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts)

        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            )
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_getTopSites_failToGetSponsoredTiles_returnNoSponsoredSites() async throws {
        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .failure(MockContileProvider.MockError.testError)
            )
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    // MARK: History-based Top Site
    func test_getTopSites_withHistoryBasedTiles_returnExpectedTopSites() async throws {
        let subject = try createSubject(
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.defaultSuccessData)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = ["Pinned Site Test", "Pinned Site 2 Test", "History-Based Tile Test"]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.mozilla.com", "www.firefox.com", "www.example.com"])
    }

    func test_getTopSites_withEmptyHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject()

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_getTopSites_withNilHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject(
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: nil)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    // MARK: Tiles space calculation
    func test_getTopSites_maxCountZero_returnNoSites() async throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.defaultSuccessData),
            maxCount: 0
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_getTopSites_noAvailableSpace_returnOnlyPinnedSites() async throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.defaultSuccessData),
            maxCount: 2
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isPinned)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Pinned Site Test", "Pinned Site 2 Test"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.mozilla.com", "www.firefox.com"])
    }

    func test_getTopSites_duplicatePinnedTile_doesNotShowDuplicateSponsoredTile() async throws {
        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.duplicateTile)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isSponsoredTile)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Mozilla Sponsored Tile", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://mozilla.com", "https://firefox.com"])
    }

    func test_getTopSites_andNoPinnedSites_returnGoogleAndSponsoredSites() async throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.noPinnedData),
            maxCount: 2
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isGoogleURL)
        XCTAssertTrue(topSites[1].isSponsoredTile)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://firefox.com"])
    }

    func test_getTopSites_availableSpace_returnSitesInOrder() async throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.defaultSuccessData)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 6)
        let expectedTitles = [
            "Google Test",
            "Firefox Sponsored Tile",
            "Mozilla Sponsored Tile",
            "Pinned Site Test",
            "Pinned Site 2 Test",
            "History-Based Tile Test"
        ]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
        let expectedURLs = [
            "https://www.google.com/webhp?client=firefox-b-1-m&channel=ts",
            "https://firefox.com",
            "https://mozilla.com",
            "www.mozilla.com",
            "www.firefox.com",
            "www.example.com"
        ]
        XCTAssertEqual(topSites.compactMap { $0.site.url }, expectedURLs)
    }

    func test_getTopSites_matchingSponsoredAndHistoryBasedTiles_removeDuplicates() async throws {
        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.noPinnedData)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = [
            "Firefox Sponsored Tile",
            "Mozilla Sponsored Tile",
            "History-Based Tile 2 Test"
        ]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
        let expectedURLs = [
            "https://firefox.com",
            "https://mozilla.com",
            "www.example.com"
        ]
        XCTAssertEqual(topSites.compactMap { $0.site.url }, expectedURLs)
    }

    // MARK: - Search engine
    func test_searchEngine_sponsoredTile_getsRemoved() async throws {
        let searchEngine = OpenSearchEngine(engineID: "Firefox",
                                            shortName: "Firefox",
                                            image: UIImage(),
                                            searchTemplate: "https://firefox.com/find?q={searchTerm}",
                                            suggestTemplate: nil,
                                            isCustomEngine: false)
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            ),
            searchEngineManager: MockSearchEnginesManager(searchEngines: [searchEngine])
        )

        let topSites = await subject.getTopSites()

        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Mozilla Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://mozilla.com"])
    }

    private func createSubject(
        googleTopSiteManager: GoogleTopSiteManagerProvider = MockGoogleTopSiteManager(mockSiteData: nil),
        contileProvider: ContileProviderInterface = MockContileProvider(
            result: .success(MockContileProvider.emptySuccessData)
        ),
        topSiteHistoryManager: TopSiteHistoryManagerProvider = MockTopSiteHistoryManager(sites: []),
        searchEngineManager: SearchEnginesManagerProvider = MockSearchEnginesManager(),
        maxCount: Int = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> TopSitesManager {
        let mockProfile = try XCTUnwrap(profile)
        let subject = TopSitesManager(
            prefs: mockProfile.prefs,
            contileProvider: contileProvider,
            googleTopSiteManager: googleTopSiteManager,
            topSiteHistoryManager: topSiteHistoryManager,
            searchEnginesManager: searchEngineManager,
            maxTopSites: maxCount
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
