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
    var stubbedResponse: CuratedRecommendationsResponse?
    var callCount = 0
    var fetchDelay: UInt64 = 0

    func fetch(
        itemCount: Int,
        locale: CuratedRecommendationLocale,
        region: String?,
        userAgent: String
    ) async -> CuratedRecommendationsResponse? {
        callCount += 1
        if fetchDelay > 0 {
            try? await Task.sleep(nanoseconds: fetchDelay)
        }
        return stubbedResponse
    }
}

private final class MockCache: CuratedRecommendationsCacheProtocol {
    private(set) var savedResponseHistory: [CuratedRecommendationsResponse] = []
    private(set) var didClear = false

    private var stored: CuratedRecommendationsResponse?
    private var lastUpdated: Date?

    func loadResponse() -> CuratedRecommendationsResponse? { stored }

    func save(_ response: CuratedRecommendationsResponse) {
        stored = response
        lastUpdated = Date()
        savedResponseHistory.append(response)
    }

    func clearCache() {
        didClear = true
        stored = nil
        lastUpdated = nil
    }

    func lastUpdatedDate() -> Date? { lastUpdated }

    // Testing helpers
    func seed(response: CuratedRecommendationsResponse, lastUpdated: Date?) {
        stored = response
        self.lastUpdated = lastUpdated
    }

    func seedEmpty(lastUpdated: Date? = nil) {
        stored = nil
        self.lastUpdated = lastUpdated
    }
}

