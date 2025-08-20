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

    func fetch(
        items: Int32,
        locale: CuratedRecommendationLocale,
        userAgent: String
    ) async throws -> [RecommendationDataItem] {
        callCount += 1
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
        self.stored = items
        self.lastUpdated = Date()
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
        let control = createSubject(thresholdHours: 4)
        control.cache.seed(items: [makeItem("a"), makeItem("b")], lastUpdated: Date())
        control.fetcher.stubbedItems = [makeItem("net1"), makeItem("net2")]

        let result = try await control.subject.fetchStories(items: 10)

        XCTAssertEqual(result.map(\.title), ["a", "b"])
        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertFalse(control.cache.didClear)
    }

    func test_fetchStories_fetchesAndSaves_whenThresholdPassed() async throws {
        let control = createSubject(thresholdHours: 1/60)
        control.cache.seed(items: [makeItem("old")], lastUpdated: Date().addingTimeInterval(-3600))
        control.fetcher.stubbedItems = [makeItem("new1"), makeItem("new2")]

        let result = try await control.subject.fetchStories(items: 10)

        XCTAssertEqual(result.map(\.title), ["new1", "new2"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["new1", "new2"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchStories_fetchesAndSaves_whenNoCache() async throws {
        let control = createSubject()
        control.cache.seedEmpty()
        control.fetcher.stubbedItems = [makeItem("net")]

        let result = try await control.subject.fetchStories(items: 5)

        XCTAssertEqual(result.map(\.title), ["net"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["net"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchStories_throws_whenFeatureDisabled() async {
        let control = createSubject(prefsEnabled: false)

        do {
            _ = try await control.subject.fetchStories(items: 3)
            XCTFail("Expected MerinoProvider.Error to be thrown")
        } catch let error as MerinoProvider.Error {
            XCTAssertEqual(error, MerinoProvider.Error.failure)
        } catch {
            XCTFail("Threw unexpected error: \(error)")
        }
    }

    func test_fetchStories_fetches_whenNoLastUpdatedEvenIfItemsExist() async throws {
        let control = createSubject(prefsEnabled: true)

        // Cache has items but NO timestamp should be treated as STALE and must fetch
        // new stories. We should never get here, but we should still test it.
        control.cache.seed(items: [makeItem("staleButNoTimestamp")], lastUpdated: nil)

        control.fetcher.stubbedItems = [makeItem("net1"), makeItem("net2")]

        let result = try await control.subject.fetchStories(items: 3)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.title), ["net1", "net2"])
        XCTAssertEqual(control.fetcher.callCount, 1)

        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadRecommendations()?.count, 2)
        XCTAssertEqual(control.cache.loadRecommendations()?.map(\.title), ["net1", "net2"])
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
        cache: MockCache = MockCache(),
        fetcher: MockFeedFetcher = MockFeedFetcher()
    ) -> TestableSubject {
        let prefs = MockProfilePrefs()
        prefs.setBool(prefsEnabled, forKey: storiesFlag)
        let subject = MerinoProvider(
            withThresholdInHours: thresholdHours,
            prefs: prefs,
            cache: cache,
            fetcher: fetcher
        )

        trackForMemoryLeaks(subject)
        return TestableSubject(subject: subject, cache: cache, fetcher: fetcher)
    }
}
