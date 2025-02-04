// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ProductAdsCacheTests: XCTestCase {
    private var cache: ProductAdsCache!
    private var ads1: [ProductAdsResponse]!
    private var ads2: [ProductAdsResponse]!

    override func setUp() {
        super.setUp()
        cache = .shared
        ads1 = [
            ProductAdsResponse(
                name: "Ad1",
                url: URL(string: "https://ad1.com")!,
                imageUrl: URL(string: "https://ad1.com/image.jpg")!,
                price: "19.99",
                currency: "USD",
                grade: .a,
                adjustedRating: 4.5,
                analysisUrl: URL(string: "https://ad1.com/analysis")!,
                sponsored: true,
                aid: "12345")
        ]
        ads2 = [
            ProductAdsResponse(
                name: "Ad2",
                url: URL(string: "https://ad2.com")!,
                imageUrl: URL(string: "https://ad2.com/image.jpg")!,
                price: "29.99",
                currency: "USD",
                grade: .b,
                adjustedRating: 3.8,
                analysisUrl: URL(string: "https://ad2.com/analysis")!,
                sponsored: false,
                aid: "67890"),
        ]
    }

    override func tearDown() {
        cache = nil
        ads1 = nil
        ads2 = nil
        super.tearDown()
    }

    func testCacheAds() async {
        let key = "testKey"
        await cache.cacheAds(ads1, forKey: key)

        let cachedAds = await cache.getCachedAds(forKey: key)
        XCTAssertNotNil(cachedAds, "Cached ads should not be nil")
        XCTAssertEqual(cachedAds, ads1, "Cached ads should match the original ads")
    }

    func testClearCache() async {
        let key = "testKey"
        await cache.cacheAds(ads1, forKey: key)
        await cache.clearCache()

        let cachedAds = await cache.getCachedAds(forKey: key)
        XCTAssertNil(cachedAds, "Cached ads should be nil after clearing the cache")
    }

    func testGetCachedAds() async {
        let key = "testKey"
        await cache.cacheAds(ads1, forKey: key)

        let cachedAds = await cache.getCachedAds(forKey: key)
        XCTAssertNotNil(cachedAds, "Cached ads should not be nil")
        XCTAssertEqual(cachedAds, ads1, "Cached ads should match the original ads")

        // Test getting ads for a non-existent key
        let nonExistentAds = await cache.getCachedAds(forKey: "nonExistentKey")
        XCTAssertNil(nonExistentAds, "Cached ads for a non-existent key should be nil")
    }

    func testCacheMultipleKeys() async {
        let key1 = "testKey1"
        let key2 = "testKey2"
        await cache.cacheAds(ads1, forKey: key1)
        await cache.cacheAds(ads2, forKey: key2)

        let cachedAds1 = await cache.getCachedAds(forKey: key1)
        let cachedAds2 = await cache.getCachedAds(forKey: key2)

        XCTAssertNotNil(cachedAds1, "Cached ads for key1 should not be nil")
        XCTAssertEqual(cachedAds1, ads1, "Cached ads for key1 should match the original ads1")

        XCTAssertNotNil(cachedAds2, "Cached ads for key2 should not be nil")
        XCTAssertEqual(cachedAds2, ads2, "Cached ads for key2 should match the original ads2")
    }
}
