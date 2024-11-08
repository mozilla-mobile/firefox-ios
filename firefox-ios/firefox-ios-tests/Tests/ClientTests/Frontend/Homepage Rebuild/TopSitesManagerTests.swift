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
    func test_getTopSites_shouldShowSponsoredTiles_returnExpectedTopSites() async throws {
        let subject = try createSubject(
            contileProvider: MockContileProvider(
                result: .success(MockContileProvider.defaultSuccessData)
            )
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 3)
        XCTAssertEqual(topSites.compactMap { $0.isSponsoredTile }, [true, true, true])
        XCTAssertEqual(topSites.compactMap { $0.title }, ["Firefox", "Mozilla", "Focus"])
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
        let subject = try createSubject(topSiteHistoryManager: MockTopSiteHistoryManager())

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 1)
        XCTAssertEqual(topSites.compactMap { $0.title }, ["History-Based Tile Test"])
        XCTAssertEqual(topSites.compactMap { $0.site.url }, ["www.example.com"])
    }

    func test_getTopSites_withEmptyHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject()

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    func test_getTopSites_withNilHistoryBasedTiles_returnNoTopSites() async throws {
        let subject = try createSubject(
            topSiteHistoryManager: MockTopSiteHistoryManager(historyBasedSites: nil)
        )

        let topSites = await subject.getTopSites()
        XCTAssertEqual(topSites.count, 0)
    }

    private func createSubject(
        googleTopSiteManager: GoogleTopSiteManagerProvider = MockGoogleTopSiteManager(mockSiteData: nil),
        contileProvider: ContileProviderInterface = MockContileProvider(
            result: .success(MockContileProvider.emptySuccessData)
        ),
        topSiteHistoryManager: TopSiteHistoryManagerProvider = MockTopSiteHistoryManager(historyBasedSites: []),
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> TopSitesManager {
        let mockProfile = try XCTUnwrap(profile)
        let subject = TopSitesManager(
            prefs: mockProfile.prefs,
            contileProvider: contileProvider,
            googleTopSiteManager: googleTopSiteManager,
            topSiteHistoryManager: topSiteHistoryManager
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
