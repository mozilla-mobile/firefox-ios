// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol MerinoStoriesProviding: Sendable {
    func fetchContent() async throws -> CuratedRecommendationsResponse
}

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private struct Constants {
        static let merinoServicesBaseURL = "https://merino.services.mozilla.com"
        static let numberOfStoriesToFetchForCaching = 100
    }

    private let thresholdInHours: Double
    private let cache: CuratedRecommendationsCacheProtocol
    private let prefs: Prefs
    private var logger: Logger
    private let fetcher: MerinoFeedFetching
    private let lock = NSLock()
    private var inFlightTask: Task<CuratedRecommendationsResponse?, Never>?

    enum Error: Swift.Error {
        case failure
    }

    init(
        withThresholdInHours threshold: Double = 1,
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
            baseURL: Constants.merinoServicesBaseURL,
            logger: logger
        )
    }

    func fetchContent() async throws -> CuratedRecommendationsResponse {
        if !AppConstants.isRunningTest && shouldUseMockData {
            return MerinoTestData().getMockDataFeed(
                Constants.numberOfStoriesToFetchForCaching,
                categoriesEnabled: isHomepageStoryCategoriesEnabled
            )
        }

        guard prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true,
              MerinoProvider.isLocaleSupported(Locale.current.identifier)
        else { throw Error.failure }

        if let cachedResponse = cache.loadResponse(),
           cacheUpdateThresholdHasNotPassed(),
           cachedResponseMatchesCurrentHomepageStoriesMode(cachedResponse) {
            return cachedResponse
        }

        guard let response = await createTask().value else {
            throw Error.failure
        }
        return response
    }

    static func isLocaleSupported(_ locale: String) -> Bool {
        return allCuratedRecommendationLocales().contains(
            locale.replacingOccurrences(of: "_", with: "-")
        )
    }

    private func createTask() -> Task<CuratedRecommendationsResponse?, Never> {
        lock.withLock {
            if let existing = inFlightTask { return existing }

            let newTask = Task<CuratedRecommendationsResponse?, Never> { [self] in
                defer { self.lock.withLock { self.inFlightTask = nil } }
                guard let currentLocale = iOSToMerinoLocale(from: Locale.current.identifier) else {
                    return nil
                }

                let region = SystemLocaleProvider().regionCode()
                let regionCode: String? = region == "und" ? nil : region

                let response = await fetcher.fetch(
                    itemCount: Constants.numberOfStoriesToFetchForCaching,
                    locale: currentLocale,
                    region: regionCode,
                    userAgent: UserAgent.getUserAgent()
                )

                // Only cache items if we have a response, and it has some sort
                // of data we'd like to actually save
                if let response,
                   !response.data.isEmpty || response.feeds != nil {
                    cache.clearCache()
                    cache.save(response)
                }

                return response
            }

            inFlightTask = newTask
            return newTask
        }
    }

    private var shouldUseMockData: Bool {
        return CoreBuildFlags.isUsingMockData || prefs.boolForKey(PrefsKeys.useMerinoTestData) ?? false
    }

    private var isHomepageStoryCategoriesEnabled: Bool {
        return featureFlagsProvider.isEnabled(.homepageStoryCategories)
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

    /// Returns whether the cached response shape matches the current homepage stories mode.
    /// When categories are enabled we require non-empty `feeds`, otherwise we require
    /// non-empty top-level story `data`. If the shapes do not match, we bypass the cache
    /// and fetch again so a mode switch is reflected immediately.
    private func cachedResponseMatchesCurrentHomepageStoriesMode(_ response: CuratedRecommendationsResponse) -> Bool {
        if isHomepageStoryCategoriesEnabled {
            return !(response.feeds?.isEmpty ?? true)
        }

        return !response.data.isEmpty
    }
}
