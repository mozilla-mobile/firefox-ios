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

    func testSaveAndLoadResponse() async throws {
        let cache = createCache()
        let response = generateFakeResponse(numberOfItems: 2)

        cache.save(response)

        let loaded = cache.loadResponse()
        XCTAssertEqual(loaded?.data.count, 2)
        XCTAssertEqual(loaded?.data.first?.title, "Title 1")
    }

    func testLastUpdatedIsSet() {
        let cache = createCache()
        let response = generateFakeResponse(numberOfItems: 1)
        cache.save(response)

        let lastUpdated = cache.lastUpdatedDate()
        XCTAssertNotNil(lastUpdated)
        XCTAssert(abs(lastUpdated!.timeIntervalSinceNow) < 2, "Last updated is too old")
    }

    func testOverwriteCache() {
        let cache = createCache()
        let response = generateFakeResponse(numberOfItems: 1)
        cache.save(response)

        let newResponse = generateFakeResponse(numberOfItems: 2)
        cache.save(newResponse)

        let loaded = cache.loadResponse()
        XCTAssertEqual(loaded?.data.count, 2)
        XCTAssertEqual(loaded?.data.last?.title, "Title 2")
    }

    func testClearCache() {
        let cache = createCache()
        let response = generateFakeResponse(numberOfItems: 1)
        cache.save(response)
        cache.clearCache()

        XCTAssertNil(cache.loadResponse())
        XCTAssertNil(cache.lastUpdatedDate())
    }

    func testLoadFromEmptyReturnsNil() {
        let cache = createCache()
        XCTAssertNil(cache.loadResponse())
        XCTAssertNil(cache.lastUpdatedDate())
    }

    private func generateFakeResponse(numberOfItems: Int) -> CuratedRecommendationsResponse {
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
        return CuratedRecommendationsResponse(
            recommendedAt: Int64(Date().timeIntervalSince1970 * 1000),
            data: data
        )
    }

    private func createCache() -> CuratedRecommendationCacheUtility {
        let tempDir = FileManager.default.temporaryDirectory
        testFileURL = tempDir.appendingPathComponent("test_curated_recommendations_cache.json")

        let cache = CuratedRecommendationCacheUtility(withCustomCacheURL: testFileURL)
        trackForMemoryLeaks(cache)

        return cache
    }
}
