// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol MerinoStoriesProviding: Sendable {
    typealias StoryResult = Swift.Result<[RecommendationDataItem], Error>

    func fetchStories(_ itemCount: Int32) async throws -> [RecommendationDataItem]
}

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private let thresholdInHours: Double
    private let cache: CuratedRecommendationsCacheProtocol
    private let prefs: Prefs
    private var logger: Logger
    private let fetcher: MerinoFeedFetching

    let MerinoServicesBaseURL = "https://merino.services.mozilla.com"

    enum Error: Swift.Error {
        case failure
    }

    init(
        withThresholdInHours threshold: Double = 4,
        prefs: Prefs,
        cache: CuratedRecommendationsCacheProtocol = CuratedRecommendationCacheUtility(),
        logger: Logger = DefaultLogger.shared,
        fetcher: MerinoFeedFetching? = nil
    ) {
        self.thresholdInHours = threshold
        self.cache = cache
        self.prefs = prefs
        self.logger = logger
        self.fetcher = fetcher ?? MerinoFeedFetcher(
            baseURL: MerinoServicesBaseURL,
            logger: logger
        )
    }

    func fetchStories(_ itemCount: Int32) async throws -> [RecommendationDataItem] {
        if !AppConstants.isRunningTest && shouldUseMockData {
            return try await MerinoTestData().getMockDataFeed(count: itemCount)
        }

        guard prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true,
              MerinoProvider.islocaleSupported(Locale.current.identifier)
        else { throw Error.failure }

        if let cachedItems = cache.loadRecommendations(),
           cacheUpdateThresholdHasNotPassed() {
            return cachedItems
        }

        guard let currentLocale = iOSToMerinoLocale(from: Locale.current.identifier) else {
            return []
        }

        let items = await fetcher.fetch(
            itemCount: itemCount,
            locale: currentLocale,
            userAgent: UserAgent.getUserAgent()
        )

        if !items.isEmpty {
            cache.clearCache()
            cache.save(items)
        }

        return items
    }

    static func islocaleSupported(_ locale: String) -> Bool {
        return allCuratedRecommendationLocales().contains(
            locale.replacingOccurrences(of: "_", with: "-")
        )
    }

    private var shouldUseMockData: Bool {
        return featureFlags.isCoreFeatureEnabled(.useMockData)
    }

    private func iOSToMerinoLocale(from locale: String) -> CuratedRecommendationLocale? {
        return curatedRecommendationLocaleFromString(
            locale: locale.replacingOccurrences(of: "_", with: "-")
        )
    }

    private func cacheUpdateThresholdHasNotPassed() -> Bool {
        let thresholdInSeconds: TimeInterval = thresholdInHours * 60 * 60
        guard let lastUpdate = cache.lastUpdatedDate() else { return false }
        return Date() < lastUpdate.addingTimeInterval(thresholdInSeconds)
    }
}
