// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

final class CuratedRecommendationCacheUtilityTests: XCTestCase {
    var cache: CuratedRecommendationCacheUtility!
    var testFileURL: URL!

    override func setUp() {
        super.setUp()

        // Create unique test file in temporary directory
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test_curated_recommendations_cache.json")

        // Inject cache with overridden file path (via subclassing or init)
        cache = CuratedRecommendationCacheUtility(withCustomCacheURL: testFileURL)
        cache.clearCache()
    }

    override func tearDown() {
        cache.clearCache()
        try? FileManager.default.removeItem(at: testFileURL)
        super.tearDown()
    }

    func testSaveAndLoadRecommendations() {
        let recs = generateFakeDataWith(numberOfItems: 2)

        cache.save(recs)

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?.first?.title, "Title 1")
    }

    func testLastUpdatedIsSet() {
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)

        let lastUpdated = cache.lastUpdatedDate()
        XCTAssertNotNil(lastUpdated)
        XCTAssert(abs(lastUpdated!.timeIntervalSinceNow) < 2, "Last updated is too old")
    }

    func testOverwriteCache() {
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)

        let new_recs = generateFakeDataWith(numberOfItems: 2)
        cache.save(new_recs)

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?.last?.title, "Title 2")
    }

    func testClearCache() {
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)
        cache.clearCache()

        XCTAssertNil(cache.loadRecommendations())
        XCTAssertNil(cache.lastUpdatedDate())
    }

    func testLoadFromEmptyReturnsNil() {
        XCTAssertNil(cache.loadRecommendations())
        XCTAssertNil(cache.lastUpdatedDate())
    }

    private func generateFakeDataWith(numberOfItems: Int) -> [RecommendationDataItem] {
        var data = [RecommendationDataItem]()
        for index in 1...numberOfItems {
            data.append(RecommendationDataItem(
                corpusItemId: "\(index)",
                scheduledCorpusItemId: "\(index)",
                url: "https://example\(index).com",
                title: "Title \(index)",
                excerpt: "Excerpt \(index)",
                publisher: "Publisher \(index)",
                isTimeSensitive: false,
                imageUrl: "https://example\(index).com",
                iconUrl: "https://example\(index).com",
                tileId: Int64(index),
                receivedRank: Int64(index)
            ))
        }
        return data
    }
}
