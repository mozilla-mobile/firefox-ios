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

final class MerinoProvider: MerinoStoriesProviding, FeatureFlaggable, @unchecked Sendable {
    private static let SupportedLocales = [
        "en_CA",
        "en_US",
        "en_GB",
        "en_ZA",
        "de_DE",
        "de_AT",
        "de_CH"
    ]

    private let prefs: Prefs
    private var logger: Logger

    let MerinoServicesBaseURL = "https://merino.services.mozilla.com"

    enum Error: Swift.Error {
        case failure
    }

    init(
        prefs: Prefs,
        logger: Logger = DefaultLogger.shared
    ) {
        self.prefs = prefs
        self.logger = logger
    }

    func fetchStories(items: Int32) async throws -> [RecommendationDataItem] {
        let isFeatureEnabled = prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.ASPocketStories) ?? true
        let isCurrentLocaleSupported = MerinoProvider.islocaleSupported(Locale.current.identifier)

        if shouldUseMockData {
            return try await MerinoTestData().getMockDataFeed(count: items)
        }

        // Ensure the feature is enabled and current locale is supported
        guard isFeatureEnabled, isCurrentLocaleSupported else {
            throw Error.failure
        }

        return try await getFeedItems(items: items)
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

    // Returns nil if the locale is not supported
    static func islocaleSupported(_ locale: String) -> Bool {
        return MerinoProvider.SupportedLocales.contains(locale)
    }

    private var shouldUseMockData: Bool {
        return featureFlags.isCoreFeatureEnabled(.useMockData)
    }

    private func iOSToMerinoLocale(from locale: String) -> CuratedRecommendationLocale? {
        switch locale {
        case "en": return .en
        case "en_CA": return .enCa
        case "en_GB": return .enGb
        case "en_US": return .enUs
        case "de": return .de
        case "de_DE": return .deDe
        case "de_AT": return .deAt
        case "de_CH": return .deCh
            // Not sure if we're supporting these yet
            //        case "fr": return .fr
            //        case "fr_FR": return .frFr
            //        case "es": return .es
            //        case "es_ES": return .esEs
            //        case "it": return .it
            //        case "it_IT": return .itIt
        default: return nil
        }
    }
}
