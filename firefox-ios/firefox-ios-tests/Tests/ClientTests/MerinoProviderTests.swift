// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
import MozillaAppServices

@testable import Client

private final class MockCache: CuratedRecommendationsCacheProtocol {
    private(set) var savedItemsHistory: [[RecommendationDataItem]] = []
    private(set) var didClear = false

    private var _stored: [RecommendationDataItem]?
    private var _lastUpdated: Date?

    func loadRecommendations() -> [RecommendationDataItem]? { _stored }

    func save(_ items: [RecommendationDataItem]) {
        _stored = items
        _lastUpdated = Date()
        savedItemsHistory.append(items)
    }

    func clearCache() {
        didClear = true
        _stored = nil
        _lastUpdated = nil
    }

    func lastUpdatedDate() -> Date? { _lastUpdated }

    // Testing helpers
    func seed(items: [RecommendationDataItem], lastUpdated: Date?) {
        _stored = items
        _lastUpdated = lastUpdated
    }

    func seedEmpty(lastUpdated: Date? = nil) {
        _stored = nil
        _lastUpdated = lastUpdated
    }
}

private final class TestableMerinoProvider: MerinoProvider, @unchecked Sendable {
    var stubbedItems: [RecommendationDataItem] = []
    var getFeedItemsCallCount = 0

    override func getFeedItems(items: Int32) async throws -> [RecommendationDataItem] {
        getFeedItemsCallCount += 1
        return stubbedItems
    }
}

final class MerinoProviderTests: XCTestCase {
    private let storiesFlag = PrefsKeys.UserFeatureFlagPrefs.ASPocketStories

    func testIncorrectLocalesAreNotSupported() {
        XCTAssertFalse(MerinoProvider.islocaleSupported("en_BD"))
        XCTAssertFalse(MerinoProvider.islocaleSupported("enCA"))
    }

    func testCorrectLocalesAreSupported() {
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_US"))
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_GB"))
        XCTAssertTrue(MerinoProvider.islocaleSupported("en_CA"))
    }

    func test_fetchStories_returnsCached_whenThresholdNotPassed() async throws {
        let (sut, cache) = createSubject(thresholdHours: 4)
        cache.seed(items: [makeItem("a"), makeItem("b")], lastUpdated: Date())
        sut.stubbedItems = [makeItem("net1"), makeItem("net2")]

        let result = try await sut.fetchStories(items: 10)

        XCTAssertEqual(result.map(\.title), ["a", "b"])
        XCTAssertEqual(sut.getFeedItemsCallCount, 0)
        XCTAssertFalse(cache.didClear)
    }

    func test_fetchStories_fetchesAndSaves_whenThresholdPassed() async throws {
        let (sut, cache) = createSubject(thresholdHours: 1/60)
        cache.seed(items: [makeItem("old")], lastUpdated: Date().addingTimeInterval(-3600))
        sut.stubbedItems = [makeItem("new1"), makeItem("new2")]

        let result = try await sut.fetchStories(items: 10)

        XCTAssertEqual(result.map(\.title), ["new1", "new2"])
        XCTAssertTrue(cache.didClear)
        XCTAssertEqual(cache.loadRecommendations()?.map(\.title), ["new1", "new2"])
        XCTAssertEqual(sut.getFeedItemsCallCount, 1)
    }

    func test_fetchStories_fetchesAndSaves_whenNoCache() async throws {
        let (sut, cache) = createSubject()
        cache.seedEmpty()
        sut.stubbedItems = [makeItem("net")]

        let result = try await sut.fetchStories(items: 5)

        XCTAssertEqual(result.map(\.title), ["net"])
        XCTAssertTrue(cache.didClear)
        XCTAssertEqual(cache.loadRecommendations()?.map(\.title), ["net"])
        XCTAssertEqual(sut.getFeedItemsCallCount, 1)
    }

    func test_fetchStories_throws_whenFeatureDisabled() async {
        let (sut, _) = createSubject(prefsEnabled: false)

        do {
            _ = try await sut.fetchStories(items: 3)
            XCTFail("Expected MerinoProvider.Error to be thrown")
        } catch let error as MerinoProvider.Error {
            XCTAssertEqual(error, MerinoProvider.Error.failure)
        } catch {
            XCTFail("Threw unexpected error: \(error)")
        }
    }

    func test_fetchStories_fetches_whenNoLastUpdatedEvenIfItemsExist() async throws {
        let (sut, cache) = createSubject(prefsEnabled: true)

        // Cache has items but NO timestamp should be treated as STALE and must fetch
        // new stories. We should never get here, but we should still test it.
        cache.seed(items: [makeItem("staleButNoTimestamp")], lastUpdated: nil)

        sut.stubbedItems = [makeItem("net1"), makeItem("net2")]

        let result = try await sut.fetchStories(items: 3)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.title), ["net1", "net2"])
        XCTAssertEqual(sut.getFeedItemsCallCount, 1)

        XCTAssertTrue(cache.didClear)
        XCTAssertEqual(cache.loadRecommendations()?.count, 2)
        XCTAssertEqual(cache.loadRecommendations()?.map(\.title), ["net1", "net2"])
    }

    private func makeItem(_ name: String) -> RecommendationDataItem {
        return RecommendationDataItem(
            corpusItemId: "\(name)",
            scheduledCorpusItemId: "\(name)",
            url: "https://\(name).com",
            title: "\(name)",
            excerpt: "Excerpt \(name)",
            publisher: "Publisher \(name)",
            isTimeSensitive: false,
            imageUrl: "https://example\(name).com",
            iconUrl: "https://example\(name).com",
            tileId: 0,
            receivedRank: 0
        )
    }

    private func createSubject(
        thresholdHours: Double = 4,
        prefsEnabled: Bool = true,
        cache: MockCache = MockCache()
    ) -> (TestableMerinoProvider, MockCache) {
        let prefs = MockProfilePrefs()
        prefs.setBool(prefsEnabled, forKey: storiesFlag)
        let sut = TestableMerinoProvider(
            withThresholdInHours: thresholdHours,
            prefs: prefs,
            cache: cache
        )

        trackForMemoryLeaks(sut)
        return (sut, cache)
    }
}
