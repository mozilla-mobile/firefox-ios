// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

protocol MerinoStoriesProviding: Sendable {
    typealias StoryResult = Swift.Result<[RecommendationDataItem], Error>

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem]
}

extension MerinoStoriesProviding {
    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        return try await fetchStories(items: items)
    }
}

class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private let thresholdInHours: Double
    private let cache: CuratedRecommendationsCacheProtocol
    private let prefs: Prefs
    private var logger: Logger

    let MerinoServicesBaseURL = "https://merino.services.mozilla.com"

    enum Error: Swift.Error {
        case failure
    }

    init(
        withThresholdInHours threshold: Double = 4,
        prefs: Prefs,
        cache: CuratedRecommendationsCacheProtocol = CuratedRecommendationCacheUtility(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.thresholdInHours = threshold
        self.cache = cache
        self.prefs = prefs
        self.logger = logger
    }

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        if shouldUseMockData {
            return try await MerinoTestData().getMockDataFeed(count: items)
        }

        // Ensure the feature is enabled and current locale is supported
        guard prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true,
              MerinoProvider.islocaleSupported(Locale.current.identifier)
        else { throw Error.failure }

        if let cachedItems = cache.loadRecommendations(),
           cacheUpdateThresholdHasNotPassed() {
                return cachedItems
        }

        let items = try await getFeedItems(items: items)
        if !items.isEmpty {
            cache.clearCache()
            cache.save(items)
        }
        return items
    }

    func getFeedItems(items: Int32) async throws -> [RecommendationDataItem] {
        do {
            let client = try CuratedRecommendationsClient(
                config: CuratedRecommendationsConfig(
                    baseHost: MerinoServicesBaseURL,
                    userAgentHeader: UserAgent.getUserAgent()
                )
            )

            guard let currentLocale = iOSToMerinoLocale(from: Locale.current.identifier) else {
                return []
            }

            let merinoRequest = CuratedRecommendationsRequest(
                locale: currentLocale,
                count: items
            )

            let response = try client.getCuratedRecommendations(request: merinoRequest)
            return response.data
        } catch let error as CuratedRecommendationsApiError {
            switch error {
            case .Network(let reason):
                logger.log("Network error when fetching Curated Recommendations: \(reason)",
                           level: .debug,
                           category: .merino
                )

            case .Other(let code?, let reason) where code == 400:
                logger.log("Bad Request: \(reason)",
                           level: .debug,
                           category: .merino
                )

            case .Other(let code?, let reason) where code == 422:
                logger.log("Validation Error: \(reason)",
                           level: .debug,
                           category: .merino
                )

            case .Other(let code?, let reason) where (500...599).contains(code):
                logger.log("Server Error: \(reason)",
                           level: .debug,
                           category: .merino
                )

            case .Other(nil, let reason):
                logger.log("Missing status code: \(reason)",
                           level: .debug,
                           category: .merino
                )

            case .Other(_, let reason):
                logger.log("Unexpected Error: \(reason)",
                           level: .debug,
                           category: .merino
                )
            }
            return []
        } catch {
            logger.log("Unhandled error: \(error)",
                       level: .debug,
                       category: .merino
            )
            return []
        }
    }

    static func islocaleSupported(_ locale: String) -> Bool {
        return allCuratedRecommendationLocales().contains(locale.replacingOccurrences(of: "_", with: "-"))
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
        guard let lastUpdate = cache.lastUpdatedDate() else { return true }
        return Date() < lastUpdate.addingTimeInterval(thresholdInSeconds)
    }
}
