// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import XCTest
import MozillaAppServices

@testable import Client

private struct TestableSubject {
    let subject: MerinoProvider
    let cache: MockCache
    let fetcher: MockFeedFetcher
}

private final class MockFeedFetcher: MerinoFeedFetching, @unchecked Sendable {
    var stubbedItems: [RecommendationDataItem] = []
    var callCount = 0
    var fetchDelay: UInt64 = 0

    func fetch(
        itemCount: Int,
        locale: CuratedRecommendationLocale,
        userAgent: String
    ) async -> [RecommendationDataItem] {
        callCount += 1
        if fetchDelay > 0 {
            try? await Task.sleep(nanoseconds: fetchDelay)
        }
        return stubbedItems
    }
}

private final class MockCache: CuratedRecommendationsCacheProtocol {
    private(set) var savedItemsHistory: [[RecommendationDataItem]] = []
    private(set) var didClear = false

    private var stored: [RecommendationDataItem]?
    private var lastUpdated: Date?

    func loadRecommendations() -> [RecommendationDataItem]? { stored }

    func save(_ items: [RecommendationDataItem]) {
        stored = items
        lastUpdated = Date()
        savedItemsHistory.append(items)
    }

    func clearCache() {
        didClear = true
        stored = nil
        lastUpdated = nil
    }

    func lastUpdatedDate() -> Date? { lastUpdated }

    // Testing helpers
    func seed(items: [RecommendationDataItem], lastUpdated: Date?) {
        stored = items
        self.lastUpdated = lastUpdated
    }

    func seedEmpty(lastUpdated: Date? = nil) {
        stored = nil
        self.lastUpdated = lastUpdated
    }
}

final class MerinoProviderTests: XCTestCase, @unchecked Sendable {
    private let storiesFlag = PrefsKeys.UserFeatureFlagPrefs.ASPocketStories

    func testIncorrectLocalesAreNotSupported() {
        XCTAssertFalse(MerinoProvider.isLocaleSupported("en_BD"))
        XCTAssertFalse(MerinoProvider.isLocaleSupported("enCA"))
    }

    func testCorrectLocalesAreSupported() {
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_US"))
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_GB"))
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_CA"))
    }

    func test_fetchStories_cachesManyStories_returnsRequired() async throws {
        let control = await createSubject(thresholdHours: 4)
        let testData = MerinoTestData().getMockDataFeed(30)
        control.cache.seed(items: testData, lastUpdated: Date())
        control.fetcher.stubbedItems = testData

        let result = try await control.subject.fetchStories(30)

        XCTAssertEqual(result.count, 30)
        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertFalse(control.cache.didClear)

        let anotherResult = try await control.subject.fetchStories(9)

        XCTAssertEqual(anotherResult.count, 9)
        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertFalse(control.cache.didClear)
    }

    func test_fetchStories_returnsCached_whenThresholdNotPassed() async throws {
        let control = await createSubject(thresholdHours: 4)
        control.cache.seed(items: [.makeItem("a"), .makeItem("b")], lastUpdated: Date())
        control.fetcher.stubbedItems = [.makeItem("net1"), .makeItem("net2")]

        let result = try await control.subject.fetchStories(10)

        XCTAssertEqual(result.map(\.title), ["a", "b"])
        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertFalse(control.cache.didClear)
    }

