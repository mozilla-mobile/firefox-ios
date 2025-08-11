// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

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
        let recs = [
            CuratedRecommendation(id: "1", title: "Rec One"),
            CuratedRecommendation(id: "2", title: "Rec Two")
        ]

        cache.save(recs)

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?.first?.title, "Rec One")
    }

    func testLastUpdatedIsSet() {
        cache.save([
            CuratedRecommendation(id: "1", title: "Test")
        ])

        let lastUpdated = cache.lastUpdatedDate()
        XCTAssertNotNil(lastUpdated)
        XCTAssert(abs(lastUpdated!.timeIntervalSinceNow) < 2, "Last updated is too old")
    }

    func testOverwriteCache() {
        cache.save([
            CuratedRecommendation(id: "1", title: "Old")
        ])
        cache.save([
            CuratedRecommendation(id: "2", title: "New")
        ])

        let loaded = cache.loadRecommendations()
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?.first?.title, "New")
    }

    func testClearCache() {
        cache.save([
            CuratedRecommendation(id: "1", title: "To be cleared")
        ])
        cache.clearCache()

        XCTAssertNil(cache.loadRecommendations())
        XCTAssertNil(cache.lastUpdated())
    }

    func testLoadFromEmptyReturnsNil() {
        XCTAssertNil(cache.loadRecommendations())
        XCTAssertNil(cache.lastUpdated())
    }

    private func fakeData() -> [Re]
}
