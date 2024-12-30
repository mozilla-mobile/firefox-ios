// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Storage

@testable import Client

final class TopSitesManagerTests: XCTestCase {
    private var profile: MockProfile?
    override func setUp() {
        super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        profile = nil
        super.tearDown()
    }

    // MARK: Google Top Site
    func test_recalculateTopSites_shouldShowGoogle_returnGoogleTopSite() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())
        let topSites = await subject.recalculateTopSites(otherSites: [], sponsoredSites: [])

        XCTAssertEqual(topSites.count, 1)
        XCTAssertEqual(topSites.first?.isPinned, true)
        XCTAssertEqual(topSites.first?.isGoogleURL, true)
        XCTAssertEqual(topSites.first?.title, "Google Test")
    }

    func test_recalculateTopSites_noGoogleSiteData_returnNoGoogleTopSite() async throws {
        let subject = try createSubject()
        let topSites = await subject.recalculateTopSites(otherSites: [], sponsoredSites: [])

        XCTAssertEqual(topSites.count, 0)
        XCTAssertNil(topSites.first)
    }

    func test_recalculateTopSites_withOtherSitesAndShouldShowGoogle_returnGoogleTopSite() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())
        let topSites = await subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 10)
        XCTAssertEqual(topSites.first?.isPinned, true)
        XCTAssertEqual(topSites.first?.isGoogleURL, true)
        XCTAssertEqual(topSites.first?.title, "Google Test")
    }

     func test_recalculateTopSites_withOtherSitesAndNoGoogleSite_returnNoGoogleTopSite() async throws {
         let subject = try createSubject()
         let topSites = await subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
         )

         XCTAssertEqual(topSites.count, 10)
         XCTAssertEqual(topSites.first?.isPinned, false)
         XCTAssertEqual(topSites.first?.isGoogleURL, false)
         XCTAssertEqual(topSites.first?.isSponsoredTile, true)
         XCTAssertEqual(topSites.first?.title, "Sponsored Tile 0")
     }

    // MARK: Sponsored Top Site
    func test_fetchSponsoredSites_withSuccessData_returnSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: false)
        let subject = try createSubject(
            contileProvider: MockSponsoredProvider(
                result: .success(MockSponsoredProvider.defaultSuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = ["Firefox Sponsored Tile", "Mozilla Sponsored Tile", "Focus Sponsored Tile"]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
    }

    func test_fetchSponsoredSites_withEmptySuccess_returnSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: false)
        let subject = try createSubject(
            contileProvider: MockSponsoredProvider(
                result: .success(MockSponsoredProvider.emptySuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_fetchSponsoredSites_withFailure_returnNoSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: false)
        let subject = try createSubject(
            contileProvider: MockSponsoredProvider(
                result: .failure(MockSponsoredProvider.MockError.testError)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_fetchSponsoredSites_forUnifiedAds_withSuccessData_returnSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: true)
        let subject = try createSubject(
            unifiedAdsProvider: MockSponsoredProvider(
                result: .success(MockSponsoredProvider.defaultSuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = ["Firefox Sponsored Tile", "Mozilla Sponsored Tile", "Focus Sponsored Tile"]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
    }

    func test_fetchSponsoredSites_forUnifiedAds_withEmptySuccess_returnSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: true)
        let subject = try createSubject(
            unifiedAdsProvider: MockSponsoredProvider(
                result: .success(MockSponsoredProvider.emptySuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_fetchSponsoredSites_forUnifiedAds_withFailure_returnNoSponsoredSites() async throws {
        setupNimbusUnifiedAdsTesting(isEnabled: true)
        let subject = try createSubject(
            unifiedAdsProvider: MockSponsoredProvider(
                result: .failure(MockSponsoredProvider.MockError.testError)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_recalculateTopSites_shouldShowSponsoredTiles_returnOnlyMaxSponsoredSites() async throws {
        // Max contiles is currently at 2, so it should add 2 contiles only.
        let subject = try createSubject()
        let topSites = await subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 10)
        let expectedSponsoredTiles = [true, true, false, false, false, false, false, false, false, false]
        let expectedTitles = [
            "Sponsored Tile 0",
            "Sponsored Tile 1",
            "Other Sites: Title 0",
            "Other Sites: Title 1",
            "Other Sites: Title 2",
            "Other Sites: Title 3",
            "Other Sites: Title 4",
            "Other Sites: Title 5",
            "Other Sites: Title 6",
            "Other Sites: Title 7"
        ]
        XCTAssertEqual(topSites.compactMap { $0.isSponsoredTile }, expectedSponsoredTiles)
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
    }

    func test_recalculateTopSites_shouldNotShowSponsoredTiles_returnNoSponsoredSites() async throws {
        profile?.prefs.setBool(false, forKey: PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts)

        let subject = try createSubject()

        let topSites = await subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 0)
    }

    // MARK: History-based Top Site (otherSites)
    func test_getOtherSites_withHistoryBasedTiles_returnExpectedTopSites() async throws {
        let subject = try createSubject(
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: MockTopSiteHistoryManager.defaultSuccessData)
        )

        let topSites = await subject.getOtherSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = ["Pinned Site Test", "Pinned Site 2 Test", "History-Based Tile Test"]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.mozilla.com", "www.firefox.com", "www.example.com"])
    }

    func test_getOtherSites_withEmptyHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject()

        let topSites = await subject.getOtherSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_getOtherSites_withNilHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject(
            topSiteHistoryManager: MockTopSiteHistoryManager(sites: nil)
        )

        let topSites = await subject.getOtherSites()
        XCTAssertEqual(topSites.count, 0)
    }

    // MARK: Tiles space calculation
    func test_recalculateTopSites_maxCountZero_returnNoSites() async throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            maxCount: 0
        )

        let topSites = await subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )
        XCTAssertEqual(topSites.count, 0)
    }

    func test_recalculateTopSites_noAvailableSpace_returnOnlyPinnedSites() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager(), maxCount: 2)

        let topSites = await subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.defaultSuccessData.compactMap { TopSiteState(site: $0) },
            sponsoredSites: createSponsoredSites()
        )
        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isPinned)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Pinned Site Test", "Pinned Site 2 Test"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.mozilla.com", "www.firefox.com"])
    }

    func test_recalculateTopSites_duplicatePinnedTile_doesNotShowDuplicateSponsoredTile() async throws {
        let subject = try createSubject()

        let topSites = await subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.duplicateTile.compactMap { TopSiteState(site: $0) },
            sponsoredSites: MockSponsoredProvider.defaultSuccessData.compactMap { SponsoredTile(contile: $0) }
        )

        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isSponsoredTile)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Mozilla Sponsored Tile", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://mozilla.com", "https://firefox.com"])
    }

    func test_recalculateTopSites_andNoPinnedSites_returnGoogleAndSponsoredSites() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager(), maxCount: 2)
        let topSites = await subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.noPinnedData.compactMap { TopSiteState(site: $0) },
            sponsoredSites: MockSponsoredProvider.defaultSuccessData.compactMap { SponsoredTile(contile: $0) }
        )

        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isGoogleURL)
        XCTAssertTrue(topSites[1].isSponsoredTile)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://firefox.com"])
    }

    func test_recalculateTopSites_availableSpace_returnSitesInOrder() async throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())

        let topSites = await subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.defaultSuccessData.compactMap { TopSiteState(site: $0) },
            sponsoredSites: MockSponsoredProvider.defaultSuccessData.compactMap { SponsoredTile(contile: $0) }
        )
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

    func test_recalculateTopSites_matchingSponsoredAndHistoryBasedTiles_removeDuplicates() async throws {
        let subject = try createSubject()

        let topSites = await subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.noPinnedData.compactMap { TopSiteState(site: $0) },
            sponsoredSites: MockSponsoredProvider.defaultSuccessData.compactMap { SponsoredTile(contile: $0) }
        )
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
            searchEngineManager: MockSearchEnginesManager(searchEngines: [searchEngine])
        )

        let topSites = await subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: MockSponsoredProvider.defaultSuccessData.compactMap { SponsoredTile(contile: $0) }
        )

        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Mozilla Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://mozilla.com"])
    }

    private func createSubject(
        googleTopSiteManager: GoogleTopSiteManagerProvider = MockGoogleTopSiteManager(mockSiteData: nil),
        contileProvider: ContileProviderInterface = MockSponsoredProvider(
            result: .success(MockSponsoredProvider.emptySuccessData)
        ),
        unifiedAdsProvider: UnifiedAdsProviderInterface = MockSponsoredProvider(
            result: .success(MockSponsoredProvider.emptySuccessData)
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
            unifiedAdsProvider: unifiedAdsProvider,
            googleTopSiteManager: googleTopSiteManager,
            topSiteHistoryManager: topSiteHistoryManager,
            searchEnginesManager: searchEngineManager,
            maxTopSites: maxCount
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createOtherSites(count: Int = 10) -> [TopSiteState] {
        var sites = [TopSiteState]()
        (0..<count).forEach {
            let site = Site(url: "www.url\($0).com",
                            title: "Other Sites: Title \($0)")
            sites.append(TopSiteState(site: site))
        }
        return sites
    }

    private func createSponsoredSites(count: Int = 10) -> [SponsoredTile] {
        var tiles = [SponsoredTile]()
        (0..<count).forEach {
            let tile = Contile(id: $0,
                               name: "Sponsored Tile \($0)",
                               url: "www.url\($0).com",
                               clickUrl: "www.url\($0).com/click",
                               imageUrl: "www.url\($0).com/image1.jpg",
                               imageSize: 200,
                               impressionUrl: "www.url\($0).com",
                               position: $0)
            tiles.append(SponsoredTile(contile: tile))
        }
        return tiles
    }

    private func setupNimbusUnifiedAdsTesting(isEnabled: Bool) {
        FxNimbus.shared.features.unifiedAds.with { _, _ in
            return UnifiedAds(enabled: isEnabled)
        }
    }
}
