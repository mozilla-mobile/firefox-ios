// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
final class CuratedRecommendationCacheUtilityTests: XCTestCase {
    var testFileURL: URL!

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testFileURL)
        testFileURL = nil
        try await super.tearDown()
    }

    func testSaveAndLoadRecommendations() async throws {
        let cache = createCache()
        let recs = generateFakeDataWith(numberOfItems: 2)

        cache.save(recs)

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?.first?.title, "Title 1")
    }

    func testLastUpdatedIsSet() {
        let cache = createCache()
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)

        let lastUpdated = cache.lastUpdatedDate()
        XCTAssertNotNil(lastUpdated)
        XCTAssert(abs(lastUpdated!.timeIntervalSinceNow) < 2, "Last updated is too old")
    }

    func testOverwriteCache() {
        let cache = createCache()
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)

        let new_recs = generateFakeDataWith(numberOfItems: 2)
        cache.save(new_recs)

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?.last?.title, "Title 2")
    }

    func testClearCache() {
        let cache = createCache()
        let recs = generateFakeDataWith(numberOfItems: 1)
        cache.save(recs)
        cache.clearCache()

        XCTAssertNil(cache.loadRecommendations())
        XCTAssertNil(cache.lastUpdatedDate())
    }

    func testLoadFromEmptyReturnsNil() {
        let cache = createCache()
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

    private func createCache() -> CuratedRecommendationCacheUtility {
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test_curated_recommendations_cache.json")

        let cache = CuratedRecommendationCacheUtility(withCustomCacheURL: testFileURL)
        trackForMemoryLeaks(cache)

        return cache
    }
}