    func test_fetchStories_fetchesAndSaves_whenThresholdPassed() async throws {
        let control = await createSubject(thresholdHours: 1/60)
        control.cache.seed(items: [.makeItem("old")], lastUpdated: Date().addingTimeInterval(-3600))
        control.fetcher.stubbedItems = [.makeItem("new1"), .makeItem("new2")]

        let result = try await control.subject.fetchStories(10)

        XCTAssertEqual(result.map(\.title), ["new1", "new2"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["new1", "new2"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchStories_fetchesAndSaves_whenNoCache() async throws {
        let control = await createSubject()
        control.cache.seedEmpty()
        control.fetcher.stubbedItems = [.makeItem("net")]

        let result = try await control.subject.fetchStories(5)

        XCTAssertEqual(result.map(\.title), ["net"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["net"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchStories_throws_whenFeatureDisabled() async {
        let control = await createSubject(prefsEnabled: false)

        do {
            _ = try await control.subject.fetchStories(3)
            XCTFail("Expected MerinoProvider.Error to be thrown")
        } catch let error as MerinoProvider.Error {
            XCTAssertEqual(error, MerinoProvider.Error.failure)
        } catch {
            XCTFail("Threw unexpected error: \(error)")
        }
    }

    func test_fetchStories_fetches_whenNoLastUpdatedEvenIfItemsExist() async throws {
        let control = await createSubject(prefsEnabled: true)

        // Cache has _ itemCount but NO timestamp should be treated as STALE and must fetch
        // new stories. We should never get here, but we should still test it.
        control.cache.seed(items: [.makeItem("staleButNoTimestamp")], lastUpdated: nil)

        control.fetcher.stubbedItems = [.makeItem("net1"), .makeItem("net2")]

        let result = try await control.subject.fetchStories(3)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.title), ["net1", "net2"])
        XCTAssertEqual(control.fetcher.callCount, 1)

        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.count, 2)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["net1", "net2"])
    }

    func test_fetchStories_returnsCached_whenWithinOneHourThreshold() async throws {
        let control = await createSubject(thresholdHours: 1)
        control.cache.seed(items: [.makeItem("cached")], lastUpdated: Date().addingTimeInterval(-30 * 60))
        control.fetcher.stubbedItems = [.makeItem("network")]

        let result = try await control.subject.fetchStories(10)

        XCTAssertEqual(result.map(\.title), ["cached"])
        XCTAssertEqual(control.fetcher.callCount, 0)
    }

    // This test attempts to create a data race, to make sure that the actual code addresses
    // the possible data race issue. Hence the marking nonisolated(unsafe)
    func test_fetchStories_coalescesConcurrentRequests_whenCacheIsStale() async throws {
        nonisolated(unsafe) let control = await createSubject(thresholdHours: 1)
        control.cache.seedEmpty()
        control.fetcher.stubbedItems = [.makeItem("a"), .makeItem("b")]
        control.fetcher.fetchDelay = 100_000_000 // 100ms to ensure overlap

        async let result1 = control.subject.fetchStories(5)
        async let result2 = control.subject.fetchStories(10)
        let (items1, items2) = try await (result1, result2)

        XCTAssertEqual(control.fetcher.callCount, 1, "Concurrent fetches should coalesce into a single network request")
        XCTAssertEqual(items1.map(\.title), ["a", "b"])
        XCTAssertEqual(items2.map(\.title), ["a", "b"])
    }

    func test_fetchStories_fetchesFromNetwork_whenOneHourThresholdPassed() async throws {
        let control = await createSubject(thresholdHours: 1)
        control.cache.seed(items: [.makeItem("old")], lastUpdated: Date().addingTimeInterval(-61 * 60))
        control.fetcher.stubbedItems = [.makeItem("fresh")]

        let result = try await control.subject.fetchStories(10)

        XCTAssertEqual(result.map(\.title), ["fresh"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    private func createSubject(
        thresholdHours: Double = 4,
        prefsEnabled: Bool = true,
        cache: MockCache = MockCache(),
        fetcher: MockFeedFetcher = MockFeedFetcher()
    ) async -> TestableSubject {
        let prefs = MockProfilePrefs()
        prefs.setBool(prefsEnabled, forKey: storiesFlag)
        let subject = MerinoProvider(
            withThresholdInHours: thresholdHours,
            prefs: prefs,
            cache: cache,
            fetcher: fetcher
        )

        await trackForMemoryLeaks(subject)
        return TestableSubject(subject: subject, cache: cache, fetcher: fetcher)
    }
}

extension RecommendationDataItem {
    static func makeItem(_ name: String) -> RecommendationDataItem {
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
}
