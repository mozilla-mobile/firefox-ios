// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Storage
import XCTest
import Common

@testable import Client

@MainActor
final class TopSitesManagerTests: XCTestCase {
    private var profile: MockProfile!
    private var mockNotificationCenter: MockNotificationCenter!
    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        mockNotificationCenter = MockNotificationCenter()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        profile = nil
        mockNotificationCenter = nil
        try await super.tearDown()
    }

    // MARK: Google Top Site
    func test_recalculateTopSites_shouldShowGoogle_returnGoogleTopSite() throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())
        let topSites = subject.recalculateTopSites(otherSites: [], sponsoredSites: [])

        XCTAssertEqual(topSites.count, 1)
        XCTAssertEqual(topSites.first?.isPinned, true)
        XCTAssertEqual(topSites.first?.isGoogleURL, true)
        XCTAssertEqual(topSites.first?.title, "Google Test")
    }

    func test_recalculateTopSites_noGoogleSiteData_returnNoGoogleTopSite() throws {
        let subject = try createSubject()
        let topSites = subject.recalculateTopSites(otherSites: [], sponsoredSites: [])

        XCTAssertEqual(topSites.count, 0)
        XCTAssertNil(topSites.first)
    }

    func test_recalculateTopSites_withOtherSitesAndShouldShowGoogle_returnGoogleTopSite() throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())
        let topSites = subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 10)
        XCTAssertEqual(topSites.first?.isPinned, true)
        XCTAssertEqual(topSites.first?.isGoogleURL, true)
        XCTAssertEqual(topSites.first?.title, "Google Test")
    }

     func test_recalculateTopSites_withOtherSitesAndNoGoogleSite_returnNoGoogleTopSite() throws {
         let subject = try createSubject()
         let topSites = subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
         )

         XCTAssertEqual(topSites.count, 10)
         XCTAssertEqual(topSites.first?.isPinned, false)
         XCTAssertEqual(topSites.first?.isGoogleURL, false)
         XCTAssertEqual(topSites.first?.isSponsored, true)
         XCTAssertEqual(topSites.first?.title, "Sponsored Tile 0")
     }

    // MARK: Sponsored Top Site

    func test_fetchSponsoredSites_forUnifiedAds_withSuccessData_returnSponsoredSites() async throws {
        let subject = try createSubject(
            unifiedAdsProvider: MockUnifiedAdsProvider(
                result: .success(MockSponsoredTileData.defaultSuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 3)
        let expectedTitles = ["Firefox Sponsored Tile", "Mozilla Sponsored Tile", "Focus Sponsored Tile"]
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
    }

    func test_fetchSponsoredSites_forUnifiedAds_withEmptySuccess_returnSponsoredSites() async throws {
        let subject = try createSubject(
            unifiedAdsProvider: MockUnifiedAdsProvider(
                result: .success(MockSponsoredTileData.emptySuccessData)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_fetchSponsoredSites_forUnifiedAds_withFailure_returnNoSponsoredSites() async throws {
        let subject = try createSubject(
            unifiedAdsProvider: MockUnifiedAdsProvider(
                result: .failure(MockSponsoredTileData.MockError.testError)
            )
        )

        let topSites = await subject.fetchSponsoredSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_recalculateTopSites_shouldShowSponsoredSites_returnOnlyMaxSponsoredSites() throws {
        // Max tiles is currently at 2, so it should add 2 tiles only.
        let subject = try createSubject()
        let topSites = subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 10)
        let expectedSponsoredSites = [true, true, false, false, false, false, false, false, false, false]
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
        XCTAssertEqual(topSites.compactMap { $0.isSponsored }, expectedSponsoredSites)
        XCTAssertEqual(topSites.compactMap { $0.title }, expectedTitles)
    }

    func test_recalculateTopSites_shouldNotShowSponsoredSites_returnNoSponsoredSites() throws {
        profile?.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)

        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
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
    func test_recalculateTopSites_maxCountZero_returnNoSites() throws {
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            maxCount: 0
        )

        let topSites = subject.recalculateTopSites(
            otherSites: createOtherSites(),
            sponsoredSites: createSponsoredSites()
        )
        XCTAssertEqual(topSites.count, 0)
    }

    func test_recalculateTopSites_noAvailableSpace_returnOnlyPinnedSites() throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager(), maxCount: 2)

        let topSites = subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.defaultSuccessData.compactMap { TopSiteConfiguration(site: $0) },
            sponsoredSites: createSponsoredSites()
        )
        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isPinned)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Pinned Site Test", "Pinned Site 2 Test"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.mozilla.com", "www.firefox.com"])
    }

    func test_recalculateTopSites_duplicatePinnedTile_doesNotShowDuplicateSponsoredSite() throws {
        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.duplicateTile.compactMap { TopSiteConfiguration(site: $0) },
            sponsoredSites: MockSponsoredTileData.defaultSuccessData.compactMap {
                Site.createSponsoredSite(fromUnifiedTile: $0)
            }
        )

        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isSponsored)
        XCTAssertTrue(topSites[1].isPinned)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Mozilla Sponsored Tile", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://mozilla.com", "https://firefox.com"])
    }

    func test_recalculateTopSites_andNoPinnedSites_returnGoogleAndSponsoredSites() throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager(), maxCount: 2)
        let topSites = subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.noPinnedData.compactMap { TopSiteConfiguration(site: $0) },
            sponsoredSites: MockSponsoredTileData.defaultSuccessData.compactMap {
                Site.createSponsoredSite(fromUnifiedTile: $0)
            }
        )

        XCTAssertEqual(topSites.count, 2)
        XCTAssertTrue(topSites[0].isGoogleURL)
        XCTAssertTrue(topSites[1].isSponsored)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Firefox Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://firefox.com"])
    }

    func test_recalculateTopSites_availableSpace_returnSitesInOrder() throws {
        let subject = try createSubject(googleTopSiteManager: MockGoogleTopSiteManager())

        let topSites = subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.defaultSuccessData.compactMap { TopSiteConfiguration(site: $0) },
            sponsoredSites: MockSponsoredTileData.defaultSuccessData.compactMap {
                Site.createSponsoredSite(fromUnifiedTile: $0)
            }
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

    func test_recalculateTopSites_matchingSponsoredAndHistoryBasedTiles_removeDuplicates() throws {
        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: MockTopSiteHistoryManager.noPinnedData.compactMap { TopSiteConfiguration(site: $0) },
            sponsoredSites: MockSponsoredTileData.defaultSuccessData.compactMap {
                Site.createSponsoredSite(fromUnifiedTile: $0)
            }
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
    func test_searchEngine_sponsoredSite_getsRemoved() throws {
        let searchEngine = OpenSearchEngine(engineID: "Firefox",
                                            shortName: "Firefox",
                                            telemetrySuffix: nil,
                                            image: UIImage(),
                                            searchTemplate: "https://firefox.com/find?q={searchTerm}",
                                            suggestTemplate: nil,
                                            isCustomEngine: false)
        let subject = try createSubject(
            googleTopSiteManager: MockGoogleTopSiteManager(),
            searchEngineManager: MockSearchEnginesManager(searchEngines: [searchEngine])
        )

        let topSites = subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: MockSponsoredTileData.defaultSuccessData.compactMap {
                Site.createSponsoredSite(fromUnifiedTile: $0)
            }
        )

        XCTAssertEqual(topSites.compactMap { $0.title }, ["Google Test", "Mozilla Sponsored Tile"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["https://www.google.com/webhp?client=firefox-b-1-m&channel=ts", "https://mozilla.com"])
    }

    // MARK: Context menu actions
    func test_unpinTopSite_callsProperMethods() async throws {
        let mockGoogleTopSiteManager = MockGoogleTopSiteManager()
        let mockTopSiteHistoryManager = MockTopSiteHistoryManager()
        let subject = try createSubject(
            googleTopSiteManager: mockGoogleTopSiteManager,
            topSiteHistoryManager: mockTopSiteHistoryManager
        )
        let site = Site.createBasicSite(url: "www.example.com", title: "Example Pinned Site")
        let unpinnedSiteExpectation = XCTestExpectation(
            description: "Remove top sites method is called from top site manager"
        )

        mockTopSiteHistoryManager.removePinnedSiteCalled = {
            unpinnedSiteExpectation.fulfill()
        }
        await subject.unpinTopSite(site)

        XCTAssertEqual(mockGoogleTopSiteManager.removeGoogleTopSiteCalledCount, 1)
        await fulfillment(of: [unpinnedSiteExpectation], timeout: 1)
    }

    func test_removeTopSite_callsProperMethods() async throws {
        let mockGoogleTopSiteManager = MockGoogleTopSiteManager()
        let mockTopSiteHistoryManager = MockTopSiteHistoryManager()
        let subject = try createSubject(
            googleTopSiteManager: mockGoogleTopSiteManager,
            topSiteHistoryManager: mockTopSiteHistoryManager
        )
        let site = Site.createBasicSite(url: "www.example.com", title: "Example Pinned Site")
        let removePinnedSiteExpectation = XCTestExpectation(
            description: "Remove top sites method is called from top site manager"
        )

        let postCalledExpectation = XCTestExpectation(
            description: "Notification post method is called from top site manager"
        )

        mockTopSiteHistoryManager.removePinnedSiteCalled = {
            removePinnedSiteExpectation.fulfill()
        }

        mockNotificationCenter.postCalled = { name in
            guard name == .TopSitesUpdated else { return }
            postCalledExpectation.fulfill()
        }

        await subject.removeTopSite(site)

        XCTAssertEqual(mockGoogleTopSiteManager.removeGoogleTopSiteCalledCount, 1)
        XCTAssertEqual(mockTopSiteHistoryManager.removeDefaultTopSitesTileCalledCount, 1)
        await fulfillment(of: [removePinnedSiteExpectation, postCalledExpectation], timeout: 1)
    }

    func test_pinTopSite_callsProperMethods() throws {
        let mockPinnedSites = MockablePinnedSites()
        let profile = MockProfile(injectedPinnedSites: mockPinnedSites)
        let mockTopSiteHistoryManager = MockTopSiteHistoryManager()
        let subject = try createSubject(
            injectedProfile: profile,
            topSiteHistoryManager: mockTopSiteHistoryManager
        )
        let site = Site.createBasicSite(url: "www.example.com", title: "Example Pinned Site")

        subject.pinTopSite(site)

        XCTAssertEqual(mockPinnedSites.addPinnedTopSiteCalledCount, 1)
    }

    func test_sponsoredShortcutsFlagEnabled_withoutUserPref_returnsSponsoredSites() throws {
        setupNimbusHNTSponsoredShortcutsTesting(isEnabled: true)

        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 2)
    }

    func test_sponsoredShorcutsFlagDisabled_withoutUserPref_returnsNoSponsoredSites() throws {
        setupNimbusHNTSponsoredShortcutsTesting(isEnabled: false)

        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 0)
    }

    func test_sponsoredShortcutsFlagEnabled_withUserPref_returnsNoSponsoredSites() throws {
        profile?.prefs.setBool(false, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
        setupNimbusHNTSponsoredShortcutsTesting(isEnabled: true)

        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 0)
    }

    func test_sponsoredShortcutsFlagDisabled_withUserPref_returnsSponsoredSites() throws {
        profile?.prefs.setBool(true, forKey: PrefsKeys.FeatureFlags.SponsoredShortcuts)
        setupNimbusHNTSponsoredShortcutsTesting(isEnabled: false)

        let subject = try createSubject()

        let topSites = subject.recalculateTopSites(
            otherSites: [],
            sponsoredSites: createSponsoredSites()
        )

        XCTAssertEqual(topSites.count, 2)
    }

    private func createSubject(
        injectedProfile: Profile? = nil,
        googleTopSiteManager: GoogleTopSiteManagerProvider = MockGoogleTopSiteManager(mockSiteData: nil),
        unifiedAdsProvider: UnifiedAdsProviderInterface = MockUnifiedAdsProvider(
            result: .success(MockSponsoredTileData.defaultSuccessData)
        ),
        topSiteHistoryManager: TopSiteHistoryManagerProvider = MockTopSiteHistoryManager(sites: []),
        searchEngineManager: SearchEnginesManagerProvider = MockSearchEnginesManager(),
        maxCount: Int = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> TopSitesManager {
        let mockProfile = try XCTUnwrap(injectedProfile ?? profile)
        let mockNotificationCenter = try XCTUnwrap(mockNotificationCenter)
        let subject = TopSitesManager(
            profile: mockProfile,
            unifiedAdsProvider: unifiedAdsProvider,
            googleTopSiteManager: googleTopSiteManager,
            topSiteHistoryManager: topSiteHistoryManager,
            searchEnginesManager: searchEngineManager,
            notification: mockNotificationCenter,
            maxTopSites: maxCount
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createOtherSites(count: Int = 10) -> [TopSiteConfiguration] {
        var sites = [TopSiteConfiguration]()
        (0..<count).forEach {
            let site = Site.createBasicSite(url: "www.url\($0).com",
                                            title: "Other Sites: Title \($0)")
            sites.append(TopSiteConfiguration(site: site))
        }
        return sites
    }

    private func createSponsoredSites(count: Int = 10) -> [Site] {
        var sponsoredSites = [Site]()
        (0..<count).forEach {
            let tile = UnifiedTile(
                format: "",
                url: "www.url\($0).com",
                callbacks: UnifiedTileCallback(
                    click: "www.url\($0).com/click",
                    impression: "www.url\($0).com"
                ),
                imageUrl: "www.url\($0).com/image1.jpg",
                name: "Sponsored Tile \($0)",
                blockKey: "Block_key_1"
            )
            sponsoredSites.append(Site.createSponsoredSite(fromUnifiedTile: tile))
        }
        return sponsoredSites
    }

    private func setupNimbusHNTSponsoredShortcutsTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hntSponsoredShortcutsFeature.with { _, _ in
            return HntSponsoredShortcutsFeature(
                enabled: isEnabled
            )
        }
    }
}