final class MerinoProviderTests: XCTestCase, @unchecked Sendable {
    private let storiesFlag = PrefsKeys.UserFeatureFlagPrefs.ASPocketStories
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        await DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            HomepageRedesignFeature(categoriesEnabled: false)
        }
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
        try await super.tearDown()
    }

    func testIncorrectLocalesAreNotSupported() {
        XCTAssertFalse(MerinoProvider.isLocaleSupported("en_BD"))
        XCTAssertFalse(MerinoProvider.isLocaleSupported("enCA"))
    }

    func testCorrectLocalesAreSupported() {
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_US"))
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_GB"))
        XCTAssertTrue(MerinoProvider.isLocaleSupported("en_CA"))
    }

    func test_fetchContent_returnsCached_whenThresholdNotPassed() async throws {
        let control = await createSubject(thresholdHours: 4)
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [
                .makeItem("a"),
                .makeItem("b")
            ]
        )
        control.cache.seed(response: cachedResponse, lastUpdated: Date())
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [
                .makeItem("net1"),
                .makeItem("net2")
            ]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.map(\.title), ["a", "b"])
        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertFalse(control.cache.didClear)
    }

    func test_fetchContent_fetchesAndSaves_whenThresholdPassed() async throws {
        let control = await createSubject(thresholdHours: 1/60)
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(items: [.makeItem("old")])
        control.cache.seed(response: cachedResponse, lastUpdated: Date().addingTimeInterval(-3600))
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [
                .makeItem("new1"),
                .makeItem("new2")
            ]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.map(\.title), ["new1", "new2"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadResponse()?.data.map(\.title), ["new1", "new2"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchContent_fetchesAndSaves_whenNoCache() async throws {
        let control = await createSubject()
        control.cache.seedEmpty()
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("net")]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.map(\.title), ["net"])
        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadResponse()?.data.map(\.title), ["net"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_fetchContent_throws_whenFeatureDisabled() async {
        let control = await createSubject(prefsEnabled: false)

        do {
            _ = try await control.subject.fetchContent()
            XCTFail("Expected MerinoProvider.Error to be thrown")
        } catch let error as MerinoProvider.Error {
            XCTAssertEqual(error, MerinoProvider.Error.failure)
        } catch {
            XCTFail("Threw unexpected error: \(error)")
        }
    }

    func test_fetchContent_fetches_whenNoLastUpdatedEvenIfItemsExist() async throws {
        let control = await createSubject(prefsEnabled: true)

        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("staleButNoTimestamp")]
        )
        control.cache.seed(response: cachedResponse, lastUpdated: nil)

        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [
                .makeItem("net1"),
                .makeItem("net2")
            ]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.count, 2)
        XCTAssertEqual(result.data.map(\.title), ["net1", "net2"])
        XCTAssertEqual(control.fetcher.callCount, 1)

        XCTAssertTrue(control.cache.didClear)
        XCTAssertEqual(control.cache.loadResponse()?.data.count, 2)
        XCTAssertEqual(control.cache.loadResponse()?.data.map(\.title), ["net1", "net2"])
    }

    func test_fetchContent_returnsCached_whenWithinOneHourThreshold() async throws {
        let control = await createSubject(thresholdHours: 1)
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("cached")]
        )
        control.cache.seed(response: cachedResponse, lastUpdated: Date().addingTimeInterval(-30 * 60))
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("network")]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.map(\.title), ["cached"])
        XCTAssertEqual(control.fetcher.callCount, 0)
    }

    func test_fetchContent_fetchesFromNetwork_whenCategoriesEnabledAndCachedResponseHasNoFeeds() async throws {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            HomepageRedesignFeature(categoriesEnabled: true)
        }

        let control = await createSubject(thresholdHours: 1)
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("cached-story")],
            feeds: nil
        )
        let networkFeeds = [FeedSection.makeSection(feedId: "technology", recommendations: [.makeItem("tech-story")])]
        control.cache.seed(response: cachedResponse, lastUpdated: Date())
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("network-story")],
            feeds: networkFeeds
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(control.fetcher.callCount, 1)
        XCTAssertEqual(result.feeds?.first?.feedId, "technology")
        XCTAssertTrue(control.cache.didClear)
    }

    func test_fetchContent_returnsCached_whenCategoriesEnabledAndCachedResponseHasFeeds() async throws {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            HomepageRedesignFeature(categoriesEnabled: true)
        }

        let control = await createSubject(thresholdHours: 1)
        let cachedFeeds = [FeedSection.makeSection(feedId: "technology", recommendations: [.makeItem("tech-story")])]
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("cached-story")],
            feeds: cachedFeeds
        )
        control.cache.seed(response: cachedResponse, lastUpdated: Date())
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("network-story")],
            feeds: [FeedSection.makeSection(feedId: "science", recommendations: [.makeItem("science-story")])]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(control.fetcher.callCount, 0)
        XCTAssertEqual(result.feeds?.first?.feedId, "technology")
        XCTAssertFalse(control.cache.didClear)
    }

    func test_fetchContent_fetchesFromNetwork_whenCategoriesDisabledAndCachedResponseHasNoStories() async throws {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            HomepageRedesignFeature(categoriesEnabled: false)
        }

        let control = await createSubject(thresholdHours: 1)
        let cachedFeeds = [FeedSection.makeSection(feedId: "technology", recommendations: [.makeItem("tech-story")])]
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [],
            feeds: cachedFeeds
        )
        control.cache.seed(response: cachedResponse, lastUpdated: Date())
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("network-story")],
            feeds: nil
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(control.fetcher.callCount, 1)
        XCTAssertEqual(result.data.map(\.title), ["network-story"])
        XCTAssertTrue(control.cache.didClear)
    }

    func test_fetchContent_coalescesConcurrentRequests_whenCacheIsStale() async throws {
        nonisolated(unsafe) let control = await createSubject(thresholdHours: 1)
        control.cache.seedEmpty()
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [
                .makeItem("a"),
                .makeItem("b")
            ]
        )
        control.fetcher.fetchDelay = 100_000_000

        async let result1 = control.subject.fetchContent()
        async let result2 = control.subject.fetchContent()
        let (response1, response2) = try await (result1, result2)

        XCTAssertEqual(control.fetcher.callCount, 1, "Concurrent fetches should coalesce into a single network request")
        XCTAssertEqual(response1.data.map(\.title), ["a", "b"])
        XCTAssertEqual(response2.data.map(\.title), ["a", "b"])
    }

    func test_fetchContent_fetchesFromNetwork_whenOneHourThresholdPassed() async throws {
        let control = await createSubject(thresholdHours: 1)
        let cachedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("old")]
        )
        control.cache.seed(response: cachedResponse, lastUpdated: Date().addingTimeInterval(-61 * 60))
        control.fetcher.stubbedResponse = CuratedRecommendationsResponse.makeResponse(
            items: [.makeItem("fresh")]
        )

        let result = try await control.subject.fetchContent()

        XCTAssertEqual(result.data.map(\.title), ["fresh"])
        XCTAssertEqual(control.fetcher.callCount, 1)
    }

    func test_getMockDataFeed_whenCategoriesDisabled_returnsStoriesOnly() {
        let response = MerinoTestData().getMockDataFeed(10, categoriesEnabled: false)

        XCTAssertEqual(response.data.count, 10)
        XCTAssertNil(response.feeds)
    }

    func test_getMockDataFeed_whenCategoriesEnabled_returnsFeedsOnly() {
        let response = MerinoTestData().getMockDataFeed(10, categoriesEnabled: true)
        let categoryRecommendations = response.feeds?.flatMap(\.recommendations) ?? []

        XCTAssertEqual(response.data.count, 0)
        XCTAssertEqual(response.feeds?.map(\.feedId), ["travel", "technology", "science"])
        XCTAssertEqual(response.feeds?.allSatisfy { !$0.recommendations.isEmpty }, true)
        XCTAssertEqual(categoryRecommendations.count, 10)
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

extension CuratedRecommendationsResponse {
    static func makeResponse(
        items: [RecommendationDataItem],
        feeds: [FeedSection]? = nil
    ) -> CuratedRecommendationsResponse {
        return CuratedRecommendationsResponse(
            recommendedAt: Int64(Date().timeIntervalSince1970 * 1000),
            data: items,
            feeds: feeds
        )
    }
}

extension FeedSection {
    static func makeSection(
        feedId: String = "section",
        receivedFeedRank: Int32 = 0,
        recommendations: [RecommendationDataItem] = [],
        title: String = "Section Title",
        subtitle: String? = nil,
        isFollowed: Bool = false,
        isBlocked: Bool = false
    ) -> FeedSection {
        return FeedSection(
            feedId: feedId,
            receivedFeedRank: receivedFeedRank,
            recommendations: recommendations,
            title: title,
            subtitle: subtitle,
            layout: Layout(name: "4-large", responsiveLayouts: []),
            isFollowed: isFollowed,
            isBlocked: isBlocked
        )
    }
}
